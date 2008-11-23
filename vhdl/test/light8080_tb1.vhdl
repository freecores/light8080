--------------------------------------------------------------------------------
-- Light8080 simulation test bench 1 : Interrupt response test
--------------------------------------------------------------------------------
-- Source for the 8080 program is in asm\tb1.asm
-- Upon completion, a value of 033h in ACC means success and a 0aah means
-- failure, but the proper behavior of intr/inta/halt has to be verified
-- visually.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY light8080_tb1 IS
END light8080_tb1;

ARCHITECTURE behavior OF light8080_tb1 IS 

--------------------------------------------------------------------------------
-- Simulation parameters

-- T: simulation clock period
constant T : time := 100 ns;

-- sim_length: total simulation time
constant sim_length : time := 45000 ns;


--------------------------------------------------------------------------------

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT light8080
    PORT (  
            addr_out :  out std_logic_vector(15 downto 0);

            inta :      out std_logic;
            inte :      out std_logic;
            halt :      out std_logic;                
            intr :      in std_logic;
              
            vma :       out std_logic;
            io :        out std_logic;
            rd :        out std_logic;
            wr :        out std_logic;
            data_in :   in std_logic_vector(7 downto 0);  
            data_out :  out std_logic_vector(7 downto 0);

            clk :       in std_logic;
            reset :     in std_logic );
	END COMPONENT;


SIGNAL data_i :  std_logic_vector(7 downto 0) := (others=>'0');

SIGNAL vma_o  :  std_logic;
SIGNAL rd_o  :  std_logic;
SIGNAL wr_o  :  std_logic;
SIGNAL io_o  :  std_logic;
SIGNAL data_o :  std_logic_vector(7 downto 0);
SIGNAL data_mem :  std_logic_vector(7 downto 0);
SIGNAL addr_o :  std_logic_vector(15 downto 0);

signal inta_o : std_logic;
signal inte_o : std_logic;
signal intr_i : std_logic := '0';
signal halt_o : std_logic;

signal reset    : std_logic := '0';
signal clk      : std_logic := '1';
signal done     : std_logic := '0';

type t_rom is array(0 to 2047) of std_logic_vector(7 downto 0);

signal rom : t_rom := (

X"c3",X"40",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"c6",X"07",X"fb",X"c9",X"00",X"00",X"00",X"00",
X"47",X"c9",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"31",X"06",X"02",X"fb",X"3e",X"00",X"ef",X"c6",
X"01",X"c6",X"01",X"c6",X"01",X"c6",X"01",X"c6",
X"01",X"c6",X"01",X"c6",X"01",X"fb",X"c6",X"01",
X"c6",X"01",X"c6",X"01",X"fb",X"76",X"fe",X"11",
X"c2",X"7b",X"00",X"78",X"fe",X"00",X"c2",X"7b",
X"00",X"79",X"fe",X"0c",X"c2",X"7b",X"00",X"7a",
X"fe",X"12",X"7b",X"fe",X"34",X"c2",X"7b",X"00",
X"3e",X"33",X"76",X"3e",X"aa",X"76",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"c6",X"09",X"06",X"77",X"fb",X"c9",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00"

);


type t_int_vectors is array(0 to 15) of std_logic_vector(7 downto 0);

-- This ROM holds the int vectors that will be fed to the CPU along the test. 
-- It will be read like a progrm ROM except a special pointer (vector_counter) 
-- will be used instead of the PC (see below).
-- Of course this is a simulation trick not meant to be synthesized.
signal int_vectors : t_int_vectors := (
  X"00",                -- not used (see below)
  X"e7",                -- rst 4 (rst 20h)
  X"4f",                -- mov c,a 
  X"11", X"34", X"12",  -- lxi d, 1234h
  X"00",                -- nop
  X"00",                -- not used
  X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00"
);

-- This will be used to read the irq vector ROM. It's a pointer that increments 
-- whenever the CPU fetches a byte while inta_o is high.
signal vector_counter : integer := 0;
-- Vector byte to be fed to the CPU in inta cycles
signal int_vector : std_logic_vector(7 downto 0);

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: light8080 PORT MAP(
		clk => clk,
		reset => reset,
		vma => vma_o,
		rd => rd_o,
		wr => wr_o,
		io => io_o,
		addr_out => addr_o, 
		data_in => data_i,
		data_out => data_o,
		
		intr => intr_i,
		inte => inte_o,
		inta => inta_o,
		halt => halt_o
	);


  ---------------------------------------------------------------------------
	-- clock: Clocking process.
	clock:
	process(done, clk)
	begin
		if done = '0' then
			clk <= not clk after T/2;
		end if;
	end process clock;


  main_test:
	process
	begin
		-- Assert reset for at least one full clk period
		reset <= '1';
		wait until clk = '1';
		wait for T/2;
		reset <= '0';

		-- Remember to 'cut away' the preceding 3 clk semiperiods from 
		-- the wait statement...
		wait for (sim_length - T*1.5);

		-- Stop the clk process asserting 'done'
		done <= '1';
		
 	  assert (done = '1') 
 		report "Test finished."
  	severity failure;
		
		wait;
	end process main_test;

  -- (Code) RAM access
  process(clk)
  begin
    if (clk'event and clk='1') then
      data_mem <= rom(conv_integer(addr_o(10 downto 0)));
      if wr_o = '1' then
        rom(conv_integer(addr_o(10 downto 0))) <= data_o;
      end if;  
    end if;
  end process;

  -- Interrupt vector ROM pointer; update it whenever the CPU fetches a byte
  -- while in INTA state.
  process(clk)
  begin
    if (clk'event and clk='1') then
      if inta_o = '1' and vma_o = '1' and rd_o='1' then
        vector_counter <= vector_counter + 1;
      end if;
    end if;
  end process;

  -- (Since the vector pointer pre-increments and the ROM in asynchronous, the
  -- first byte of the ROM is never used).
  int_vector <= int_vectors(vector_counter);

  data_i <= data_mem when inta_o='0' else int_vector;

  -- Trigger the IRQ input in a pattern carefully synchronized to the code of 
  -- the test bench (see 'asm/tb1.asm').
	int0:
	process
	begin
		intr_i <= '0';
		
		-- 
	  wait for T*89;
		intr_i <= '1';
		wait for T;
		intr_i <= '0';

		-- 
	  wait for T*87;
		intr_i <= '1';
		wait for T;
		intr_i <= '0';

		-- 
	  wait for T*49;
		intr_i <= '1';
		wait for T;
		intr_i <= '0';

		-- intr after cpu is halted
	  wait for T*41;
		intr_i <= '1';
		wait for T;
		intr_i <= '0';

    wait;
	end process int0;

END;
