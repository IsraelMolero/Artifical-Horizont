library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity bme680_altitude_system is
    Generic (
        CLK_FREQ_MHZ : real := 100.0 
    );
    Port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        scl_io   : inout std_logic;
        sda_io   : inout std_logic;
        altura_m : out integer
    );
end bme680_altitude_system;

architecture rtl of bme680_altitude_system is

    -- 1. DECLARACIÓN DEL CONTROLADOR I2C (i2c_master.vhd)
    component I2c is
        generic (
            FREQ_G     : real;
            I2C_FREQ_G : real
        );
        port (
            clk_i  : in    std_logic;
            rst_i  : in    std_logic;
            addr_i : in    std_logic_vector(3 downto 0);
            data_i : in    std_logic_vector(7 downto 0);
            data_o : out   std_logic_vector(7 downto 0);
            wr_i   : in    std_logic;
            rd_i   : in    std_logic;
            done_o : out   std_logic;
            scl_io : inout std_logic;
            sda_io : inout std_logic
        );
    end component;

    -- 2. DECLARACIÓN DE TU NUEVA LUT (bme680_rom_lut.vhd)
    component bme680_rom_lut is
        Port (
            clk      : in  STD_LOGIC;
            addr     : in  STD_LOGIC_VECTOR (11 downto 0);
            data_out : out integer
        );
    end component;

    -- 3. CONSTANTES I2C DEL BME680
    constant BME680_I2C_W  : std_logic_vector(7 downto 0) := x"EC";
    constant BME680_I2C_R  : std_logic_vector(7 downto 0) := x"ED";
    constant REG_CTRL_MEAS : std_logic_vector(7 downto 0) := x"74";
    constant REG_PRESS_MSB : std_logic_vector(7 downto 0) := x"1F";

    -- 4. SEÑALES INTERNAS
    signal i2c_addr : std_logic_vector(3 downto 0) := (others => '0');
    signal i2c_din  : std_logic_vector(7 downto 0) := (others => '0');
    signal i2c_dout : std_logic_vector(7 downto 0);
    signal i2c_wr   : std_logic := '0';
    signal i2c_rd   : std_logic := '0';
    signal i2c_done : std_logic;

    -- MÁQUINA DE ESTADOS
    type state_t is (SETUP_I2C, START_MEAS, WAIT_MEAS, READ_PRESS, WAIT_ROM);
    signal state     : state_t := SETUP_I2C;
    signal sub_state : integer range 0 to 15 := 0;
    
    signal press_12b : unsigned(11 downto 0) := (others => '0');
    signal msb_buf   : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- Instanciación del módulo I2C
    u_i2c: I2c 
        generic map (
            FREQ_G     => CLK_FREQ_MHZ,
            I2C_FREQ_G => 100.0 
        )
        port map (
            clk_i  => clk,      rst_i  => rst,
            addr_i => i2c_addr, data_i => i2c_din,  data_o => i2c_dout,
            wr_i   => i2c_wr,   rd_i   => i2c_rd,   done_o => i2c_done,
            scl_io => scl_io,   sda_io => sda_io
        );

    -- Instanciación de tu nueva Memoria ROM
    u_rom: bme680_rom_lut
        port map (
            clk      => clk,
            addr     => std_logic_vector(press_12b), -- Le pasamos la presión leída
            data_out => altura_m                     -- Sale directo al puerto final
        );

    -- Máquina de estados principal
    process(clk)
        variable timer : integer := 0;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= SETUP_I2C;
                sub_state <= 0;
                i2c_wr <= '0'; i2c_rd <= '0';
                timer := 0;
                press_12b <= (others => '0');
            else
                case state is
                    
                    when SETUP_I2C =>
                        i2c_addr <= "0010"; i2c_din <= x"80"; i2c_wr <= '1';
                        if i2c_done = '1' then i2c_wr <= '0'; state <= START_MEAS; end if;

                    when START_MEAS =>
                        case sub_state is
                            when 0 => i2c_addr <= "0011"; i2c_din <= BME680_I2C_W; i2c_wr <= '1'; 
                            when 1 => i2c_addr <= "0100"; i2c_din <= x"90"; i2c_wr <= '1'; 
                            when 2 => i2c_addr <= "0011"; i2c_din <= REG_CTRL_MEAS; i2c_wr <= '1'; 
                            when 3 => i2c_addr <= "0100"; i2c_din <= x"10"; i2c_wr <= '1'; 
                            when 4 => i2c_addr <= "0011"; i2c_din <= x"05"; i2c_wr <= '1'; 
                            when 5 => i2c_addr <= "0100"; i2c_din <= x"50"; i2c_wr <= '1'; 
                            when others => 
                                i2c_wr <= '0'; sub_state <= 0; state <= WAIT_MEAS; 
                        end case;
                        
                        if i2c_wr = '1' and i2c_done = '1' then
                            sub_state <= sub_state + 1; i2c_wr <= '0'; 
                        end if;

                    when WAIT_MEAS =>
                        if timer > integer(CLK_FREQ_MHZ * 20000.0) then
                            timer := 0; state <= READ_PRESS;
                        else 
                            timer := timer + 1; 
                        end if;

                    when READ_PRESS =>
                        case sub_state is
                            when 0 => i2c_addr <= "0011"; i2c_din <= BME680_I2C_W; i2c_wr <= '1'; 
                            when 1 => i2c_addr <= "0100"; i2c_din <= x"90"; i2c_wr <= '1'; 
                            when 2 => i2c_addr <= "0011"; i2c_din <= REG_PRESS_MSB; i2c_wr <= '1'; 
                            when 3 => i2c_addr <= "0100"; i2c_din <= x"10"; i2c_wr <= '1'; 
                            
                            when 4 => i2c_addr <= "0011"; i2c_din <= BME680_I2C_R; i2c_wr <= '1'; 
                            when 5 => i2c_addr <= "0100"; i2c_din <= x"90"; i2c_wr <= '1'; 
                            
                            when 6 => i2c_addr <= "0100"; i2c_din <= x"20"; i2c_wr <= '1'; 
                            when 7 => i2c_addr <= "0011"; i2c_rd <= '1'; 
                            when 8 => 
                                msb_buf <= i2c_dout; i2c_rd <= '0';
                                
                            when 9 => i2c_addr <= "0100"; i2c_din <= x"68"; i2c_wr <= '1'; 
                            when 10=> i2c_addr <= "0011"; i2c_rd <= '1'; 
                            when 11=> 
                                press_12b <= unsigned(msb_buf) & unsigned(i2c_dout(7 downto 4));
                                i2c_rd <= '0';
                                state <= WAIT_ROM; -- Vamos a esperar a que la ROM reaccione
                                sub_state <= 0;
                                
                            when others => null;
                        end case;
                        
                        if (i2c_wr = '1' or i2c_rd = '1') and i2c_done = '1' then
                            sub_state <= sub_state + 1; i2c_wr <= '0'; i2c_rd <= '0';
                        end if;

                    when WAIT_ROM =>
                        -- La ROM necesita 1 ciclo de reloj para escupir la altura.
                        -- Aquí esperamos y volvemos a iniciar el ciclo completo.
                        state <= START_MEAS;
                        
                end case;
            end if;
        end if;
    end process;

end rtl;