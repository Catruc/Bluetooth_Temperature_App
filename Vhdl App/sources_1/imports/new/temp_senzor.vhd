----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2023 03:30:14 PM
-- Design Name: 
-- Module Name: temp_senzor - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity temp_senzor is
    generic( sys_clk_freq : integer := 100_000_000;  -- clock speed in Hertz -- 50 MHz valoare implicita
             sensor_addr : std_logic_vector(6 downto 0) :=  "1001011" ); -- adreasa i2c a senzorului -- valoare implicita
    port( clk : in std_logic; -- semnal de clock
          rst : in std_logic; -- semnal de reset
          scl : inout std_logic; --
          sda : inout std_logic;
          i2c_ack_err : out std_logic;
          temperature : out std_logic_vector (15 downto 0));
end temp_senzor;

architecture Behavioral of temp_senzor is

type machine is (start, init, pause, readData, outputRes);
signal state : machine;
signal i2c_en : std_logic;
signal i2c_adr : std_logic_vector(6 downto 0);
signal i2c_rw : std_logic;
signal i2c_dataWr : std_logic_vector(7 downto 0);
signal i2c_dataRd : std_logic_vector(7 downto 0);
signal i2c_busy : std_logic;
signal busy_prev : std_logic;
signal buff_temp : std_logic_vector(15 downto 0);
signal output_signal : std_logic;
signal an : std_logic_vector (3 downto 0);
signal cat : std_logic_vector ( 6 downto 0);

component I2CModule is
  Generic(
    input_clock : INTEGER;  -- input clock speed in Hz
    bus_clock   : INTEGER);  -- speed for scl
  Port (clock : in std_logic;  --system clock
        reset_n : in std_logic; --active low reset
        ena : in std_logic; --latch in command
        addr : in std_logic_vector(6 downto 0); -- address of target slave
        rw: in std_logic;  -- signal whose value is '0' when write and '1' when read
        data_wr: in std_logic_vector(7 downto 0); -- data to write to slave
        busy: out std_logic; -- indicates transaction in progress
        data_rd: out std_logic_vector(7 downto 0); --data read from slave
        ack_error: BUFFER std_logic; --flag if improper acknowledge from slave
        sda: inout std_logic; --serial data output of i2c bus
        scl : inout std_logic -- serial clock output of i2c bus
        );
end component;

component SSD is
    Port ( clk: in STD_LOGIC;
           digits: in STD_LOGIC_VECTOR(15 downto 0);
           an: out STD_LOGIC_VECTOR(3 downto 0);
           cat: out STD_LOGIC_VECTOR(6 downto 0));
end component;

begin

i2c_master: I2CModule generic map ( input_clock => sys_clk_freq, bus_clock => 400_000)
                      port map ( clock => clk, reset_n => rst, ena => i2c_en, addr => i2c_adr, rw => i2c_rw, data_wr => i2c_dataWr, busy => i2c_busy, data_rd => i2c_dataRd, ack_error => i2c_ack_err, sda => sda, scl => scl);


process(clk, rst)

variable busyCount : integer range 0 to 3 := 0;
variable counter : integer range 0 to sys_clk_freq/10 := 0;

begin

    if rst = '0' then
        counter := 0;
        i2c_en <= '0';
        busyCount := 0;
        temperature <= (OTHERS => '0');
        state <= start;
    elsif rising_edge(clk) then
        case state is
            when start => if (counter < sys_clk_freq/10) then 
                            counter := counter + 1;
                          else 
                            counter := 0;
                            state <= init;
                          end if;
            when init => busy_prev <= i2c_busy;
                         if (busy_prev = '0' and i2c_busy = '1') then
                            busyCount := busyCount + 1;
                         end if;
                         case busyCount is
                            when 0 =>
                                i2c_en <= '1';
                                i2c_adr <= sensor_addr;
                                i2c_rw <= '0';
                                i2c_dataWr <= "00000011";
                            when 1 =>
                                i2c_dataWr <= "10000000";
                            when 2 =>
                                i2c_en <= '0';
                                if i2c_busy = '0' then
                                    busyCount := 0;
                                    state <= pause;
                                end if;
                            when others => NULL;
                          end case;
                  when pause => if (counter < sys_clk_freq/769_000) then
                                    counter := counter + 1;
                                else
                                    counter := 0;
                                    state <= readData;
                                end if;
                  when readData => busy_prev <= i2c_busy;
                                   if(busy_prev = '0' and i2c_busy = '1') then
                                        busyCount := busyCount + 1; 
                                   end if;
                                   case busyCount is
                                      when 0 =>
                                        i2c_en <= '1';
                                        i2c_adr <= sensor_addr;
                                        i2c_rw <= '0';
                                        i2c_dataWr <= "00000000";
                                      when 1 => 
                                        i2c_rw <= '1';
                                      when 2 =>
                                        if(i2c_busy = '0') then
                                            buff_temp(15 downto 8) <= i2c_dataRd;
                                        end if;
                                      when 3 =>
                                        i2c_en <= '0';
                                        if(i2c_busy = '0') then
                                            buff_temp(7 downto 0) <= i2c_dataRd;
                                            busyCount := 0;
                                            state <= outputRes;
                                        end if;
                                       when others => NULL;
                                      end case;
                     when outputRes => temperature <= buff_temp(15 downto 0);
                                       state <= pause;
                     when others => state <= start;
         end case;
      end if;
end process;


end Behavioral;
