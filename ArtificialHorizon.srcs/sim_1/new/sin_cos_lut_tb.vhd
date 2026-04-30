library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sin_cos_lut_tb is
end entity;

architecture sim of sin_cos_lut_tb is
    constant CLK_PERIOD : time := 10 ns;

    signal clk   : std_logic := '0';
    signal angle : unsigned(7 downto 0) := (others => '0');
    signal sin : signed(15 downto 0);
    signal cos : signed(15 downto 0);

begin
    uut: entity work.lut_sin_cos
        port map (
            clk   => clk,
            angle => angle,
            sin => sin,
            cos => cos
        );

    clk_process: process
    begin
        while now < 5000 ns loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stim_process: process
    begin
        wait for CLK_PERIOD * 2;

        for i in 0 to 255 loop
            angle <= to_unsigned(i, 8);
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 10;
        assert false report "End of simulation" severity failure;
        wait;
    end process;

end architecture;
