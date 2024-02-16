library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity SSD is
    Port ( clk: in STD_LOGIC;
           digits: in STD_LOGIC_VECTOR(31 downto 0);
           an: out STD_LOGIC_VECTOR(7 downto 0);
           cat: out STD_LOGIC_VECTOR(7 downto 0));
end SSD;

architecture Behavioral of SSD is

signal digit : STD_LOGIC_VECTOR (3 downto 0);
signal cnt : STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
signal sel : STD_LOGIC_VECTOR(2 downto 0);

begin

    counter: process (clk) 
    begin
        if rising_edge(clk) then
            cnt <= cnt + 1;
        end if;
    end process;

    sel <= cnt(15 downto 13);

    muxCat : process (sel, digits)
    begin
        case sel is
           when "000" => digit <= digits(3 downto 0);
           when "001" => digit <= digits(7 downto 4);
           when "010" => digit <= digits(11 downto 8);
           when "011" => digit <= digits(15 downto 12);
           when "100" => digit <= digits(19 downto 16);
           when "101" => digit <= digits(23 downto 20);
           when "110" => digit <= digits(27 downto 24);
           when "111" => digit <= digits(31 downto 28);
           when others => digit <= (others => '0');
        end case;
    end process;

    muxAn : process (sel)
    begin
        case sel is
            when "000" => an <= "11111110";
            when "001" => an <= "11111101";
            when "010" => an <= "11111011";
            when "011" => an <= "11110111";
            when "100" => an <= "11101111";
            when "101" => an <= "11011111";
            when "110" => an <= "10111111";
            when "111" => an <= "01111111";
            when others => an <= (others => '0');
        end case;
    end process;
    
    digitsSel : process(sel, digit)
    begin
        case sel is
            when "000" => cat <= "11000110";
            when "001" => cat <= "10011100";
            when "100" =>
                case digit is
                    when "0000" => cat <= "01000000";
                    when "0001" => cat <= "01111001";
                    when "0010" => cat <= "00100100";
                    when "0011" => cat <= "00110000";
                    when "0100" => cat <= "00011001";
                    when "0101" => cat <= "00010010";
                    when "0110" => cat <= "00000010";
                    when "0111" => cat <= "01111000";
                    when "1000" => cat <= "00000000";
                    when "1001" => cat <= "00010000";
                    when "1010" => cat <= "00001000";
                    when "1011" => cat <= "00000011";
                    when "1100" => cat <= "01000110";
                    when "1101" => cat <= "00100001";
                    when "1110" => cat <= "00000110";
                    when "1111" => cat <= "00001110";
                    when others => cat <= (others => '0');
                end case;
            when others =>
                case digit is
                    when "0000" => cat <= "11000000";
                    when "0001" => cat <= "11111001";
                    when "0010" => cat <= "10100100";
                    when "0011" => cat <= "10110000";
                    when "0100" => cat <= "10011001";
                    when "0101" => cat <= "10010010";
                    when "0110" => cat <= "10000010";
                    when "0111" => cat <= "11111000";
                    when "1000" => cat <= "10000000";
                    when "1001" => cat <= "10010000";
                    when "1010" => cat <= "10001000";
                    when "1011" => cat <= "10000011";
                    when "1100" => cat <= "11000110";
                    when "1101" => cat <= "10100001";
                    when "1110" => cat <= "10000110";
                    when "1111" => cat <= "10001110";
                    when others => cat <= (others => '0');
                end case;
        end case;
    end process;

end Behavioral;