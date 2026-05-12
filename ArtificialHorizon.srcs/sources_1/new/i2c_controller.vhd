library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.I2cPckg.all;

entity i2c_controller is
    generic(
        FREQ_G : real := 100.0;
        I2C_FREQ_G : real := 0.4
    );
    port(
        clk_i : in std_logic;
        rst_i : in std_logic;
        start_read_i : in std_logic;
        accel_x_o : out std_logic_vector(15 downto 0);
        accel_y_o : out std_logic_vector(15 downto 0);
        accel_z_o : out std_logic_vector(15 downto 0);
        data_ready_o : out std_logic;
        init_done_o : out std_logic;
        scl_io : inout std_logic;
        sda_io : inout std_logic;
		-- Puerto de debug para ver el estado de la maquina en LEDs
		state_debug_o : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of i2c_controller is

    constant BMI160_ADDR_WRITE : std_logic_vector(7 downto 0) := "11010000";
    constant BMI160_ADDR_READ  : std_logic_vector(7 downto 0) := "11010001";

    constant CMD_REG : std_logic_vector(7 downto 0) := x"7E";
    constant ACC_NORMAL_MODE : std_logic_vector(7 downto 0) := x"11";
    constant ACCEL_X_LSB : std_logic_vector(7 downto 0) := x"12";

    constant CMD_START : std_logic_vector(7 downto 0) := x"80";
    constant CMD_STOP  : std_logic_vector(7 downto 0) := x"40";
    constant CMD_WRITE : std_logic_vector(7 downto 0) := x"10";
    constant CMD_READ  : std_logic_vector(7 downto 0) := x"20";
    -- En este core, el bit ACK=0 envia ACK y ACK=1 envia NACK.
    constant CMD_NACK  : std_logic_vector(7 downto 0) := x"08";

    constant ADDR_CTR    : std_logic_vector(2 downto 0) := "010";
    constant ADDR_TXR    : std_logic_vector(2 downto 0) := "011";
    constant ADDR_CR     : std_logic_vector(2 downto 0) := "100";
    constant ADDR_SR     : std_logic_vector(2 downto 0) := "100";

    type state_t is (IDLE, INIT_I2C,
                     INIT_START, INIT_ADDR_W, INIT_ADDR_ACK,
                     INIT_REG, INIT_REG_ACK, INIT_DATA, INIT_DATA_ACK,
                     INIT_STOP, INIT_WAIT, WAIT_I2C_CMD, WAIT_I2C_EVAL,
                     START_COND, SEND_ADDR_W, ACK_ADDR_W,
                     SEND_REG, ACK_REG, RESTART_COND,
                     SEND_ADDR_R, ACK_ADDR_R,
                     READ_BYTE, ACK_BYTE, STOP_COND, DONE_ST,
                     ERROR_ST, RECOVER_ST);
    signal state : state_t;
    signal next_state_after_cmd : state_t;

    signal i2c_addr : std_logic_vector(2 downto 0);
    signal i2c_data_in : std_logic_vector(7 downto 0);
    signal i2c_data_out : std_logic_vector(7 downto 0);
    signal i2c_wr : std_logic;
    signal i2c_rd : std_logic;
    signal i2c_done : std_logic;

    signal byte_count : unsigned(2 downto 0);
    signal accel_data : std_logic_vector(47 downto 0);
    signal wait_counter : unsigned(23 downto 0);
    signal cmd_timeout_counter : unsigned(23 downto 0);
    signal recovery_tick_counter : unsigned(15 downto 0);
    signal recovery_phase : unsigned(4 downto 0);
    signal init_done : std_logic;

    -- Señal para debug: estado actual codificado en 4 bits
	signal state_debug : std_logic_vector(3 downto 0);

begin

    i2c_inst : I2c
        generic map(
            FREQ_G => FREQ_G,
            I2C_FREQ_G => I2C_FREQ_G
        )
        port map(
            clk_i => clk_i,
            rst_i => i2c_core_rst,
            addr_i => i2c_addr,
            data_i => i2c_data_in,
            data_o => i2c_data_out,
            wr_i => i2c_wr,
            rd_i => i2c_rd,
            done_o => i2c_done,
            scl_io => scl_io,
            sda_io => sda_io
        );

    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state <= IDLE;
                i2c_wr <= '0';
                i2c_rd <= '0';
                data_ready_o <= '0';
                byte_count <= (others => '0');
                wait_counter <= (others => '0');
                cmd_timeout_counter <= (others => '0');
                recovery_tick_counter <= (others => '0');
                recovery_phase <= (others => '0');
                init_done <= '0';
                next_state_after_cmd <= IDLE;
            else
                i2c_wr <= '0';
                i2c_rd <= '0';
                data_ready_o <= '0';

                case state is
                    when IDLE =>
                        if init_done = '0' then
                            state <= INIT_POWER_WAIT;
                            wait_counter <= (others => '0');
                        elsif start_read_i = '1' then
                            state <= START_COND;
                            byte_count <= (others => '0');
                            wait_counter <= (others => '0');
                        end if;

                    -- Habilitar el core I2C escribiendo 0x80 al registro de control
                    when INIT_I2C =>
                        i2c_addr <= ADDR_CTR;
                        i2c_data_in <= x"80";
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= INIT_ADDR_W;
                            wait_counter <= (others => '0');
                        end if;

                    -- Cargar direccion I2C del BMI160 en modo escritura al TXR
                    when INIT_ADDR_W =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_TXR;
                            i2c_data_in <= BMI160_ADDR_WRITE;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                wait_counter <= (others => '0');
                                state <= INIT_START;
                            end if;
                        end if;

                    -- Generar START y transmitir la direccion ya cargada en TXR
                    when INIT_START =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_CR;
                            i2c_data_in <= CMD_START or CMD_WRITE;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                next_state_after_cmd <= INIT_REG;
                                state <= WAIT_I2C_CMD;
                                wait_counter <= (others => '0');
                                cmd_timeout_counter <= (others => '0');
                            end if;
                        end if;

                    -- Estado mantenido para compatibilidad con debug; no se usa en el flujo normal.
                    when INIT_ADDR_ACK =>
                        state <= INIT_REG;

                    -- Escribir direccion del registro CMD (0x7E) al TXR
                    when INIT_REG =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_TXR;
                            i2c_data_in <= CMD_REG;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                wait_counter <= (others => '0');
                                state <= INIT_REG_ACK;
                            end if;
                        end if;

                    -- Enviar comando WRITE para transmitir el registro
                    when INIT_REG_ACK =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_CR;
                            i2c_data_in <= CMD_WRITE;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                next_state_after_cmd <= INIT_DATA;
                                state <= WAIT_I2C_CMD;
                                wait_counter <= (others => '0');
                                cmd_timeout_counter <= (others => '0');
                            end if;
                        end if;

                    -- Escribir comando para poner acelerometro en modo normal (0x11) al TXR
                    when INIT_DATA =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_TXR;
                            i2c_data_in <= ACC_NORMAL_MODE;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                wait_counter <= (others => '0');
                                state <= INIT_DATA_ACK;
                            end if;
                        end if;

                    -- Enviar comando WRITE para transmitir el dato
                    when INIT_DATA_ACK =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_CR;
                            i2c_data_in <= CMD_WRITE;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                next_state_after_cmd <= INIT_STOP;
                                state <= WAIT_I2C_CMD;
                                wait_counter <= (others => '0');
                                cmd_timeout_counter <= (others => '0');
                            end if;
                        end if;

                    -- Generar condicion STOP para finalizar la inicializacion
                    when INIT_STOP =>
                        if wait_counter < 10 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_CR;
                            i2c_data_in <= CMD_STOP;
                            i2c_wr <= '1';
                            if i2c_done = '1' then
                                next_state_after_cmd <= INIT_WAIT;
                                state <= WAIT_I2C_CMD;
                                wait_counter <= (others => '0');
                                cmd_timeout_counter <= (others => '0');
                            end if;
                        end if;

                    -- Esperar 4ms para que el sensor se estabilice (400000 ciclos @ 100MHz)
                    when INIT_WAIT =>
                        if wait_counter < 400000 then
                            wait_counter <= wait_counter + 1;
                        else
                            init_done <= '1';
                            state <= IDLE;
                        end if;

                    -- Esperar a que termine el comando I2C real (bit TIP del SR = 0).
                    -- done_o del wrapper solo confirma la transaccion Wishbone, no el byte en el bus I2C.
                    when WAIT_I2C_CMD =>
                        if wait_counter < 2 then
                            wait_counter <= wait_counter + 1;
                        else
                            i2c_addr <= ADDR_SR;
                            i2c_rd <= '1';
                            if i2c_done = '1' then
                                state <= WAIT_I2C_EVAL;
                            end if;
                        end if;

                    -- Evaluar el SR un ciclo despues del ACK Wishbone para usar data_o ya actualizado.
                    when WAIT_I2C_EVAL =>
                        if i2c_data_out(1) = '0' then
                            state <= next_state_after_cmd;
                            wait_counter <= (others => '0');
                        else
                            state <= WAIT_I2C_CMD;
                        end if;

                    -- LECTURA DE DATOS: cargar direccion de escritura
                    when START_COND =>
                        i2c_addr <= ADDR_TXR;
                        i2c_data_in <= BMI160_ADDR_WRITE;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= SEND_ADDR_W;
                        end if;

                    -- Generar START y transmitir la direccion I2C en modo escritura
                    when SEND_ADDR_W =>
                        i2c_addr <= ADDR_CR;
                        i2c_data_in <= CMD_START or CMD_WRITE;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            next_state_after_cmd <= SEND_REG;
                            state <= WAIT_I2C_CMD;
                            wait_counter <= (others => '0');
                        end if;

                    -- Estado mantenido para compatibilidad con debug; no se usa en el flujo normal.
                    when ACK_ADDR_W =>
                        state <= SEND_REG;

                    -- Enviar direccion del registro a leer (0x12 = ACC_X LSB) al TXR
                    when SEND_REG =>
                        i2c_addr <= ADDR_TXR;
                        i2c_data_in <= ACCEL_X_LSB;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= ACK_REG;
                        end if;

                    -- Enviar comando WRITE para transmitir el registro
                    when ACK_REG =>
                        i2c_addr <= ADDR_CR;
                        i2c_data_in <= CMD_WRITE;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            next_state_after_cmd <= SEND_ADDR_R;
                            state <= WAIT_I2C_CMD;
                            wait_counter <= (others => '0');
                        end if;

                    -- Generar condicion RESTART (START repetido)
                    when RESTART_COND =>
                        i2c_addr <= ADDR_CR;
                        i2c_data_in <= CMD_START or CMD_WRITE;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            next_state_after_cmd <= READ_BYTE;
                            state <= WAIT_I2C_CMD;
                            wait_counter <= (others => '0');
                        end if;

                    -- Cargar direccion I2C en modo lectura al TXR
                    when SEND_ADDR_R =>
                        i2c_addr <= ADDR_TXR;
                        i2c_data_in <= BMI160_ADDR_READ;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= RESTART_COND;
                        end if;

                    -- Estado mantenido para compatibilidad con debug; no se usa en el flujo normal.
                    when ACK_ADDR_R =>
                        state <= READ_BYTE;
                        byte_count <= (others => '0');

                    -- Leer byte del sensor, enviar ACK si no es el ultimo byte
                    when READ_BYTE =>
                        i2c_addr <= ADDR_CR;
                        if byte_count < 5 then
                            -- ACK para continuar leyendo (bit ACK=0)
                            i2c_data_in <= CMD_READ;
                        else
                            -- NACK en el ultimo byte (bit ACK=1)
                            i2c_data_in <= CMD_READ or CMD_NACK;
                        end if;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            next_state_after_cmd <= ACK_BYTE;
                            state <= WAIT_I2C_CMD;
                            wait_counter <= (others => '0');
                        end if;

                    -- Leer el byte recibido del registro TXR
                    when ACK_BYTE =>
                        i2c_rd <= '1';
                        i2c_addr <= ADDR_TXR;
                        if i2c_done = '1' then
                            -- Almacenar byte leido en el buffer
                            accel_data(to_integer(byte_count)*8 + 7 downto
                                      to_integer(byte_count)*8) <= i2c_data_out;

                            if byte_count = 5 then
                                state <= STOP_COND;
                            else
                                byte_count <= byte_count + 1;
                                state <= READ_BYTE;
                            end if;
                        end if;

                    -- Generar condicion STOP para finalizar la lectura
                    when STOP_COND =>
                        i2c_addr <= ADDR_CR;
                        i2c_data_in <= CMD_STOP;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            next_state_after_cmd <= DONE_ST;
                            state <= WAIT_I2C_CMD;
                            wait_counter <= (others => '0');
                        end if;

                    -- Transferir datos leidos a las salidas y señalizar lectura completa
                    when DONE_ST =>
                        accel_x_o <= accel_data(15 downto 0);
                        accel_y_o <= accel_data(31 downto 16);
                        accel_z_o <= accel_data(47 downto 32);
                        data_ready_o <= '1';
                        state <= IDLE;

                end case;

                -- Casos de debug para i2c: evitar que estados normales caigan en x"F".
                case state is
                    when IDLE => state_debug <= x"0";
                    when INIT_I2C => state_debug <= x"1";
                    when INIT_ADDR_W => state_debug <= x"2";
                    when INIT_START => state_debug <= x"3";
                    when INIT_REG => state_debug <= x"4";
                    when INIT_REG_ACK => state_debug <= x"5";
                    when INIT_DATA => state_debug <= x"6";
                    when INIT_DATA_ACK => state_debug <= x"7";
                    when INIT_STOP => state_debug <= x"8";
                    when INIT_WAIT => state_debug <= x"9";
                    when WAIT_I2C_CMD | WAIT_I2C_EVAL => state_debug <= x"A";
                    when START_COND | SEND_ADDR_W => state_debug <= x"B";
                    when SEND_REG | ACK_REG => state_debug <= x"C";
                    when SEND_ADDR_R | RESTART_COND => state_debug <= x"D";
                    when READ_BYTE | ACK_BYTE | STOP_COND | DONE_ST => state_debug <= x"E";
                    when others => state_debug <= x"F";
                end case;

            end if;
        end if;
    end process;

    -- Exponer señal de inicializacion para debug
    init_done_o <= init_done;
    -- Exponer estado para debug
	state_debug_o <= state_debug;

end architecture;

