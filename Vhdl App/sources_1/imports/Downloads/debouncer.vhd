----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 10/01/2019 10:50:04 AM
-- Design Name: 
-- Module Name: debouncer - Behavioral
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

entity debouncer is
    Port ( Clk : in STD_LOGIC;
           D_in : in STD_LOGIC;
           Q_out : out STD_LOGIC);
end debouncer;

architecture Behavioral of debouncer is

signal Q1, Q2, Q3 : std_logic;

begin


--  Provides a one-shot pulse from a non-clock input, with reset
--**Insert the following between the 'architecture' and
---'begin' keywords**


--**Insert the following after the 'begin' keyword**
process(Clk)
begin
   if (Clk'event and Clk = '1') then
         Q1 <= D_IN;
         Q2 <= Q1;
         Q3 <= Q2;
   end if;
end process;

Q_OUT <= Q1 and Q2 and (not Q3);


				
				

end Behavioral;
