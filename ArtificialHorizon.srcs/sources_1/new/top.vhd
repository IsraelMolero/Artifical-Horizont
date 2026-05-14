library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        -- Debug LEDs
        led      : out STD_LOGIC_VECTOR(15 downto 0);
        -- reloj del sistema
        clk      : in  STD_LOGIC;
        -- Reset (boton BTNC, activo en alto) para el receptor UART
        btn_rst  : in  STD_LOGIC;
        -- Entrada UART desde el TX de la ESP32-C3
        rx       : in  STD_LOGIC;
        -- VGA
        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync    : out STD_LOGIC;
        Vsync    : out STD_LOGIC;
        -- 7 segmentos
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top;

architecture Structural of top is

    signal clk25_s    : STD_LOGIC;
    signal x_s, y_s   : unsigned(9 downto 0);
    signal engine_out : STD_LOGIC;

    -- Angulos recibidos por UART desde la ESP32-C3
    -- Cada uno es un byte mapeado: -180 -> 0, 0 -> 128, +180 -> 255
    signal yaw_s   : std_logic_vector(7 downto 0);
    signal pitch_v : std_logic_vector(7 downto 0);
    signal roll_v  : std_logic_vector(7 downto 0);

    -- Versiones unsigned para alimentar al motor logico
    signal pitch_s : unsigned(7 downto 0);
    signal roll_s  : unsigned(7 downto 0);

    -- Pulso de un ciclo cuando llega un paquete valido (debug)
    signal data_valid_s : std_logic;

    -- Valor a mostrar en el display de 7 segmentos
    -- El display espera 14 bits; ponemos yaw en los 8 bits bajos
    signal display_value_s : unsigned(13 downto 0);

begin

    -- Divisor de Reloj 100MHz -> 25MHz para la VGA
    U_CLK: entity work.clk_div_25
        port map (
            clk100 => clk,
            clk25  => clk25_s
        );

    -- Receptor UART + parser de paquetes IMU
    -- Trama: 0xAA | yaw | pitch | roll | checksum (XOR de los 3)
    U_UART_RX: entity work.imu_uart_rx
        generic map (
            CLK_FREQ  => 100_000_000,
            BAUD_RATE => 115_200
        )
        port map (
            clk        => clk,
            reset      => btn_rst,
            rx         => rx,
            yaw_out    => yaw_s,
            pitch_out  => pitch_v,
            roll_out   => roll_v,
            data_valid => data_valid_s
        );

    -- Conversion a unsigned para el motor logico
    pitch_s <= unsigned(pitch_v);
    roll_s  <= unsigned(roll_v) + 127;

    -- Controlador VGA
    U_VGA_CTRL: entity work.top_vga
        port map (
            clk25      => clk25_s,
            engine_out => engine_out,
            x_out      => x_s,
            y_out      => y_s,
            vgaRed     => vgaRed,
            vgaGreen   => vgaGreen,
            vgaBlue    => vgaBlue,
            Hsync      => Hsync,
            Vsync      => Vsync
        );

    -- Motor Logico
 
    U_ENGINE: entity work.linear_engine
        port map (
            clk    => clk25_s,
            x      => x_s,
            y      => y_s,
            pitch  => pitch_s,
            roll   => roll_s,
            output => engine_out
        );

    -- Debug en LEDs
    -- led(15:8) -> pitch para ver que tambien llega
    -- led(7:0)  -> yaw, el mismo valor que aparece en el display
    led(15 downto 8) <= pitch_v;
    led(7  downto 0) <= yaw_s;

    -- Display 7 Segmentos: mostramos yaw
    -- yaw es de 8 bits y el modulo espera 14, asi que rellenamos arriba
    -- con ceros. El valor mostrado en decimal sera 0..255.
    display_value_s <= resize(unsigned(roll_v), 14);
    U_7SEG: entity work.seven_segment_display
        port map (
            clk   => clk,
            value => display_value_s,
            seg   => seg,
            an    => an
        );

end Structural;