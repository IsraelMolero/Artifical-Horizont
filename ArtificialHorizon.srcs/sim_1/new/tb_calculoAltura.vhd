----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.04.2026 11:13:19
-- Design Name: 
-- Module Name: tb_calculoAltura - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_calculo_altura is

end tb_calculo_altura;

architecture behavior of tb_calculo_altura is


    component calculo_altura
    Port ( 
        clk        : in  STD_LOGIC;
        adc_data12 : in  STD_LOGIC_VECTOR (11 downto 0);
        altura_m   : out STD_LOGIC_VECTOR (15 downto 0)
    );
    end component;


    signal tb_clk        : std_logic := '0';
    signal tb_adc_data12 : std_logic_vector(11 downto 0) := (others => '0');
    signal tb_altura_m   : std_logic_vector(15 downto 0);


    constant clk_period : time := 10 ns;

begin

    uut: calculo_altura PORT MAP (
        clk        => tb_clk,
        adc_data12 => tb_adc_data12,
        altura_m   => tb_altura_m
    );

    clk_process :process
    begin
        tb_clk <= '0';
        wait for clk_period/2;
        tb_clk <= '1';
        wait for clk_period/2;
    end process;

    stim_proc: process
    begin
        wait for 100 ns;
        -- 0
        tb_adc_data12 <= std_logic_vector(to_unsigned(4095, 12));
        wait for 20 ns;
        -- 13685 
        tb_adc_data12 <= std_logic_vector(to_unsigned(0, 12));
        wait for 20 ns;
        --4325 
        tb_adc_data12 <= std_logic_vector(to_unsigned(2048, 12));
        wait for 20 ns;
        -- 2037 
        tb_adc_data12 <= std_logic_vector(to_unsigned(3000, 12));
        wait for 20 ns;
        for i in 3900 to 3910 loop
            tb_adc_data12 <= std_logic_vector(to_unsigned(i, 12));
            wait for 10 ns;
        end loop;
        wait;
    end process;

end behavior;
