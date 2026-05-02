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
	-- El linear engine tarda 4 ciclos en calcular el
	-- output, necesitamos 4 ciclos de retraso para 
	-- que la imagen se vea bien en el display
	-- señales sincronizacion
	signal Hsync_internal : std_logic;
    signal Vsync_internal : std_logic;
	signal hsync_delay  : std_logic_vector(3 downto 0);
    signal vsync_delay  : std_logic_vector(3 downto 0);
    signal v_on_delay   : std_logic_vector(3 downto 0);
    signal y_s_delay    : unsigned(39 downto 0);
	
begin

    U1: clk_div_25
        port map (
            clk100 => clk,
            clk25  => clk25_s
        );

	U2: vga_sync
		port map (
			clk25    => clk25_s,
			hsync    => Hsync_internal,
			vsync    => Vsync_internal,
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
    
	process(clk25_s)
    begin
        if rising_edge(clk25_s) then
            hsync_delay <= hsync_delay(2 downto 0) & Hsync_internal;
            vsync_delay <= vsync_delay(2 downto 0) & Vsync_internal;
            v_on_delay  <= v_on_delay(2 downto 0)  & video_on_s;
            y_s_delay   <= y_s_delay(29 downto 0)  & y_s;
        end if;
    end process;
    -- Usar las señales retrasadas
    Hsync <= hsync_delay(3);
    Vsync <= vsync_delay(3);    
    
    process(v_on_delay, y_s_delay, engine_out)
        variable y_actual : unsigned(9 downto 0);
        variable v_on     : std_logic;
    begin
        y_actual := y_s_delay(39 downto 30);
        v_on     := v_on_delay(3);

        if v_on = '1' then
            if y_actual > (display_size / 2 - line_width / 2) and 
               y_actual < (display_size / 2 + line_width / 2) then
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




