library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

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
	constant display_size: integer := 400;
	constant line_width: integer := 4;
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
    
    component linear_engine
        port(
            x      : in unsigned;
            y      : in unsigned;
            output : out std_logic;
            pitch  : in unsigned(7 downto 0);
            roll   : in unsigned(7 downto 0);
            clk    : in std_logic
        );
    end component;

    signal clk25_s    : STD_LOGIC;
    signal video_on_s : STD_LOGIC;
    signal x_s        : unsigned(9 downto 0);
    signal y_s        : unsigned(9 downto 0);
    signal engine_out : STD_LOGIC;
    signal pitch_s    : unsigned(7 downto 0) := x"00";
    signal roll_s     : unsigned(7 downto 0) := x"00";
    -- señal para aumentar el roll cada cierto tiempo, prueba
	signal roll_counter : unsigned(27 downto 0) := (others => '0');
	
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
        
   	U3: linear_engine
        port map (
            x      => x_s,
            y      => y_s,
            output => engine_out,
            pitch  => pitch_s,
            roll   => roll_s,
            clk    => clk25_s
        );
	
	-- Process para aumentar roll para probar comportamiento
	process(clk25_s)
    begin
        if rising_edge(clk25_s) then
            roll_counter <= roll_counter + 1;
        end if;
    end process;

    roll_s <= roll_counter(27 downto 20);
    
    
    process(video_on_s, y_s, engine_out)
    begin
        if video_on_s = '1' then
        	-- 200 para display de 400x400 (antes 240)
        	-- pintamos linea blanca para dibujar centro vertical del hotizonte
        	if y_s > display_size / 2 - line_width / 2 and y_s < display_size / 2 + line_width / 2 then
        		vgaRed   <= "1111";
                vgaGreen <= "1111";
                vgaBlue  <= "1111";
            elsif engine_out = '1' then
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




