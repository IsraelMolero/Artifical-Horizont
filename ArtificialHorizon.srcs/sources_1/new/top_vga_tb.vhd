library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_vga_tb is
end top_vga_tb;

architecture sim of top_vga_tb is

    component top_vga
        Port (
            clk      : in  STD_LOGIC;
            vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
            vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
            vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
            Hsync    : out STD_LOGIC;
            Vsync    : out STD_LOGIC
        );
    end component;

    signal clk_tb      : STD_LOGIC := '0';
    signal vgaRed_tb   : STD_LOGIC_VECTOR(3 downto 0);
    signal vgaGreen_tb : STD_LOGIC_VECTOR(3 downto 0);
    signal vgaBlue_tb  : STD_LOGIC_VECTOR(3 downto 0);
    signal Hsync_tb    : STD_LOGIC;
    signal Vsync_tb    : STD_LOGIC;

begin

    uut: top_vga port map (
        clk      => clk_tb,
        vgaRed   => vgaRed_tb,
        vgaGreen => vgaGreen_tb,
        vgaBlue  => vgaBlue_tb,
        Hsync    => Hsync_tb,
        Vsync    => Vsync_tb
    );

    process
    begin
        clk_tb <= '0'; wait for 5 ns;
        clk_tb <= '1'; wait for 5 ns;
    end process;

end sim;
