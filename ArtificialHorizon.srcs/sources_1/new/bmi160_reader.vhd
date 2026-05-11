library IEEE, XESS;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use XESS.CommonPckg.all;
use XESS.I2cPckg.all;

entity bmi160_reader is
    generic(
        FREQ_G : real := 100.0;
        I2C_FREQ_G : real := 0.4
    );
    port(
        clk_i : in std_logic;
        rst_i : in std_logic;
        start_read_i : in std_logic;
        accel_x_o : out std_logic_vector(15 downto 0);
        accel_y_o : out std_logic_vector(15 downto 0);
        accel_z_o : out std_logic_vector(15 downto 0);
        data_ready_o : out std_logic;
        scl_io : inout std_logic;
        sda_io : inout std_logic
    );
end entity;

architecture rtl of bmi160_reader is
    constant BMI160_ADDR : std_logic_vector(7 downto 0) := "11010000";
    constant ACCEL_X_LSB : std_logic_vector(7 downto 0) := x"12";
    
    type state_t is (IDLE, SEND_ADDR, SEND_REG, RESTART, 
                     READ_ADDR, READ_DATA, PROCESS_DATA, DONE);
    signal state : state_t;
    
    signal i2c_addr : std_logic_vector(2 downto 0);
    signal i2c_data_in : std_logic_vector(7 downto 0);
    signal i2c_data_out : std_logic_vector(7 downto 0);
    signal i2c_wr : std_logic;
    signal i2c_rd : std_logic;
    signal i2c_done : std_logic;
    
    signal byte_count : unsigned(2 downto 0);
    signal accel_data : std_logic_vector(47 downto 0);
    
begin
    i2c_inst : I2c
        generic map(
            FREQ_G => FREQ_G,
            I2C_FREQ_G => I2C_FREQ_G
        )
        port map(
            clk_i => clk_i,
            rst_i => rst_i,
            addr_i => i2c_addr,
            data_i => i2c_data_in,
            data_o => i2c_data_out,
            wr_i => i2c_wr,
            rd_i => i2c_rd,
            done_o => i2c_done,
            scl_io => scl_io,
            sda_io => sda_io
        );
    
    process(clk_i)
    begin
        if rising_edge(clk_i) then
            if rst_i = '1' then
                state <= IDLE;
                i2c_wr <= '0';
                i2c_rd <= '0';
                data_ready_o <= '0';
                byte_count <= (others => '0');
            else
                i2c_wr <= '0';
                i2c_rd <= '0';
                data_ready_o <= '0';
                
                case state is
                    when IDLE =>
                        if start_read_i = '1' then
                            state <= SEND_ADDR;
                            byte_count <= (others => '0');
                        end if;
                    
                    when SEND_ADDR =>
                        i2c_addr <= "011";
                        i2c_data_in <= BMI160_ADDR;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= SEND_REG;
                        end if;
                    
                    when SEND_REG =>
                        i2c_addr <= "100";
                        i2c_data_in <= ACCEL_X_LSB;
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= RESTART;
                        end if;
                    
                    when RESTART =>
                        i2c_addr <= "100";
                        i2c_data_in <= BMI160_ADDR or x"01";
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            state <= READ_DATA;
                        end if;
                    
                    when READ_DATA =>
                        i2c_addr <= "100";
                        i2c_data_in <= x"00";
                        i2c_wr <= '1';
                        if i2c_done = '1' then
                            accel_data(to_integer(byte_count)*8 + 7 downto 
                                      to_integer(byte_count)*8) <= i2c_data_out;
                            if byte_count = 5 then
                                state <= PROCESS_DATA;
                            else
                                byte_count <= byte_count + 1;
                            end if;
                        end if;
                    
                    when PROCESS_DATA =>
                        accel_x_o <= accel_data(15 downto 0);
                        accel_y_o <= accel_data(31 downto 16);
                        accel_z_o <= accel_data(47 downto 32);
                        state <= DONE;
                    
                    when DONE =>
                        data_ready_o <= '1';
                        state <= IDLE;
                end case;
            end if;
        end if;
    end process;
    
end architecture;