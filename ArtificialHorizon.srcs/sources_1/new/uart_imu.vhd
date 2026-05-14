----------------------------------------------------------------------
-- imu_uart_rx.vhd
-- Receptor UART + parser de paquetes IMU para Basys3 (xc7a35t)
--
-- Protocolo (5 bytes):
--   0xAA | yaw | pitch | roll | checksum
--   checksum = yaw XOR pitch XOR roll
--
-- Parametros por defecto: 100 MHz de reloj, 115200 baud, 8N1, LSB first.
--
-- Salidas:
--   yaw_out, pitch_out, roll_out : registros de 8 bits que se actualizan
--                                  solo cuando se recibe un paquete valido.
--   data_valid                   : pulso de 1 ciclo cuando se actualizan
--                                  los registros (util para depurar).
----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity imu_uart_rx is
    generic (
        CLK_FREQ  : integer := 100_000_000;
        BAUD_RATE : integer := 115_200
    );
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        rx         : in  std_logic;
        yaw_out    : out std_logic_vector(7 downto 0);
        pitch_out  : out std_logic_vector(7 downto 0);
        roll_out   : out std_logic_vector(7 downto 0);
        data_valid : out std_logic
    );
end imu_uart_rx;

architecture rtl of imu_uart_rx is

    ------------------------------------------------------------------
    -- Constantes derivadas del baud rate
    -- BIT_PERIOD : ciclos de clk por bit UART
    -- HALF_BIT   : medio periodo, para muestrear en el centro del bit
    ------------------------------------------------------------------
    constant BIT_PERIOD : integer := CLK_FREQ / BAUD_RATE;
    constant HALF_BIT   : integer := BIT_PERIOD / 2;

    ------------------------------------------------------------------
    -- Sincronizador de doble flip-flop sobre la entrada rx
    -- Evita metaestabilidad porque rx es asincrono respecto a clk
    ------------------------------------------------------------------
    signal rx_sync0 : std_logic := '1';
    signal rx_sync1 : std_logic := '1';

    ------------------------------------------------------------------
    -- FSM del receptor UART de bajo nivel
    -- IDLE  : esperando flanco de bajada (start bit)
    -- START : confirmando start bit en su centro
    -- DATA  : recibiendo los 8 bits de datos
    -- STOP  : esperando el stop bit
    ------------------------------------------------------------------
    type uart_state_t is (UART_IDLE, UART_START, UART_DATA, UART_STOP);
    signal uart_state : uart_state_t := UART_IDLE;

    -- Contador de ciclos dentro de un bit
    signal clk_count : integer range 0 to BIT_PERIOD - 1 := 0;

    -- Indice del bit de datos actual (0..7), LSB primero
    signal bit_index : integer range 0 to 7 := 0;

    -- Registro de desplazamiento donde se va construyendo el byte
    signal rx_shift  : std_logic_vector(7 downto 0) := (others => '0');

    -- Pulso de 1 ciclo: byte recibido y valido en byte_data
    signal byte_ready : std_logic := '0';
    signal byte_data  : std_logic_vector(7 downto 0) := (others => '0');

    ------------------------------------------------------------------
    -- FSM del parser de paquetes IMU
    -- Busca cabecera 0xAA, luego yaw, pitch, roll y checksum
    ------------------------------------------------------------------
    type pkt_state_t is (PKT_HEADER, PKT_YAW, PKT_PITCH, PKT_ROLL, PKT_CHECKSUM);
    signal pkt_state : pkt_state_t := PKT_HEADER;

    -- Registros temporales mientras se acumulan los 3 bytes del paquete
    signal yaw_reg   : std_logic_vector(7 downto 0) := (others => '0');
    signal pitch_reg : std_logic_vector(7 downto 0) := (others => '0');
    signal roll_reg  : std_logic_vector(7 downto 0) := (others => '0');

    -- Registros de salida (solo se actualizan con paquete valido)
    signal yaw_q   : std_logic_vector(7 downto 0) := (others => '0');
    signal pitch_q : std_logic_vector(7 downto 0) := (others => '0');
    signal roll_q  : std_logic_vector(7 downto 0) := (others => '0');

    signal valid_pulse : std_logic := '0';

