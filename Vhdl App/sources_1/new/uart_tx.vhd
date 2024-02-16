----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 11/23/2023 04:15:21 PM
-- Design Name: 
-- Module Name: UART - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity UART_tx is
    generic(n: Integer := 9600);
  Port (TxData : in std_logic_vector(7 downto 0);
        Clk : in std_logic;
        Rst : in std_logic;
        Start : in std_logic;
        Tx : out std_logic;
        TxRdy : out std_logic
   );
end UART_tx;

architecture Behavioral of UART_tx is


constant clock_rate : Integer := 100_000_000;
constant t_bit : Integer :=  clock_rate / n; 
attribute keep : String;
type state is (ready, load, send, waitbit, shift);
signal st : state := ready;
attribute keep of St : signal is "True";

signal CntBit : Integer := 0;
attribute keep of CntBit : signal is "True";
signal CntRate : Integer := 0;
attribute keep of CntRate : signal is "True";
signal LdData : std_logic := '0';
signal ShData : std_logic := '0';
signal TxEn : std_logic := '0';

signal TSR : std_logic_vector(9 downto 0) := (others =>'0');
attribute keep of Tsr : signal is "True";



begin
    proc_tsr1: process(clk, rst)
    begin
        if clk = '1' and clk'event then
            if rst = '1' then 
                TSR <= (others => '0');
            else
                if LdData = '1' then
                    TSR <= '1' & TxData & '0';
                else  
                    if ShData = '1' then
                        TSR <= '0' & TSR(9 downto 1);
                    end if;  
                end if;
            end if;
        end if;
    end process proc_tsr1;
    -- Automat de stare pentru unitatea de control a transmitatorului serial
    proc_control: process (Clk)
    begin
        if RISING_EDGE (Clk) then
            if (Rst = '1') then
            St <= ready;
            else
            case St is
            when ready =>
            CntRate <= 0;
            CntBit <= 0;
            if (Start = '1') then
            St <= load;
            end if;
            when load =>
            St <= send;
            when send =>
            St <= waitbit;
            CntBit <= CntBit + 1;
            when waitbit =>
            CntRate <= CntRate + 1;
            if (CntRate = T_BIT - 3) then
            CntRate <= 0;
            St <= shift;
            end if;
            when shift =>
            if (CntBit = 10) then
            St <= ready;
            else
            St <= send;
            end if;
            when others =>
            St <= ready;
            end case;
            end if;
        end if;
    end process proc_control;
-- Setarea semnalelor de comanda
LdData <= '1' when St = load else '0';
ShData <= '1' when St = shift else '0';
TxEn <= '0' when St = ready or St = load else '1';
-- Setarea semnalelor de iesire
Tx <= TSR(0) when TxEn = '1' else '1';
TxRdy <= '1' when St = ready else '0';  

end Behavioral;