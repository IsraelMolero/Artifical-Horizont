library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity adc is
    port ( 
        clk     : in  STD_LOGIC;
        vauxp6  : in  STD_LOGIC;
        vauxn6  : in  STD_LOGIC; 
        adc_out : out STD_LOGIC_VECTOR (11 downto 0)
    );
end adc;

architecture behavioral of adc is
    component xadc_wiz_0
        port (
            daddr_in    : in  STD_LOGIC_VECTOR (6 downto 0);
            dclk_in     : in  STD_LOGIC;
            den_in      : in  STD_LOGIC;
            di_in       : in  STD_LOGIC_VECTOR (15 downto 0);
            dwe_in      : in  STD_LOGIC;
            vauxp6      : in  STD_LOGIC;
            vauxn6      : in  STD_LOGIC;
            busy_out    : out STD_LOGIC;
            channel_out : out STD_LOGIC_VECTOR (4 downto 0);
            do_out      : out STD_LOGIC_VECTOR (15 downto 0);
            drdy_out    : out STD_LOGIC;
            eoc_out     : out STD_LOGIC;
            eos_out     : out STD_LOGIC;
            alarm_out   : out STD_LOGIC;
            vp_in       : in  STD_LOGIC;
            vn_in       : in  STD_LOGIC
        );
    end component;

    signal adc_data_raw : std_logic_vector(15 downto 0);
    signal eoc_signal   : std_logic;
    signal drdy_signal  : std_logic;
    
begin

    U1 : xadc_wiz_0
        port map (
            daddr_in    => "0010110", 
            dclk_in     => clk,
            den_in      => eoc_signal,
            di_in       => (others => '0'),
            dwe_in      => '0',
            vauxp6      => vauxp6,
            vauxn6      => vauxn6,
            busy_out    => open,
            channel_out => open,
            do_out      => adc_data_raw,
            drdy_out    => drdy_signal,
            eoc_out     => eoc_signal,
            eos_out     => open,
            alarm_out   => open,
            vp_in       => '0',
            vn_in       => '0'
        );

    process(clk)
    begin
        if rising_edge(clk) then
            if drdy_signal = '1' then
                adc_out <= adc_data_raw(15 downto 4);
            end if;
        end if;
    end process;

end behavioral;