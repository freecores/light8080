--##############################################################################
-- RS-232 transmitter, hardwired to 9600 bauds when clocked at 50MHz.
-- WARNING: Hacked up for light8080 demo. Poor performance, no formal testing!
-- I don't advise using this for any purpose.
--##############################################################################


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity rs232_tx is
	port (	clk 		: in std_logic;
         	reset 	: in std_logic;
         	rdy 		: out std_logic;
          load 		: in std_logic;
          data_i 	: in std_logic_vector(7 downto 0);
          txd 		: out std_logic);
end rs232_tx;

architecture demo of rs232_tx is

signal counter : integer;

signal data :         std_logic_vector(10 downto 0);
signal ctr_bit :      std_logic_vector(3 downto 0);
signal tx :           std_logic;

begin


process(clk)
begin
if clk'event and clk='1' then
  
  if reset='1' then
    data <= "10111111111";
    tx <= '0';
    ctr_bit <= "0000";
    counter <= 0;
  elsif load='1' and tx='0' then
    data <= "1"&data_i&"01";
    tx <= '1';
  else
    if tx='1' then
      if counter = 5200 then
        counter <= 0;
        data(9 downto 0) <= data(10 downto 1);
        data(10) <= '1';
        if ctr_bit = "1010" then
           tx <= '0';
           ctr_bit <= "0000";
        else
           ctr_bit <= ctr_bit + 1;
        end if;
      else
        counter <= counter + 1;
      end if;
    end if;
  end if;
end if;
end process;

rdy <= not tx;
txd <= data(0);

end demo;