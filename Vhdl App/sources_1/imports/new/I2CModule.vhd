----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/04/2023 05:45:08 PM
-- Design Name: 
-- Module Name: I2CModule - Behavioral
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


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity I2CModule is
  GENERIC(
    input_clock : INTEGER := 100_000_000;  -- input clock speed in Hz
    bus_clock   : INTEGER := 400_000);  -- speed for scl
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
end I2CModule;

-- arhitectura I2CModule

architecture Behavioral of I2CModule is

CONSTANT divider : INTEGER := (input_clock/bus_clock)/4;  --number of clocks in 1/4 cycle of scl
-- I2C bus divider devides by 4 because the I2C communication uses a 4-phase clock

TYPE machine IS(ready, start, command, slv_ack1, wr, rd, slv_ack2, mstr_ack, stop); --needed states

SIGNAL state: machine;  --state machine
SIGNAL data_clk: STD_LOGIC;  --data clock for sda
SIGNAL data_clk_prev : STD_LOGIC; --data clock during previous system clock
SIGNAL scl_clk: STD_LOGIC;  --constantly running internal scl
SIGNAL scl_ena: STD_LOGIC := '0'; --enables internal scl to output
SIGNAL sda_int: STD_LOGIC := '1'; --internal sda
SIGNAL sda_ena_n: STD_LOGIC;  --enables internal sda to output
SIGNAL addr_rw: STD_LOGIC_VECTOR(7 DOWNTO 0); --latched in address and read/write
SIGNAL data_tx: STD_LOGIC_VECTOR(7 DOWNTO 0); --latched in data to write to slave
SIGNAL data_rx: STD_LOGIC_VECTOR(7 DOWNTO 0); --data received from slave
SIGNAL bit_cnt: INTEGER RANGE 0 TO 7 := 7; --tracks bit number in transaction
SIGNAL stretch: STD_LOGIC := '0'; --identifies if slave is stretching scl

begin


--generate the timing for the bus clock (scl_clk) and the data clock (data_clk)

PROCESS(clock, reset_n)

    VARIABLE count: INTEGER RANGE 0 TO divider*4; --timing for clock generation
