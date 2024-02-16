library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity top_module is
    Port (
        clk: in std_logic;                     -- Clock signal
        rst: in std_logic;                     -- Reset signal
        rst_uart: in std_logic;
        --send : in std_logic;
        scl: inout std_logic;                  -- I2C Clock line
        sda: inout std_logic;                  -- I2C Data line
        an: out std_logic_vector(7 downto 0);  -- SSD anodes
        cat: out std_logic_vector(7 downto 0); -- SSD cathodes
        tx: out std_logic;
        txRdy: out std_logic
    );
end top_module;

architecture Behavioral of top_module is
    signal i2c_ack_err : std_logic;
    signal temperature : std_logic_vector (15 downto 0);
    

    signal txData : std_logic_vector(15 downto 0);
    signal txAux : std_logic := '1';
    signal txRdyAux : std_logic := '0';
    
    signal tempInDec : integer range 0 to 9999;
    signal digit1, digit2, digit3, digit4 : std_logic_vector(3 downto 0);
    signal ascii1, ascii2, ascii3, ascii4 : std_logic_vector(7 downto 0);
    
     signal ascii_out : std_logic_vector (39 downto 0);
     signal allDigits :std_logic_vector(31 downto 0) ;

    -- instantiere componenta temp_senzor
    component temp_senzor is
        generic( sys_clk_freq : integer := 100_000_000;
                 sensor_addr : std_logic_vector(6 downto 0) := "1001011");
        port( clk : in std_logic;
              rst : in std_logic;
              scl : inout std_logic;
              sda : inout std_logic;
              i2c_ack_err : out std_logic;
              temperature : out std_logic_vector (15 downto 0));
    end component;

    -- instantiere componenta ssd
    component SSD is
        Port ( clk: in std_logic;
               digits: in std_logic_vector(31 downto 0);
               an: out std_logic_vector(7 downto 0);
               cat: out std_logic_vector(7 downto 0));
    end component;

    --instantiere componenta de conversie dec to ascii
    component ConvertorDecAsc is
        Port (
            decDigit: in std_logic_vector(3 downto 0);
            asciiValue: out std_logic_vector(7 downto 0)
        );
    end component;

begin
    -- mapare a componentei temp_senzor
    temp_sensor_inst: temp_senzor
        generic map (
            sys_clk_freq => 100_000_000,
            sensor_addr => "1001011"
        )
        port map (
            clk => clk,
            rst => rst,
            scl => scl,
            sda => sda,
            i2c_ack_err => i2c_ack_err,
            temperature => temperature
        );
        
    -- mapare a componentei ssd
    ssd_display_inst: SSD
        port map (
            clk => clk,
            digits => allDigits,
            an => an,
            cat => cat
        );
        
        -- proces pentru a schimba temperatura dintr-o valoare salvata pe 16 biti intr-o valoare de tip int
        process(temperature)
        begin
            tempInDec <= conv_integer(temperature);
        end process;
    
        --impartim temperatura pe cifre si le stocam valoarea in vectori diferiti
        digit1 <= std_logic_vector(to_unsigned(tempInDec mod 10, 4));
        digit2 <= std_logic_vector(to_unsigned((tempInDec / 10) mod 10, 4));
        digit3 <= std_logic_vector(to_unsigned((tempInDec / 100) mod 10, 4));
        digit4 <= std_logic_vector(to_unsigned((tempInDec / 1000) mod 10, 4));
        
        allDigits(23 downto 8) <= digit4 & digit3 & digit2 & digit1; -- concatenam fiecare vector de cifre pentru a trimite la ssd valoarea corecta, de la 23 la 8 pentru ca cei de la 7 la 0 sun ocupati cu ^C
        
    
        -- convertim fiecare cifra la un cod ascii pe 8 biti
        D2A1: ConvertorDecAsc port map (digit1, ascii1);
        D2A2: ConvertorDecAsc port map (digit2, ascii2);
        D2A3: ConvertorDecAsc port map (digit3, ascii3);
        D2A4: ConvertorDecAsc port map (digit4, ascii4);
    
        -- concatenam valorile ascii pe 8 biti intr-una singra pentru a o trimite la uart
        ascii_out <= ascii4 & ascii3 & x"2E" & ascii2 & ascii1;
        
    uart16: entity work.UART_16 port map(Clk => clk, Rst => rst_uart, data1 => ascii_out , Tx => tx, TxRdy => txRdy);

end Behavioral;
