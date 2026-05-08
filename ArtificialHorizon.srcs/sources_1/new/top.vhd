library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        clk      : in  STD_LOGIC;
        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync    : out STD_LOGIC;
        Vsync    : out STD_LOGIC;
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top;

architecture Structural of top is

    signal clk25_s    : STD_LOGIC;
    signal x_s, y_s   : unsigned(9 downto 0);
    signal engine_out : STD_LOGIC;
    
    -- pitch y roll
    signal pitch_s    : unsigned(7 downto 0) := x"00";
    signal roll_s     : unsigned(7 downto 0) := x"00";
   
begin

    -- Divisor de Reloj
    U_CLK: entity work.clk_div_25
        port map (
            clk100 => clk,
            clk25  => clk25_s
        );

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
