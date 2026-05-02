library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity linear_engine is
	port(x, y : in unsigned; output : out std_logic; pitch, roll : in unsigned(7 downto 0); clk : in std_logic);
end linear_engine;

architecture Behavioral of linear_engine is
    signal x_rel, y_rel : signed(10 downto 0);
    signal prod_x, prod_y : signed(26 downto 0); 
    signal res_intermedio : signed(26 downto 0);
    signal sin, cos : signed(15 downto 0);
begin
    trig_table: entity work.lut_sin_cos
        port map(clk => clk, angle => roll, sin => sin, cos => cos);

    process(clk)
    begin
        if rising_edge(clk) then
        	-- Ecuación normal de la recta
            x_rel <= signed("0" & x) - 200;
            y_rel <= signed("0" & y) - 200;

            prod_x <= x_rel * sin;
            prod_y <= y_rel * cos;

            res_intermedio <= prod_x - prod_y + signed(pitch & "00000000");
            
            if res_intermedio < 0 then
                output <= '0';
            else
                output <= '1';
            end if;
        end if;
    end process;
end Behavioral;



