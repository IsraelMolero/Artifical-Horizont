library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk      : in  STD_LOGIC;
        --- VGA
        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync    : out STD_LOGIC;
        Vsync    : out STD_LOGIC;
        --- 7 Segmentos
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC_VECTOR(3 downto 0);
        --- NEW Israel -> I2C
        scl_io   : inout STD_LOGIC;
        sda_io   : inout STD_LOGIC
    );
end top;

architecture Structural of top is

    signal clk25_s    : STD_LOGIC;
    signal x_s, y_s   : unsigned(9 downto 0);
    signal engine_out : STD_LOGIC;
    
    -- pitch y roll
    signal pitch_s    : unsigned(7 downto 0) := x"00";
    signal roll_s     : unsigned(7 downto 0) := x"00";
    -- New Israel -> Señales para hacer el cast
    
    signal accel_x_s  : std_logic_vector(15 downto 0);
    signal accel_y_s  : std_logic_vector(15 downto 0);
    
   
begin

    -- Divisor de Reloj
    U_CLK: entity work.clk_div_25
        port map (
            clk100 => clk,
            clk25  => clk25_s
        );

   -- NEW Israel -> Usamos el core y el sensor control del I2C de la liberia que hemos importado
    U_SENSOR_READER: entity work.bmi160_reader
        generic map (
            FREQ_G     => 100.0,
            I2C_FREQ_G => 0.4
        )
        port map (
            clk_i        => clk,
            rst_i        => '0',
            start_read_i => '1',
            accel_x_o    => accel_x_s,
            accel_y_o    => accel_y_s,
            accel_z_o    => open, 
            data_ready_o => open,
            scl_io       => scl_io,
            sda_io       => sda_io
        );

    pitch_s <= unsigned(accel_x_s(15 downto 8));
    roll_s  <= unsigned(accel_y_s(15 downto 8));



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

    -- Motor Lógico
    U_ENGINE: entity work.linear_engine
        port map (
            clk    => clk25_s,
            x      => x_s,
            y      => y_s,
            pitch  => pitch_s,
            roll   => roll_s,
            output => engine_out
        );

    -- Display 7 Segmentos
    U_7SEG: entity work.seven_segment_display
        port map (
            clk   => clk,
            value => "00000000000000",
            seg   => seg,
            an    => an
        );

end Structural;
