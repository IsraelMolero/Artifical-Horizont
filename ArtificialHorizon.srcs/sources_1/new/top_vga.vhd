----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 30.04.2026 00:35:33
-- Design Name: 
-- Module Name: top_vga - Behavioral
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


entity top_vga is
    Port (
        clk      : in  STD_LOGIC;
        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync    : out STD_LOGIC;
        Vsync    : out STD_LOGIC
    );
end top_vga;

architecture Structural of top_vga is

    component clk_div_25
        Port (
            clk100 : in  STD_LOGIC;
            clk25  : out STD_LOGIC
        );
    end component;

    component vga_sync
        Port (
            clk25    : in  STD_LOGIC;
            hsync    : out STD_LOGIC;
            vsync    : out STD_LOGIC;
            video_on : out STD_LOGIC;
            x        : out unsigned(9 downto 0);
            y        : out unsigned(9 downto 0)
        );
    end component;

    signal clk25_s    : STD_LOGIC;
    signal video_on_s : STD_LOGIC;
    signal x_s        : unsigned(9 downto 0);
    signal y_s        : unsigned(9 downto 0);

begin

    U1: clk_div_25
        port map (
            clk100 => clk,
            clk25  => clk25_s
        );

    U2: vga_sync
        port map (
            clk25    => clk25_s,
            hsync    => Hsync,
            vsync    => Vsync,
            video_on => video_on_s,
            x        => x_s,
            y        => y_s
        );

    process(video_on_s, y_s)
    begin
        if video_on_s = '1' then
            if y_s < 240 then
                vgaRed   <= "0000";
                vgaGreen <= "0110";
                vgaBlue  <= "1111";
            else
                vgaRed   <= "1001";
                vgaGreen <= "0100";
                vgaBlue  <= "0000";
            end if;
        else
            vgaRed   <= "0000";
            vgaGreen <= "0000";
            vgaBlue  <= "0000";
        end if;
    end process;

end Structural;