BEGIN

    if(reset_n = '0') then   --reset activated
        stretch <= '0';
        count := 0;
    elsif(clock'EVENT and clock = '1') then
        data_clk_prev <= data_clk; -- we store previous value of data clock
        IF (count = divider*4 - 1)  then   --end of timing cycle
            count:=0; --reset timer
        ELSIF (stretch = '0')  then   --clock stretching from slave not detected
            count := count + 1;   -- continue clock generating timing
        END IF;
        
        case count is
            when 0 TO divider -1 =>   --case for first 1/4 cycle of clocking
                scl_clk <= '0';
                data_clk <= '0';
            when divider to divider*2-1 =>  --case for second 1/4 cycle of clocking
                scl_clk <= '0';
                data_clk <= '1';
            when 2*divider to divider*3-1 => --case for third 1/4 cycle of clocking
                scl_clk <= '1'; -- release scl
                if(scl = '0') then   -- detect if slave is stretching clock
                    stretch <= '1';
                else
                    stretch <= '0';
                end if;
                data_clk <= '1';
            when others =>    -- last 1/4 cycle of clock
                scl_clk <= '1';
                data_clk <= '0';
        end case;
    end if;
end process;


--state machine and writing to sda during scl low (data_clk rising edge)

process(clock, reset_n)
begin
    if(reset_n = '0') then    -- reset activated
        state <= ready;     -- return to initial state
        busy <= '1';      -- indicate not available
        scl_ena <= '0';   --sets scl high impedance
        sda_int <= '1';   -- sets sda high impedance
        ack_error <= '0';  --clear acknowledge error flag
        bit_cnt <= 7;   --restarts data bit counter
        data_rd <= "00000000"; --clear data read port
    elsif(clock'EVENT AND clock = '1') then 
        IF(data_clk = '1' AND data_clk_prev = '0') then  -- suntem pe data_clk rising_edge
            case state is
                when ready =>      -- when in idle state
                    if(ena = '1') then  -- transaction requested
                        busy <= '1';    -- flag busy activated
                        addr_rw <= addr & rw; --collect requested slave address and command
                        data_tx <= data_wr;  --collect requested data to write
                        state <= start;      --go to start bit
                    else
                        busy <= '0';  -- flag busy deactivated
                        state <= ready;  --remain idle
                    end if;
                when start =>                      --start bit of transaction
                   busy <= '1';                     --resume busy if continuous mode
                   sda_int <= addr_rw(bit_cnt);     --set first address bit to bus
                   state <= command;                --go to command
                when command =>                    --address and command byte of transaction
                    if(bit_cnt = 0) then             --command transmit finished
                        sda_int <= '1';                --release sda for slave acknowledge
                        bit_cnt <= 7;                  --reset bit counter for "byte" states
                        state <= slv_ack1;             --go to slave acknowledge (command)
                    else                             --next clock cycle of command state
                        bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
                        sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
                        state <= command;              --continue with command
                    end if;
                when slv_ack1 =>                   --slave acknowledge bit (command)
                   if(addr_rw(0) = '0') then        --write command
                        sda_int <= data_tx(bit_cnt);   --write first bit of data
                        state <= wr;                   --go to write byte
                   else                             --read command
                        sda_int <= '1';                --release sda from incoming data
                        state <= rd;                   --go to read byte
                   end if;
               when wr =>                         --write byte of transaction
                    busy <= '1';                     --resume busy if continuous mode
                    if(bit_cnt = 0) THEN             --write byte transmit finished
                        sda_int <= '1';                --release sda for slave acknowledge
                        bit_cnt <= 7;                  --reset bit counter for "byte" states
                        state <= slv_ack2;             --go to slave acknowledge (write)
                    else                             --next clock cycle of write state
                        bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
                        sda_int <= data_tx(bit_cnt-1); --write next bit to bus
                        state <= wr;                   --continue writing
                    end if;
              when rd =>                         --read byte of transaction
                    busy <= '1';                     --resume busy if continuous mode
                    if(bit_cnt = 0) THEN             --read byte receive finished
                        if(ena = '1' and addr_rw = addr & rw) then  --continuing with another read at same address
                            sda_int <= '0';              --acknowledge the byte has been received
                        else                           --stopping or continuing with a write
                            sda_int <= '1';              --send a no-acknowledge (before stop or repeated start)
                        end if;
                        bit_cnt <= 7;                  --reset bit counter for "byte" states
                        data_rd <= data_rx;            --output received data
                        state <= mstr_ack;             --go to master acknowledge
                    else                             --next clock cycle of read state
                        bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
                        state <= rd;                   --continue reading
                    end if;
              when slv_ack2 =>                   --slave acknowledge bit (write)
                  if(ena = '1') then               --continue transaction
                      busy <= '0';                   --continue is accepted
                      addr_rw <= addr & rw;          --collect requested slave address and command
                      data_tx <= data_wr;            --collect requested data to write
                    if(addr_rw = addr & rw) then   --continue transaction with another write
                        sda_int <= data_wr(bit_cnt); --write first bit of data
                        state <= wr;                 --go to write byte
                    else                           --continue transaction with a read or new slave
                        state <= start;              --go to repeated start
                    end if;
                 else                             --complete transaction
                    state <= stop;                 --go to stop bit
                end if;
            when mstr_ack =>                   --master acknowledge bit after a read
                if(ena = '1') then               --continue transaction
                  busy <= '0';                   --continue is accepted and data received is available on bus
                  addr_rw <= addr & rw;          --collect requested slave address and command
                  data_tx <= data_wr;            --collect requested data to write
                  if(addr_rw = addr & rw) then   --continue transaction with another read
                    sda_int <= '1';              --release sda from incoming data
                    state <= rd;                 --go to read byte
                  else                           --continue transaction with a write or new slave
                    state <= start;              --repeated start
                  end if;    
                else                             --complete transaction
                   state <= stop;                 --go to stop bit
                end if;
            when stop =>                       --stop bit of transaction
                busy <= '0';                     --unflag busy
                state <= ready;                  --go to idle state
            end case;    
        elsif(data_clk = '0' AND data_clk_prev = '1') then  --data clock falling edge
            case state is
                when start =>                  
                    if(scl_ena = '0') then                  --starting new transaction
                        scl_ena <= '1';                       --enable scl output
                        ack_error <= '0';                     --reset acknowledge error output
                    end if;
               when slv_ack1 =>                          --receiving slave acknowledge (command)
                    if(sda /= '0' OR ack_error = '1') then  --no-acknowledge or previous no-acknowledge
                        ack_error <= '1';                     --set error output if no-acknowledge
                    end if;
              when rd =>                                --receiving slave data
                    data_rx(bit_cnt) <= sda;                --receive current slave data bit
              when slv_ack2 =>                          --receiving slave acknowledge (write)
                if(sda /= '0' OR ack_error = '1') then  --no-acknowledge or previous no-acknowledge
                    ack_error <= '1';                     --set error output if no-acknowledge
                end if;
              when stop =>
                scl_ena <= '0';                         --disable scl
             when others =>
                null;
        end case;
      end if;
    end if;
end process;  



--set sda output
with state select
    sda_ena_n <= data_clk_prev when start,     --generate start condition
                 not data_clk_prev when stop,  --generate stop condition
                 sda_int when others;          --set to internal sda signal    
      
  --set scl and sda outputs
  scl <= '0' when (scl_ena = '1' and scl_clk = '0') else 'Z';
  sda <= '0' when sda_ena_n = '0' else 'Z';


end Behavioral;
