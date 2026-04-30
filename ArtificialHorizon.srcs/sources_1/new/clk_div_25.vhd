----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.04.2026 00:24:47
-- Design Name: 
-- Module Name: clk_div_25 - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clk_div_25 is
    Port (
        clk100 : in  STD_LOGIC;
        clk25  : out STD_LOGIC
    );
end clk_div_25;

architecture Behavioral of clk_div_25 is
    signal div : unsigned(1 downto 0) := "00";
begin
    process(clk100)
    begin
        if rising_edge(clk100) then
            div <= div + 1;        
        end if;
    end process;

    clk25 <= div(1);
end Behavioral;