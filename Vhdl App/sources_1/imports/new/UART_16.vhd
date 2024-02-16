----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 12/07/2023 04:46:00 PM
-- Design Name: 
-- Module Name: UART16 - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_16 is
  Port (Clk : in std_logic;
        Rst : in std_logic;
        --Send : in std_logic;
        data1 : in std_logic_vector (39 downto 0);
        Tx : out std_logic;
        TxRdy : out std_logic
   );
end UART_16;

architecture Behavioral of UART_16 is
signal temp : std_logic_vector(7 downto 0) := x"00";
signal temp_txRdy : std_logic := '0';
signal temp_tx : std_logic := '0';
signal start_temp : std_logic := '0';
type State is (init, trimit, stop);
signal stare : State := init;
signal nr_octeti : Integer;

signal send_filtrat : std_logic := '0';
signal rst_filtrat : std_logic := '0';
signal rst_aux : std_logic := '0';

begin
    temp <= data1(39 downto 32) when nr_octeti = 7 else
            data1(31 downto 24) when nr_octeti = 6 else
            data1(23 downto 16) when nr_octeti = 5 else
            data1(15 downto 8) when nr_octeti = 4 else
            data1(7 downto 0) when nr_octeti = 3 else
            x"0D" when nr_octeti = 2 else
            x"0A" when nr_octeti = 1 else
            x"00";


    UartX: entity Work.UART_tx port map(temp,
                                     clk,
                                     rst_filtrat,
                                     start_temp,
                                     tx,
                                     temp_txRdy  
                                        );
    FSM : process(clk)
          begin
            if rst = '1' then
                stare <= init;
            else
                if clk = '1' and clk'event then
                    case stare is
                        when init =>  
                            nr_octeti <= 9;  
                            start_temp <= '0'; 
                            stare <= trimit;
                        when trimit => 
                            start_temp <= '1';
                            if temp_txRdy = '1' then
                            nr_octeti <= nr_octeti - 1;
                            end if;
                            if nr_octeti > 0 then
                                stare <= trimit;
                            else
                                stare <= stop;
                            end if;
                        when stop => stare <= init;
                           
                    end case;   
                end if;
            end if;
          end process;
            

   MPG2 : entity Work.debouncer port map (clk, rst, rst_filtrat);
   
   
end Behavioral;
