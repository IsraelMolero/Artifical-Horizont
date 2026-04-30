library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity linear_engine_tb is
end linear_engine_tb;

architecture sim of linear_engine_tb is
    constant CLK_PERIOD : time := 10 ns;
    
    signal clk    : std_logic := '0';
    signal x      : unsigned(9 downto 0) := (others => '0');
    signal y      : unsigned(9 downto 0) := (others => '0');
    signal pitch  : unsigned(7 downto 0) := (others => '0');
    signal roll   : unsigned(7 downto 0) := (others => '0');
    signal output : std_logic;

begin
    uut: entity work.linear_engine
        port map (
            clk    => clk,
            x      => x,
            y      => y,
            pitch  => pitch,
            roll   => roll,
            output => output
        );

    clk_process: process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;

    stim_process: process
    begin
        wait for CLK_PERIOD * 10;

        roll  <= to_unsigned(0, 8);
        pitch <= to_unsigned(0, 8);
        x     <= to_unsigned(200, 10);
        
        for i in 195 to 205 loop
            y <= to_unsigned(i, 10);
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 10;

        pitch <= to_unsigned(20, 8);
        for i in 215 to 225 loop
            y <= to_unsigned(i, 10);
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 10;

        roll  <= to_unsigned(64, 8);
        pitch <= to_unsigned(0, 8);
        y     <= to_unsigned(200, 10);
        
        for i in 195 to 205 loop
            x <= to_unsigned(i, 10);
            wait for CLK_PERIOD;
        end loop;

        wait for CLK_PERIOD * 50;
        assert false report "Simulation finished" severity failure;
        wait;
    end process;
end sim;


