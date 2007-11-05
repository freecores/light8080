--------------------------------------------------------------------------------
-- Light8080 simulation test bench 0 : Kelly Smith test
--------------------------------------------------------------------------------
-- This test executes the 'Kelly Smith test' which tests most instructions
-- and flags. At the end of the test, A will contain 0x55 on success or 0x0aa
-- on failure, and the cpu will halt.
-- Interrupts and i/o instructions are not tested.
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY light8080_tb0 IS
END light8080_tb0;

ARCHITECTURE behavior OF light8080_tb0 IS 

--------------------------------------------------------------------------------
-- Simulation parameters

-- sim_length: total simulation time
constant sim_length : time := 700000 ns;

-- T: simulation clock period
constant T : time := 100 ns;

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

	--Inputs
	SIGNAL intr_o :  std_logic := '0';
	SIGNAL data_i :  std_logic_vector(7 downto 0) := (others=>'0');

	--Outputs
	SIGNAL vma_o  :  std_logic;
	SIGNAL rd_o  :  std_logic;
	SIGNAL wr_o  :  std_logic;
	SIGNAL io_o  :  std_logic;
  SIGNAL data_o :  std_logic_vector(7 downto 0);
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
X"31",X"f5",X"05",X"3e",X"77",X"e6",X"00",X"ca",
X"0d",X"00",X"cd",X"e0",X"04",X"d2",X"13",X"00",
X"cd",X"e0",X"04",X"ea",X"19",X"00",X"cd",X"e0",
X"04",X"f2",X"1f",X"00",X"cd",X"e0",X"04",X"c2",
X"2e",X"00",X"da",X"2e",X"00",X"e2",X"2e",X"00",
X"fa",X"2e",X"00",X"c3",X"31",X"00",X"cd",X"e0",
X"04",X"c6",X"06",X"c2",X"39",X"00",X"cd",X"e0",
X"04",X"da",X"42",X"00",X"e2",X"42",X"00",X"f2",
X"45",X"00",X"cd",X"e0",X"04",X"c6",X"70",X"e2",
X"4d",X"00",X"cd",X"e0",X"04",X"fa",X"56",X"00",
X"ca",X"56",X"00",X"d2",X"59",X"00",X"cd",X"e0",
X"04",X"c6",X"81",X"fa",X"61",X"00",X"cd",X"e0",
X"04",X"ca",X"6a",X"00",X"da",X"6a",X"00",X"e2",
X"6d",X"00",X"cd",X"e0",X"04",X"c6",X"fe",X"da",
X"75",X"00",X"cd",X"e0",X"04",X"ca",X"7e",X"00",
X"e2",X"7e",X"00",X"fa",X"81",X"00",X"cd",X"e0",
X"04",X"fe",X"00",X"da",X"99",X"00",X"ca",X"99",
X"00",X"fe",X"f5",X"da",X"99",X"00",X"c2",X"99",
X"00",X"fe",X"ff",X"ca",X"99",X"00",X"da",X"9c",
X"00",X"cd",X"e0",X"04",X"ce",X"0a",X"ce",X"0a",
X"fe",X"0b",X"ca",X"a8",X"00",X"cd",X"e0",X"04",
X"d6",X"0c",X"d6",X"0f",X"fe",X"f0",X"ca",X"b4",
X"00",X"cd",X"e0",X"04",X"de",X"f1",X"de",X"0e",
X"fe",X"f0",X"ca",X"c0",X"00",X"cd",X"e0",X"04",
X"e6",X"55",X"fe",X"50",X"ca",X"ca",X"00",X"cd",
X"e0",X"04",X"f6",X"3a",X"fe",X"7a",X"ca",X"d4",
X"00",X"cd",X"e0",X"04",X"ee",X"0f",X"fe",X"75",
X"ca",X"de",X"00",X"cd",X"e0",X"04",X"e6",X"00",
X"dc",X"e0",X"04",X"e4",X"e0",X"04",X"fc",X"e0",
X"04",X"c4",X"e0",X"04",X"fe",X"00",X"ca",X"f4",
X"00",X"cd",X"e0",X"04",X"d6",X"77",X"d4",X"e0",
X"04",X"ec",X"e0",X"04",X"f4",X"e0",X"04",X"cc",
X"e0",X"04",X"fe",X"89",X"ca",X"0a",X"01",X"cd",
X"e0",X"04",X"e6",X"ff",X"e4",X"17",X"01",X"fe",
X"d9",X"ca",X"74",X"01",X"cd",X"e0",X"04",X"e8",
X"c6",X"10",X"ec",X"23",X"01",X"c6",X"02",X"e0",
X"cd",X"e0",X"04",X"e0",X"c6",X"20",X"fc",X"2f",
X"01",X"c6",X"04",X"e8",X"cd",X"e0",X"04",X"f0",
X"c6",X"80",X"f4",X"3b",X"01",X"c6",X"80",X"f8",
X"cd",X"e0",X"04",X"f8",X"c6",X"40",X"d4",X"47",
X"01",X"c6",X"40",X"f0",X"cd",X"e0",X"04",X"d8",
X"c6",X"8f",X"dc",X"53",X"01",X"d6",X"02",X"d0",
X"cd",X"e0",X"04",X"d0",X"c6",X"f7",X"c4",X"5f",
X"01",X"c6",X"fe",X"d8",X"cd",X"e0",X"04",X"c8",
X"c6",X"01",X"cc",X"6b",X"01",X"c6",X"d0",X"c0",
X"cd",X"e0",X"04",X"c0",X"c6",X"47",X"fe",X"47",
X"c8",X"cd",X"e0",X"04",X"3e",X"77",X"3c",X"47",
X"04",X"48",X"0d",X"51",X"5a",X"63",X"6c",X"7d",
X"3d",X"4f",X"59",X"6b",X"45",X"50",X"62",X"7c",
X"57",X"14",X"6a",X"4d",X"0c",X"61",X"44",X"05",
X"58",X"7b",X"5f",X"1c",X"43",X"60",X"24",X"4c",
X"69",X"55",X"15",X"7a",X"67",X"25",X"54",X"42",
X"68",X"2c",X"5d",X"1d",X"4b",X"79",X"6f",X"2d",
X"65",X"5c",X"53",X"4a",X"41",X"78",X"fe",X"77",
X"c4",X"e0",X"04",X"af",X"06",X"01",X"0e",X"03",
X"16",X"07",X"1e",X"0f",X"26",X"1f",X"2e",X"3f",
X"80",X"81",X"82",X"83",X"84",X"85",X"87",X"fe",
X"f0",X"c4",X"e0",X"04",X"90",X"91",X"92",X"93",
X"94",X"95",X"fe",X"78",X"c4",X"e0",X"04",X"97",
X"c4",X"e0",X"04",X"3e",X"80",X"87",X"06",X"01",
X"0e",X"02",X"16",X"03",X"1e",X"04",X"26",X"05",
X"2e",X"06",X"88",X"06",X"80",X"80",X"80",X"89",
X"80",X"80",X"8a",X"80",X"80",X"8b",X"80",X"80",
X"8c",X"80",X"80",X"8d",X"80",X"80",X"8f",X"fe",
X"37",X"c4",X"e0",X"04",X"3e",X"80",X"87",X"06",
X"01",X"98",X"06",X"ff",X"80",X"99",X"80",X"9a",
X"80",X"9b",X"80",X"9c",X"80",X"9d",X"fe",X"e0",
X"c4",X"e0",X"04",X"3e",X"80",X"87",X"9f",X"fe",
X"ff",X"c4",X"e0",X"04",X"3e",X"ff",X"06",X"fe",
X"0e",X"fc",X"16",X"ef",X"1e",X"7f",X"26",X"f4",
X"2e",X"bf",X"a7",X"a1",X"a2",X"a3",X"a4",X"a5",
X"a7",X"fe",X"24",X"c4",X"e0",X"04",X"af",X"06",
X"01",X"0e",X"02",X"16",X"04",X"1e",X"08",X"26",
X"10",X"2e",X"20",X"b0",X"b1",X"b2",X"b3",X"b4",
X"b5",X"b7",X"fe",X"3f",X"c4",X"e0",X"04",X"3e",
X"00",X"26",X"8f",X"2e",X"4f",X"a8",X"a9",X"aa",
X"ab",X"ac",X"ad",X"fe",X"cf",X"c4",X"e0",X"04",
X"af",X"c4",X"e0",X"04",X"06",X"44",X"0e",X"45",
X"16",X"46",X"1e",X"47",X"26",X"04",X"2e",X"ee",
X"70",X"06",X"00",X"46",X"3e",X"44",X"b8",X"c4",
X"e0",X"04",X"72",X"16",X"00",X"56",X"3e",X"46",
X"ba",X"c4",X"e0",X"04",X"73",X"1e",X"00",X"5e",
X"3e",X"47",X"bb",X"c4",X"e0",X"04",X"74",X"26",
X"04",X"2e",X"ee",X"66",X"3e",X"04",X"bc",X"c4",
X"e0",X"04",X"75",X"26",X"04",X"2e",X"ee",X"6e",
X"3e",X"ee",X"bd",X"c4",X"e0",X"04",X"26",X"04",
X"2e",X"ee",X"3e",X"32",X"77",X"be",X"c4",X"e0",
X"04",X"86",X"fe",X"64",X"c4",X"e0",X"04",X"af",
X"7e",X"fe",X"32",X"c4",X"e0",X"04",X"26",X"04",
X"2e",X"ee",X"7e",X"96",X"c4",X"e0",X"04",X"3e",
X"80",X"87",X"8e",X"fe",X"33",X"c4",X"e0",X"04",
X"3e",X"80",X"87",X"9e",X"fe",X"cd",X"c4",X"e0",
X"04",X"a6",X"c4",X"e0",X"04",X"3e",X"25",X"b6",
X"fe",X"37",X"c4",X"e0",X"04",X"ae",X"fe",X"05",
X"c4",X"e0",X"04",X"36",X"55",X"34",X"35",X"86",
X"fe",X"5a",X"c4",X"e0",X"04",X"01",X"ff",X"12",
X"11",X"ff",X"12",X"21",X"ff",X"12",X"03",X"13",
X"23",X"3e",X"13",X"b8",X"c4",X"e0",X"04",X"ba",
X"c4",X"e0",X"04",X"bc",X"c4",X"e0",X"04",X"3e",
X"00",X"b9",X"c4",X"e0",X"04",X"bb",X"c4",X"e0",
X"04",X"bd",X"c4",X"e0",X"04",X"0b",X"1b",X"2b",
X"3e",X"12",X"b8",X"c4",X"e0",X"04",X"ba",X"c4",
X"e0",X"04",X"bc",X"c4",X"e0",X"04",X"3e",X"ff",
X"b9",X"c4",X"e0",X"04",X"bb",X"c4",X"e0",X"04",
X"bd",X"c4",X"e0",X"04",X"32",X"ee",X"04",X"af",
X"3a",X"ee",X"04",X"fe",X"ff",X"c4",X"e0",X"04",
X"2a",X"ec",X"04",X"22",X"ee",X"04",X"3a",X"ec",
X"04",X"47",X"3a",X"ee",X"04",X"b8",X"c4",X"e0",
X"04",X"3a",X"ed",X"04",X"47",X"3a",X"ef",X"04",
X"b8",X"c4",X"e0",X"04",X"3e",X"aa",X"32",X"ee",
X"04",X"44",X"4d",X"af",X"0a",X"fe",X"aa",X"c4",
X"e0",X"04",X"3c",X"02",X"3a",X"ee",X"04",X"fe",
X"ab",X"c4",X"e0",X"04",X"3e",X"77",X"32",X"ee",
X"04",X"2a",X"ec",X"04",X"11",X"00",X"00",X"eb",
X"af",X"1a",X"fe",X"77",X"c4",X"e0",X"04",X"af",
X"84",X"85",X"c4",X"e0",X"04",X"3e",X"cc",X"12",
X"3a",X"ee",X"04",X"fe",X"cc",X"12",X"3a",X"ee",
X"04",X"fe",X"cc",X"c4",X"e0",X"04",X"21",X"77",
X"77",X"29",X"3e",X"ee",X"bc",X"c4",X"e0",X"04",
X"bd",X"c4",X"e0",X"04",X"21",X"55",X"55",X"01",
X"ff",X"ff",X"09",X"3e",X"55",X"d4",X"e0",X"04",
X"bc",X"c4",X"e0",X"04",X"3e",X"54",X"bd",X"c4",
X"e0",X"04",X"21",X"aa",X"aa",X"11",X"33",X"33",
X"19",X"3e",X"dd",X"bc",X"c4",X"e0",X"04",X"bd",
X"c4",X"e0",X"04",X"37",X"d4",X"e0",X"04",X"3f",
X"dc",X"e0",X"04",X"3e",X"aa",X"2f",X"fe",X"55",
X"c4",X"e0",X"04",X"b7",X"27",X"fe",X"55",X"c4",
X"e0",X"04",X"3e",X"88",X"87",X"27",X"fe",X"76",
X"c4",X"e0",X"04",X"af",X"3e",X"aa",X"27",X"d4",
X"e0",X"04",X"fe",X"10",X"c4",X"e0",X"04",X"af",
X"3e",X"9a",X"27",X"d4",X"e0",X"04",X"c4",X"e0",
X"04",X"37",X"3e",X"42",X"07",X"dc",X"e0",X"04",
X"07",X"d4",X"e0",X"04",X"fe",X"09",X"c4",X"e0",
X"04",X"0f",X"d4",X"e0",X"04",X"0f",X"fe",X"42",
X"c4",X"e0",X"04",X"17",X"17",X"d4",X"e0",X"04",
X"fe",X"08",X"c4",X"e0",X"04",X"1f",X"1f",X"dc",
X"e0",X"04",X"fe",X"02",X"c4",X"e0",X"04",X"01",
X"34",X"12",X"11",X"aa",X"aa",X"21",X"55",X"55",
X"af",X"c5",X"d5",X"e5",X"f5",X"01",X"00",X"00",
X"11",X"00",X"00",X"21",X"00",X"00",X"3e",X"c0",
X"c6",X"f0",X"f1",X"e1",X"d1",X"c1",X"dc",X"e0",
X"04",X"c4",X"e0",X"04",X"e4",X"e0",X"04",X"fc",
X"e0",X"04",X"3e",X"12",X"b8",X"c4",X"e0",X"04",
X"3e",X"34",X"b9",X"c4",X"e0",X"04",X"3e",X"aa",
X"ba",X"c4",X"e0",X"04",X"bb",X"c4",X"e0",X"04",
X"3e",X"55",X"bc",X"c4",X"e0",X"04",X"bd",X"c4",
X"e0",X"04",X"21",X"00",X"00",X"39",X"22",X"f3",
X"04",X"31",X"f2",X"04",X"3b",X"3b",X"33",X"3b",
X"3e",X"55",X"32",X"f0",X"04",X"2f",X"32",X"f1",
X"04",X"c1",X"b8",X"c4",X"e0",X"04",X"2f",X"b9",
X"c4",X"e0",X"04",X"21",X"f2",X"04",X"f9",X"21",
X"33",X"77",X"3b",X"3b",X"e3",X"3a",X"f1",X"04",
X"fe",X"77",X"c4",X"e0",X"04",X"3a",X"f0",X"04",
X"fe",X"33",X"c4",X"e0",X"04",X"3e",X"55",X"bd",
X"c4",X"e0",X"04",X"2f",X"bc",X"c4",X"e0",X"04",
X"2a",X"f3",X"04",X"f9",X"21",X"e6",X"04",X"e9",
X"3e",X"aa",X"32",X"00",X"ff",X"76",X"3e",X"55",
X"32",X"00",X"ff",X"76",X"ee",X"04",X"00",X"00",
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
		wait;
	end process main_test;


  process(clk)
  begin
    if (clk'event and clk='1') then
      data_i <= rom(conv_integer(addr_o(10 downto 0)));
      if wr_o = '1' then
        rom(conv_integer(addr_o(10 downto 0))) <= data_o;
      end if;  
    end if;
  end process;


END;
