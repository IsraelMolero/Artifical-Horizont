library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lut_sin_cos is
    port (
    	-- Para poder usar BRAM necesitamos que sea sincrono
        clk   : in  std_logic;
        -- Entrada de valor de 8 bits, incrementos de 1.4 grados (tendremos que ver como convertir)
        angle : in  unsigned(7 downto 0);
        -- Devolvemos valores de 16 bits con signo
        sin : 	out signed(15 downto 0);
        cos : 	out signed(15 downto 0)
    );
end entity;

architecture rtl of lut_sin_cos is
    type rom_type is array (0 to 63) of signed(15 downto 0);
    
    -- generado con el script de python
    constant SIN_TABLE : rom_type := (
        x"0000", x"0006", x"000d", x"0013", x"0019", x"001f", x"0026", x"002c",
		x"0032", x"0038", x"003e", x"0044", x"004a", x"0050", x"0056", x"005c",
		x"0062", x"0068", x"006d", x"0073", x"0079", x"007e", x"0084", x"0089",
		x"008e", x"0093", x"0098", x"009d", x"00a2", x"00a7", x"00ac", x"00b1",
		x"00b5", x"00b9", x"00be", x"00c2", x"00c6", x"00ca", x"00ce", x"00d1",
		x"00d5", x"00d8", x"00dc", x"00df", x"00e2", x"00e5", x"00e7", x"00ea",
		x"00ed", x"00ef", x"00f1", x"00f3", x"00f5", x"00f7", x"00f8", x"00fa",
		x"00fb", x"00fc", x"00fd", x"00fe", x"00ff", x"00ff", x"0100", x"0100"
        
    );

    signal angle_cos    : unsigned(7 downto 0);
    signal addr_sin     : integer range 0 to 63;
    signal addr_cos     : integer range 0 to 63;
    signal quad_sin     : unsigned(1 downto 0);
    signal quad_cos     : unsigned(1 downto 0);
    signal raw_sin      : signed(15 downto 0);
    signal raw_cos      : signed(15 downto 0);

begin
	-- al tener escala de 8 bits 64 son 90 grados
    angle_cos <= angle + 64;

	-- Cuadrantes
    quad_sin <= angle(7 downto 6);
    quad_cos <= angle_cos(7 downto 6);

	-- Direcciones de los valores en la lut
    addr_sin <= to_integer(angle(5 downto 0)) when quad_sin(0) = '0' else
                63 - to_integer(angle(5 downto 0));

    addr_cos <= to_integer(angle_cos(5 downto 0)) when quad_cos(0) = '0' else
                63 - to_integer(angle_cos(5 downto 0));

    process(clk)
    begin
        if rising_edge(clk) then
            raw_sin <= SIN_TABLE(addr_sin);
            raw_cos <= SIN_TABLE(addr_cos);

            if quad_sin(1) = '1' then
                sin <= -raw_sin;
            else
                sin <= raw_sin;
            end if;

            if quad_cos(1) = '1' then
                cos <= -raw_cos;
            else
                cos <= raw_cos;
            end if;
        end if;
    end process;
end architecture;
