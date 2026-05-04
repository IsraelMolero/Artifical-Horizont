library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
            Vsync    : out STD_LOGIC;
            seg      : out STD_LOGIC_VECTOR(6 downto 0);
            an       : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component;

    signal clk_tb      : STD_LOGIC := '0';
    signal vgaRed_tb   : STD_LOGIC_VECTOR(3 downto 0);
    signal vgaGreen_tb : STD_LOGIC_VECTOR(3 downto 0);
    signal vgaBlue_tb  : STD_LOGIC_VECTOR(3 downto 0);
    signal Hsync_tb    : STD_LOGIC;
    signal Vsync_tb    : STD_LOGIC;
    signal seg_tb      : STD_LOGIC_VECTOR(6 downto 0);
    signal an_tb       : STD_LOGIC_VECTOR(3 downto 0);


    signal div_sim     : unsigned(1 downto 0) := "00";
    signal clk25_sim   : STD_LOGIC;
    

    signal x_sim       : integer := -4; 
    signal y_sim       : integer := 0;

begin

    uut: top_vga port map (
        clk      => clk_tb,
        vgaRed   => vgaRed_tb,
        vgaGreen => vgaGreen_tb,
        vgaBlue  => vgaBlue_tb,
        Hsync    => Hsync_tb,
        Vsync    => Vsync_tb,
        seg      => seg_tb,
        an       => an_tb
    );

    process
    begin
        clk_tb <= '0'; wait for 5 ns;
        clk_tb <= '1'; wait for 5 ns;
    end process;


    process(clk_tb)
    begin
        if rising_edge(clk_tb) then
            div_sim <= div_sim + 1;
        end if;
    end process;
    clk25_sim <= div_sim(1);


    process(clk25_sim)
    begin
        if rising_edge(clk25_sim) then
            if x_sim = 799 then
                x_sim <= 0;
                
                if y_sim = 524 then
                    y_sim <= 0;
                else
                    y_sim <= y_sim + 1;
                end if;
            else
                x_sim <= x_sim + 1;
            end if;
        end if;
    end process;

end sim;