library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity seven_segment_display is
    port(
        clk   : in std_logic;
        value : in unsigned(13 downto 0);
        seg   : out std_logic_vector(6 downto 0);
        an    : out std_logic_vector(3 downto 0)
    );
end seven_segment_display;

architecture behavioral of seven_segment_display is
    signal refresh_counter : unsigned(19 downto 0) := (others => '0');
    signal digit_select    : std_logic_vector(1 downto 0);
    signal bcd_digit       : unsigned(3 downto 0);
    signal thousands       : unsigned(3 downto 0);
    signal hundreds        : unsigned(3 downto 0);
    signal tens            : unsigned(3 downto 0);
    signal unit            : unsigned(3 downto 0);
begin
    process(value)
    begin
        thousands <= resize(value / 1000, 4);
        hundreds  <= resize((value / 100) mod 10, 4);
        tens      <= resize((value / 10) mod 10, 4);
        unit      <= resize(value mod 10, 4);
    end process;

    process(clk)
    begin
        if(rising_edge(clk)) then
            refresh_counter <= refresh_counter + 1;
     	end if;
    end process;

    digit_select <= std_logic_vector(refresh_counter(19 downto 18));

    process(digit_select, thousands, hundreds, tens, unit)
    begin
        case digit_select is
            when "00" =>
                an <= "1110";
                bcd_digit <= unit;
            when "01" =>
                an <= "1101";
                bcd_digit <= tens;
            when "10" =>
                an <= "1011";
                bcd_digit <= hundreds;
            when "11" =>
                an <= "0111";
                bcd_digit <= thousands;
            when others =>
                an <= "1111";
                bcd_digit <= "0000";
        end case;
    end process;

    process(bcd_digit)
    begin
        case bcd_digit is
            when "0000" => seg <= "1000000";
            when "0001" => seg <= "1111001";
            when "0010" => seg <= "0100100";
            when "0011" => seg <= "0110000";
            when "0100" => seg <= "0011001";
            when "0101" => seg <= "0010010";
            when "0110" => seg <= "0000010";
            when "0111" => seg <= "1111000";
            when "1000" => seg <= "0000000";
            when "1001" => seg <= "0010000";
            when others => seg <= "1111111";
        end case;
    end process;
end behavioral;