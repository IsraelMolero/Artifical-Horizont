library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
    Port (
        -- Debug LEDs
    	led      : out STD_LOGIC_VECTOR(15 downto 0);
    	-- reloj del sistema
        clk      : in  STD_LOGIC;
        -- VGA
        vgaRed   : out STD_LOGIC_VECTOR(3 downto 0);
        vgaGreen : out STD_LOGIC_VECTOR(3 downto 0);
        vgaBlue  : out STD_LOGIC_VECTOR(3 downto 0);
        Hsync    : out STD_LOGIC;
        Vsync    : out STD_LOGIC;
        -- 7 segmentos
        seg      : out STD_LOGIC_VECTOR(6 downto 0);
        an       : out STD_LOGIC_VECTOR(3 downto 0);
        -- i2c
        scl      : inout STD_LOGIC;
        sda      : inout STD_LOGIC
    );
end top;

architecture Structural of top is

    signal clk25_s    : STD_LOGIC;
    signal x_s, y_s   : unsigned(9 downto 0);
    signal engine_out : STD_LOGIC;

    -- pitch y roll
    signal pitch_s    : unsigned(7 downto 0) := x"00";
    signal roll_s     : unsigned(7 downto 0) := x"00";

    -- Señales del sensor BMI160
    -- Salidas de aceleracion en los tres ejes (16 bits complemento a 2)
    signal accel_x_s       : std_logic_vector(15 downto 0);
    signal accel_y_s       : std_logic_vector(15 downto 0);
    signal accel_z_s       : std_logic_vector(15 downto 0);

    -- Indica cuando hay datos nuevos disponibles del sensor
    signal data_ready_s    : std_logic;

    -- Pulso para iniciar una lectura del sensor
    signal start_read_s    : std_logic;

    -- Valor a mostrar en el display de 7 segmentos
    signal display_value_s : unsigned(13 downto 0);

    -- Contador para generar pulsos periodicos de lectura del sensor
    -- Con 24 bits a 100MHz genera un pulso cada ~168ms
    signal read_counter    : unsigned(23 downto 0) := (others => '0');

    -- Señal auxiliar para ver si la inicializacion completo
	signal init_done_s : std_logic;

	-- Señal de debug del estado de la maquina
	signal state_debug_s : std_logic_vector(3 downto 0);


begin

    -- Divisor de Reloj
    U_CLK: entity work.clk_div_25
        port map (
            clk100 => clk,
            clk25  => clk25_s
        );

   -- Lectura del BMI160: usamos un unico controlador I2C para evitar
   -- multiples drivers sobre accel_x/accel_y y sobre las lineas SCL/SDA.
    pitch_s <= unsigned(accel_x_s(15 downto 8));
    roll_s  <= unsigned(accel_y_s(15 downto 8));



    -- Controlador VGA
    U_VGA_CTRL: entity work.top_vga
        port map (
            clk25      => clk25_s,
            engine_out => engine_out,
            x_out      => x_s,
            y_out      => y_s,
            vgaRed     => vgaRed,
            vgaGreen   => vgaGreen,
            vgaBlue    => vgaBlue,
            Hsync      => Hsync,
            Vsync      => Vsync
        );

    -- Motor Lógico
    U_ENGINE: entity work.linear_engine
        port map (
            clk    => clk25_s,
            x      => x_s,
            y      => y_s,
            pitch  => pitch_s,
            roll   => roll_s,
            output => engine_out
        );

     U_BMI160: entity work.i2c_controller
        generic map (
            FREQ_G     => 100.0,
            I2C_FREQ_G => 0.4
        )
        port map (
            clk_i        => clk,
            rst_i        => '0',
            start_read_i => start_read_s,
            accel_x_o    => accel_x_s,
            accel_y_o    => accel_y_s,
            accel_z_o    => accel_z_s,
            data_ready_o => data_ready_s,
            scl_io       => scl,
            sda_io       => sda,
            -- Conexion de la señal de debug de inicializacion
        	init_done_o  => init_done_s,
        	-- Conexion de debug del estado
			state_debug_o => state_debug_s
        );


        -- Debug: mostrar estado de inicializacion y lectura en los LEDs
		-- LED(15): init_done (deberia encenderse despues de ~4ms)
		-- LED(14): data_ready (deberia parpadear cada lectura)
		-- LED(13): start_read (deberia parpadear con read_counter)
		-- LED(12:9): estado de la maquina de estados (para debug avanzado)
		-- LED(8:0): primeros 9 bits del dato X
		led(15) <= '1' when init_done_s = '1' else '0';
		led(14) <= data_ready_s;
		led(13) <= start_read_s;
		-- Mostrar el estado de la maquina en los LEDs 12-9
		led(12 downto 9) <= state_debug_s;
		led(8 downto 0) <= accel_x_s(8 downto 0);

		-- Proceso de generacion de pulsos de lectura periodicos
		-- Incrementa el contador continuamente
		-- Cuando el contador vuelve a 0, genera un pulso de un ciclo en start_read_s
		process(clk)
		begin
			if rising_edge(clk) then
				read_counter <= read_counter + 1;

				if read_counter = 0 then
					start_read_s <= '1';
				else
					start_read_s <= '0';
				end if;
			end if;
		end process;

    -- Display 7 Segmentos
    display_value_s <= unsigned(accel_x_s(13 downto 0));
    U_7SEG: entity work.seven_segment_display
        port map (
            clk   => clk,
            value => display_value_s,
            seg   => seg,
            an    => an
        );

end Structural;
