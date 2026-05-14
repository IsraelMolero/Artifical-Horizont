library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity linear_engine is
    port(
        x, y   : in  unsigned;
        output : out std_logic;
        pitch  : in  unsigned(7 downto 0);
        roll   : in  unsigned(7 downto 0);
        clk    : in  std_logic
    );
end linear_engine;

architecture Behavioral of linear_engine is

    signal x_rel, y_rel       : signed(10 downto 0);
    signal prod_x, prod_y     : signed(26 downto 0);
    signal res_intermedio     : signed(26 downto 0);
    signal sin, cos           : signed(15 downto 0);

    -- Pitch centrado en cero: el sensor envia 128 para 0 grados,
    -- asi que restamos 128 para tener un rango con signo de -128..+127
    signal pitch_centered     : signed(8 downto 0);

    -- Pitch ya extendido y escalado para sumarlo al resultado
    -- Aumenta o disminuye el valor de PITCH_SHIFT para cambiar
    -- la sensibilidad del eje vertical (mas bits = mas sensible)
    constant PITCH_SHIFT      : integer := 10;
    signal pitch_term         : signed(26 downto 0);

begin

    trig_table: entity work.lut_sin_cos
        port map(clk => clk, angle => roll, sin => sin, cos => cos);

    -- Centrado de pitch en cero
    -- 128 -> 0, 0 -> -128, 255 -> +127
    pitch_centered <= signed('0' & pitch) - to_signed(128, 9);

    -- Extension de signo a 27 bits y desplazamiento a la izquierda
    -- PITCH_SHIFT bits para amplificar su efecto
    pitch_term <= shift_left(resize(pitch_centered, 27), PITCH_SHIFT);

    process(clk)
    begin
        if rising_edge(clk) then
            -- Ecuacion normal de la recta
            x_rel <= signed("0" & x) - 200;
            y_rel <= signed("0" & y) - 200;
            prod_x <= x_rel * sin;
            prod_y <= y_rel * cos;
            res_intermedio <= prod_x - prod_y + pitch_term;

            if res_intermedio < 0 then
                output <= '0';
            else
                output <= '1';
            end if;
        end if;
    end process;

end Behavioral;