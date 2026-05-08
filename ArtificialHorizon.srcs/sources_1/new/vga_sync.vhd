----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.04.2026 00:32:48
-- Design Name: 
-- Module Name: vga_sync - Behavioral
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

entity vga_sync is
    Port (
        clk25    : in  STD_LOGIC;
        hsync    : out STD_LOGIC;
        vsync    : out STD_LOGIC;
        video_on : out STD_LOGIC;
        x        : out unsigned(9 downto 0);
        y        : out unsigned(9 downto 0)
    );
end vga_sync;

architecture Behavioral of vga_sync is
    signal h_count : unsigned(9 downto 0) := (others => '0');
    signal v_count : unsigned(9 downto 0) := (others => '0');
begin
    process(clk25)
    begin
        if rising_edge(clk25) then
            if h_count = 799 then
                h_count <= (others => '0');
                if v_count = 524 then
                    v_count <= (others => '0');
                else
                    v_count <= v_count + 1;
                end if;
            else
                h_count <= h_count + 1;
            end if;
        end if;
    end process;
    -- video_on <= '1' when (h_count < 640 and v_count < 480) else '0';
    -- video_on <= '1' when (h_count >= 120 and h_count < 520 and v_count >= 40 and v_count < 440) else '0';
	video_on <= '1' when (h_count < 400 and v_count < 400) else '0';
	
    hsync <= '0' when (h_count >= 656 and h_count < 752) else '1';
    vsync <= '0' when (v_count >= 490 and v_count < 492) else '1';

    x <= h_count;
    y <= v_count;
end Behavioral;
