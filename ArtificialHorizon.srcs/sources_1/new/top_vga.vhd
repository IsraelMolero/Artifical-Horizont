library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_vga is
    Port (
        clk25      : in  STD_LOGIC;
        engine_out : in  STD_LOGIC;
        x_out      : out unsigned(9 downto 0);
        y_out      : out unsigned(9 downto 0);
        vgaRed     : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue    : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync      : out STD_LOGIC;
        Vsync      : out STD_LOGIC
    );
end top_vga;

architecture Behavioral of top_vga is
    constant display_size: integer := 400;
    constant line_width: integer := 2;

    -- Señales internas del vga_sync
    signal hsync_s, vsync_s, v_on_s : STD_LOGIC;
    signal x_s, y_s : unsigned(9 downto 0);

    -- Señales de retraso
    signal hsync_delay : std_logic_vector(3 downto 0);
    signal vsync_delay : std_logic_vector(3 downto 0);
    signal v_on_delay  : std_logic_vector(3 downto 0);
    signal y_s_delay   : unsigned(39 downto 0);

begin

    -- Instancia de tu vga_sync original
    U_SYNC: entity work.vga_sync
        port map (
            clk25    => clk25,
            hsync    => hsync_s,
            vsync    => vsync_s,
            video_on => v_on_s,
            x        => x_s,
            y        => y_s
        );

    -- Exponemos las coordenadas hacia el exterior
    x_out <= x_s;
    y_out <= y_s;

    -- Lógica de Retrasos
    process(clk25)
    begin
        if rising_edge(clk25) then
            hsync_delay <= hsync_delay(2 downto 0) & hsync_s;
            vsync_delay <= vsync_delay(2 downto 0) & vsync_s;
            v_on_delay  <= v_on_delay(2 downto 0)  & v_on_s;
            y_s_delay   <= y_s_delay(29 downto 0)  & y_s;
        end if;
    end process;

    -- Lógica de dibujado
    process(v_on_delay, engine_out, y_s_delay)
        variable y_actual : unsigned(9 downto 0);
    begin
        y_actual := y_s_delay(39 downto 30);

        if v_on_delay(3) = '0' then
            -- Fuera de pantalla
            vgaRed <= "0000"; vgaGreen <= "0000"; vgaBlue <= "0000";
        else
            -- Área de dibujo
            if y_actual > (display_size/2 - line_width/2) and y_actual < (display_size/2 + line_width/2) then
                vgaRed <= "1111"; vgaGreen <= "1111"; vgaBlue <= "1111";
            elsif engine_out = '1' then
                vgaRed <= "0000"; vgaGreen <= "0110"; vgaBlue <= "1111";
            else
                vgaRed <= "1001"; vgaGreen <= "0100"; vgaBlue <= "0000";
            end if;
        end if;
    end process;

    -- salidas finales
    Hsync <= hsync_delay(3);
    Vsync <= vsync_delay(3);

end Behavioral;