begin

    ------------------------------------------------------------------
    -- Sincronizacion de rx con clk
    -- Dos flip-flops en cascada para evitar metaestabilidad
    ------------------------------------------------------------------
    sync_proc : process(clk)
    begin
        if rising_edge(clk) then
            rx_sync0 <= rx;
            rx_sync1 <= rx_sync0;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Receptor UART
    -- Detecta start bit, muestrea 8 bits de datos en el centro de
    -- cada bit, comprueba stop bit y entrega el byte recibido.
    ------------------------------------------------------------------
    uart_rx_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                uart_state <= UART_IDLE;
                clk_count  <= 0;
                bit_index  <= 0;
                rx_shift   <= (others => '0');
                byte_ready <= '0';
                byte_data  <= (others => '0');
            else
                -- byte_ready es un pulso de un solo ciclo
                byte_ready <= '0';

                case uart_state is

                    when UART_IDLE =>
                        -- Linea en reposo en alto; un '0' marca start bit
                        clk_count <= 0;
                        bit_index <= 0;
                        if rx_sync1 = '0' then
                            uart_state <= UART_START;
                        end if;

                    when UART_START =>
                        -- Esperar al centro del start bit para confirmarlo
                        if clk_count = HALF_BIT - 1 then
                            if rx_sync1 = '0' then
                                -- Start bit valido, reiniciar contador para
                                -- empezar a muestrear los bits de datos en
                                -- el centro de cada bit
                                clk_count  <= 0;
                                uart_state <= UART_DATA;
                            else
                                -- Falso start (glitch), volver a IDLE
                                uart_state <= UART_IDLE;
                            end if;
                        else
                            clk_count <= clk_count + 1;
                        end if;

                    when UART_DATA =>
                        -- Esperar un periodo de bit completo y muestrear
                        if clk_count < BIT_PERIOD - 1 then
                            clk_count <= clk_count + 1;
                        else
                            clk_count <= 0;
                            -- LSB primero: el bit recibido entra por la
                            -- posicion MSB del shift register y se va
                            -- desplazando a la derecha
                            rx_shift <= rx_sync1 & rx_shift(7 downto 1);
                            if bit_index = 7 then
                                bit_index  <= 0;
                                uart_state <= UART_STOP;
                            else
                                bit_index <= bit_index + 1;
                            end if;
                        end if;

                    when UART_STOP =>
                        -- Esperar al centro del stop bit
                        if clk_count < BIT_PERIOD - 1 then
                            clk_count <= clk_count + 1;
                        else
                            clk_count  <= 0;
                            -- Solo damos el byte por valido si el stop bit
                            -- esta en alto; si no, lo descartamos
                            if rx_sync1 = '1' then
                                byte_data  <= rx_shift;
                                byte_ready <= '1';
                            end if;
                            uart_state <= UART_IDLE;
                        end if;

                end case;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Parser de paquetes
    -- Maquina que va consumiendo bytes de byte_data cada vez que
    -- byte_ready se activa y reconstruye el paquete de 5 bytes.
    -- Si el checksum coincide, actualiza los registros de salida.
    ------------------------------------------------------------------
    parser_proc : process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                pkt_state   <= PKT_HEADER;
                yaw_reg     <= (others => '0');
                pitch_reg   <= (others => '0');
                roll_reg    <= (others => '0');
                yaw_q       <= (others => '0');
                pitch_q     <= (others => '0');
                roll_q      <= (others => '0');
                valid_pulse <= '0';
            else
                -- Pulso de un solo ciclo
                valid_pulse <= '0';

                if byte_ready = '1' then
                    case pkt_state is

                        when PKT_HEADER =>
                            -- Solo avanzamos si vemos la cabecera 0xAA
                            -- Cualquier otro byte se descarta, permitiendo
                            -- resincronizar si perdemos alineacion
                            if byte_data = x"AA" then
                                pkt_state <= PKT_YAW;
                            end if;

                        when PKT_YAW =>
                            yaw_reg   <= byte_data;
                            pkt_state <= PKT_PITCH;

                        when PKT_PITCH =>
                            pitch_reg <= byte_data;
                            pkt_state <= PKT_ROLL;

                        when PKT_ROLL =>
                            roll_reg  <= byte_data;
                            pkt_state <= PKT_CHECKSUM;

                        when PKT_CHECKSUM =>
                            -- Comprobamos checksum XOR. Si es correcto,
                            -- actualizamos los registros de salida.
                            -- Si no, descartamos el paquete entero.
                            if byte_data = (yaw_reg xor pitch_reg xor roll_reg) then
                                yaw_q       <= yaw_reg;
                                pitch_q     <= pitch_reg;
                                roll_q      <= roll_reg;
                                valid_pulse <= '1';
                            end if;
                            pkt_state <= PKT_HEADER;

                    end case;
                end if;
            end if;
        end if;
    end process;

    ------------------------------------------------------------------
    -- Asignacion de salidas
    ------------------------------------------------------------------
    yaw_out    <= yaw_q;
    pitch_out  <= pitch_q;
    roll_out   <= roll_q;
    data_valid <= valid_pulse;

end rtl;