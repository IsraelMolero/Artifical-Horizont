library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_vga_tb is
end top_vga_tb;

architecture sim of top_vga_tb is
    component top_vga
        port(
            clk      : in  std_logic;
            vgaRed   : out std_logic_vector(3 downto 0);
            vgaGreen : out std_logic_vector(3 downto 0);
            vgaBlue  : out std_logic_vector(3 downto 0);
            Hsync    : out std_logic;
            Vsync    : out std_logic;
            seg      : out std_logic_vector(6 downto 0);
            an       : out std_logic_vector(3 downto 0)
        );
    end component;

    signal clk_tb      : std_logic := '0';
    signal vgaRed_tb   : std_logic_vector(3 downto 0);
    signal vgaGreen_tb : std_logic_vector(3 downto 0);
    signal vgaBlue_tb  : std_logic_vector(3 downto 0);
    signal Hsync_tb    : std_logic;
    signal Vsync_tb    : std_logic;
    signal seg_tb      : std_logic_vector(6 downto 0);
    signal an_tb       : std_logic_vector(3 downto 0);

    constant clk_period : time := 10 ns;
    signal rgb_combined : std_logic_vector(11 downto 0);

begin
    uut: top_vga
        port map(
            clk      => clk_tb,
            vgaRed   => vgaRed_tb,
            vgaGreen => vgaGreen_tb,
            vgaBlue  => vgaBlue_tb,
            Hsync    => Hsync_tb,
            Vsync    => Vsync_tb,
            seg      => seg_tb,
            an       => an_tb
        );

    rgb_combined <= vgaRed_tb & vgaGreen_tb & vgaBlue_tb;

    process
    begin
        while now < 17 ms loop
            clk_tb <= '0';
            wait for clk_period / 2;
            clk_tb <= '1';
            wait for clk_period / 2;
        end loop;
        wait;
    end process;

    process(clk_tb)
        variable prev_rgb : std_logic_vector(11 downto 0) := (others => '0');
    begin
        if rising_edge(clk_tb) then
            if rgb_combined /= prev_rgb then
                if Hsync_tb = '1' and Vsync_tb = '1' then
                    report "Color Transition at " & time'image(now) & 
                           " -> RGB Hex: " & 
                           std_logic'image(vgaRed_tb(3)) & std_logic'image(vgaRed_tb(2)) & 
                           std_logic'image(vgaRed_tb(1)) & std_logic'image(vgaRed_tb(0)) & " " &
                           std_logic'image(vgaBlue_tb(3)) & std_logic'image(vgaBlue_tb(2)) & 
                           std_logic'image(vgaBlue_tb(1)) & std_logic'image(vgaBlue_tb(0));
                end if;
                prev_rgb := rgb_combined;
            end if;
        end if;
    end process;

end sim;
