-------------------------------------------------------------------------
    -- Lógica de Generación de Color con Horizonte Artificial
    -- Sincronizada con el reloj de 25MHz para mayor estabilidad.
    -------------------------------------------------------------------------
    process(clk25_s)
    begin
        if rising_edge(clk25_s) then
            -- Solo pintamos si estamos en la zona activa de la pantalla
            if video_on_s = '1' then
                
                -- Decidimos el color basándonos en la coordenada vertical Y
                if y_s < 240 then
                    -- MITAD SUPERIOR: Azul Cielo (R=0, G=0, B=15)
                    vgaRed   <= "0000";
                    vgaGreen <= "0110";
                    vgaBlue  <= "1111"; 
                else
                    -- MITAD INFERIOR: Marrón Tierra (R=8, G=4, B=0)
                    -- (puedes ajustar estos valores para cambiar el tono)
                    vgaRed   <= "1001"; 
                    vgaGreen <= "0100";
                    vgaBlue  <= "0000";
                end if;
                
            else
                -- FUERA DE LA ZONA ACTIVA: Negro obligatorio (R=0, G=0, B=0)
                vgaRed   <= "0000";
                vgaGreen <= "0000";
                vgaBlue  <= "0000";
            end if;
        end if;
    end process;

-------------------------------------------------------------------------
    -- Línea blanca del horizonte artificial
   -------------------------------------------------------------------------


process(video_on_s, y_s)
begin
    if video_on_s = '1' then

        if y_s = 240 then
            -- Línea del horizonte
            vgaRed   <= "1111";
            vgaGreen <= "1111";
            vgaBlue  <= "1111";

        elsif y_s < 240 then
            -- Cielo
            vgaRed   <= "0000";
            vgaGreen <= "0110";
            vgaBlue  <= "1111";

        else
            -- Tierra
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



-------------------------------------------------------------------------
    -- Pitch
   -------------------------------------------------------------------------


architecture Structural of top_vga is

    -- ... [Tus componentes clk_div_25 y vga_sync] ...

    signal clk25_s    : STD_LOGIC;
    signal video_on_s : STD_LOGIC;
    signal x_s        : unsigned(9 downto 0);
    signal y_s        : unsigned(9 downto 0);
    
    -- NUEVO: Señal interna para calcular dónde está la línea divisoria
    signal limite_horizonte : integer;

begin

    -- ... [Instancias U1 y U2] ...

    -- Proceso matemático puro: Calculamos la Y del horizonte
    -- Si el compañero te da el pitch de entrada en un puerto: 'pitch_in' (integer)
    -- Asumimos que si pitch_in es positivo (sube morro), la línea baja.
    process(clk25_s)
    begin
        if rising_edge(clk25_s) then
            -- Multiplicamos por 2 para que sea más visual en la pantalla
            -- (En VHDL multiplicar por 2 es trivial para el sintetizador)
            limite_horizonte <= 240 + (pitch_in * 2);
        end if;
    end process;


    -- Proceso de pintado de pantalla
    process(clk25_s)
    begin
        if rising_edge(clk25_s) then
            if video_on_s = '1' then
                
                -- Ahora no comparamos con 240 fijo, sino con el límite dinámico
                if to_integer(y_s) = limite_horizonte then
                    -- Linea blanca
                    vgaRed   <= "1111";
                    vgaGreen <= "1111";
                    vgaBlue  <= "1111";
                elsif to_integer(y_s) < limite_horizonte then
                    -- Cielo (Arriba)
                    vgaRed   <= "0000";
                    vgaGreen <= "0110";
                    vgaBlue  <= "1111";
                else
                    -- Tierra (Abajo)
                    vgaRed   <= "1001";
                    vgaGreen <= "0100";
                    vgaBlue  <= "0000";
                end if;
                
            else
                vgaRed   <= "0000";
                vgaGreen <= "0000";
                vgaBlue  <= "0000";
            end if;
        end if;
    end process;

end Structural;



