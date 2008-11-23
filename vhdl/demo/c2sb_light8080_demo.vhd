--#############################################################################
-- Light8080 core demo 0 : IMSAI SCS1 monitor/assembler
-- 
-- Designed for Cyclone II FPGA Starter Develoment Kit from terasIC.
-- Runs IMSAI SCS1 monitor on serial port, using 4KB of internal RAM.
-- Documentation for the monitor and Altera Quartus pin assignment files are 
-- included.
--
-- All that's really needed to run the demo is the serial interface (2 pins),
-- so this should be easy to adapt to any other dev board.
--#############################################################################

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity c2sb_light8080_demo is
    port ( 
				clk_50MHz			: in std_logic;

				flash_addr		: out std_logic_vector(21 downto 0);
				flash_data		: in std_logic_vector(7 downto 0);
				flash_oe			: out std_logic;
				flash_we			: out std_logic;
				flash_reset		: out std_logic;

				rxd 					: in std_logic;
				txd						: out std_logic;

				switches			: in std_logic_vector(9 downto 0);
				buttons				: in std_logic_vector(3 downto 0);

				red_leds			: out std_logic_vector(9 downto 0);
				green_leds		: out std_logic_vector(7 downto 0)		
		);
end c2sb_light8080_demo;

architecture demo of c2sb_light8080_demo is


component light8080
port (  
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
end component;

-- Serial port, RX 
component rs232_rx
port(
		rxd 			: IN std_logic;
		read_rx 	: IN std_logic;
		clk 			: IN std_logic;
		reset 		: IN std_logic;          
		data_rx 	: OUT std_logic_vector(7 downto 0);
		rx_rdy 		: OUT std_logic
		);
end component;

-- Serial port, TX
component rs232_tx
port(
		clk 			: IN std_logic;
		reset 		: IN std_logic;
		load 			: IN std_logic;
		data_i 		: IN std_logic_vector(7 downto 0);          
		rdy 			: OUT std_logic;
		txd				: OUT std_logic
		);
end component;


--##############################################################################
-- light8080 CPU system signals

signal data_in :          std_logic_vector(7 downto 0);
signal vma :              std_logic;
signal rd :               std_logic;
signal wr  :              std_logic;
signal io  :              std_logic;
signal data_out :         std_logic_vector(7 downto 0);
signal addr :             std_logic_vector(15 downto 0);
signal inta :             std_logic;
signal inte :             std_logic;
signal intr :             std_logic;
signal halt :             std_logic;


signal reg_h :            std_logic_vector(7 downto 0);
signal reg_l :            std_logic_vector(7 downto 0);  
signal io_q :							std_logic;
signal rd_q :							std_logic;
signal io_read : 					std_logic;
signal io_write :					std_logic;

--##############################################################################
-- RS232 signals

signal rx_rdy :						std_logic;
signal tx_rdy :						std_logic;
signal rs232_data_rx : 		std_logic_vector(7 downto 0);
signal rs232_status :			std_logic_vector(7 downto 0);
signal data_io_out :  		std_logic_vector(7 downto 0);
signal io_port :	    		std_logic_vector(7 downto 0);
signal read_rx : 					std_logic;
signal write_tx :					std_logic;

signal rom_addr :         std_logic_vector(11 downto 0);
type t_rom is array(0 to 4095) of std_logic_vector(7 downto 0);

signal rom : t_rom := (
-- @begin_rom 

X"c3",X"40",X"00",X"c3",X"69",X"00",X"00",X"00",
X"c3",X"87",X"0d",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"21",X"79",X"04",X"cd",X"7d",X"02",X"cd",X"11",
X"01",X"21",X"ad",X"04",X"cd",X"7d",X"02",X"cd",
X"11",X"01",X"21",X"27",X"0e",X"0e",X"4e",X"af",
X"77",X"23",X"0d",X"c2",X"58",X"00",X"06",X"18",
X"21",X"0f",X"0e",X"77",X"23",X"05",X"c2",X"63",
X"00",X"31",X"b5",X"0e",X"cd",X"11",X"01",X"cd",
X"82",X"00",X"23",X"7e",X"fe",X"3a",X"da",X"0e",
X"05",X"cd",X"76",X"01",X"cd",X"2e",X"01",X"c3",
X"69",X"00",X"21",X"ca",X"0e",X"22",X"77",X"0e",
X"1e",X"02",X"cd",X"f7",X"00",X"78",X"fe",X"18",
X"c2",X"99",X"00",X"cd",X"11",X"01",X"c3",X"82",
X"00",X"fe",X"0d",X"c2",X"b4",X"00",X"7d",X"fe",
X"ca",X"ca",X"82",X"00",X"36",X"0d",X"23",X"36",
X"01",X"23",X"3e",X"1d",X"cd",X"e3",X"00",X"21",
X"c9",X"0e",X"73",X"c9",X"fe",X"7f",X"c2",X"c9",
X"00",X"3e",X"ca",X"bd",X"ca",X"8a",X"00",X"2b",
X"1d",X"06",X"5f",X"cd",X"05",X"01",X"c3",X"8a",
X"00",X"fe",X"20",X"da",X"8a",X"00",X"fe",X"7b",
X"d2",X"8a",X"00",X"47",X"cd",X"05",X"01",X"70",
X"3e",X"1b",X"bd",X"ca",X"c1",X"00",X"23",X"1c",
X"c3",X"8a",X"00",X"bd",X"c8",X"36",X"20",X"23",
X"c3",X"e3",X"00",X"db",X"20",X"e6",X"01",X"c0",
X"db",X"21",X"e6",X"7f",X"fe",X"38",X"c9",X"db",
X"20",X"2f",X"e6",X"01",X"ca",X"f7",X"00",X"db",
X"21",X"e6",X"7f",X"47",X"c9",X"db",X"20",X"2f",
X"e6",X"80",X"ca",X"05",X"01",X"78",X"d3",X"21",
X"c9",X"06",X"0d",X"cd",X"05",X"01",X"06",X"0a",
X"cd",X"05",X"01",X"06",X"7f",X"cd",X"05",X"01",
X"cd",X"05",X"01",X"c9",X"cd",X"03",X"03",X"cd",
X"11",X"01",X"2a",X"8d",X"0e",X"e9",X"11",X"c1",
X"02",X"06",X"0b",X"3e",X"04",X"32",X"98",X"0e",
X"cd",X"3f",X"01",X"c2",X"5d",X"04",X"e9",X"2a",
X"77",X"0e",X"3a",X"98",X"0e",X"4f",X"cd",X"56",
X"01",X"1a",X"6f",X"13",X"1a",X"67",X"c8",X"13",
X"05",X"c2",X"3f",X"01",X"04",X"c9",X"1a",X"be",
X"c2",X"62",X"01",X"23",X"13",X"0d",X"c2",X"56",
X"01",X"c9",X"13",X"0d",X"c2",X"62",X"01",X"0c",
X"c9",X"af",X"11",X"8d",X"0e",X"06",X"0c",X"1b",
X"12",X"05",X"c2",X"6f",X"01",X"c9",X"cd",X"7d",
X"01",X"da",X"5d",X"04",X"c9",X"21",X"00",X"00",
X"22",X"8f",X"0e",X"22",X"79",X"0e",X"cd",X"69",
X"01",X"21",X"c9",X"0e",X"23",X"7e",X"fe",X"20",
X"3f",X"d0",X"c2",X"8c",X"01",X"22",X"99",X"0e",
X"cd",X"66",X"09",X"3f",X"d0",X"fe",X"2f",X"c2",
X"c7",X"01",X"11",X"79",X"0e",X"0e",X"05",X"23",
X"7e",X"fe",X"2f",X"ca",X"b7",X"01",X"0d",X"fa",
X"5d",X"04",X"12",X"13",X"c3",X"a7",X"01",X"3e",
X"20",X"0d",X"fa",X"c2",X"01",X"12",X"13",X"c3",
X"b9",X"01",X"cd",X"6d",X"09",X"3f",X"d0",X"11",
X"81",X"0e",X"cd",X"ce",X"0b",X"78",X"fe",X"05",
X"3f",X"d8",X"01",X"81",X"0e",X"cd",X"1e",X"02",
X"d8",X"22",X"8d",X"0e",X"21",X"81",X"0e",X"cd",
X"16",X"06",X"cd",X"66",X"09",X"3f",X"d0",X"11",
X"85",X"0e",X"cd",X"ce",X"0b",X"78",X"fe",X"05",
X"3f",X"d8",X"01",X"85",X"0e",X"cd",X"1e",X"02",
X"d8",X"22",X"8f",X"0e",X"21",X"85",X"0e",X"cd",
X"16",X"06",X"b7",X"c9",X"21",X"00",X"00",X"0a",
X"b7",X"c8",X"54",X"5d",X"29",X"29",X"19",X"29",
X"d6",X"30",X"fe",X"0a",X"3f",X"d8",X"5f",X"16",
X"00",X"19",X"03",X"c3",X"07",X"02",X"21",X"00",
X"00",X"0a",X"b7",X"c8",X"29",X"29",X"29",X"29",
X"cd",X"35",X"02",X"fe",X"10",X"3f",X"d8",X"85",
X"6f",X"03",X"c3",X"21",X"02",X"d6",X"30",X"fe",
X"0a",X"d8",X"d6",X"07",X"c9",X"cd",X"89",X"02",
X"21",X"77",X"0e",X"46",X"cd",X"05",X"01",X"23",
X"46",X"cd",X"05",X"01",X"c9",X"cd",X"3d",X"02",
X"cd",X"60",X"02",X"c9",X"cd",X"a6",X"02",X"cd",
X"40",X"02",X"23",X"46",X"cd",X"05",X"01",X"c9",
X"06",X"20",X"cd",X"05",X"01",X"c9",X"2a",X"8d",
X"0e",X"3a",X"90",X"0e",X"bc",X"c2",X"78",X"02",
X"3a",X"8f",X"0e",X"bd",X"c2",X"78",X"02",X"37",
X"23",X"22",X"8d",X"0e",X"c9",X"46",X"3e",X"0d",
X"b8",X"c8",X"cd",X"05",X"01",X"23",X"c3",X"7d",
X"02",X"21",X"77",X"0e",X"47",X"1f",X"1f",X"1f",
X"1f",X"cd",X"9c",X"02",X"77",X"23",X"78",X"cd",
X"9c",X"02",X"77",X"c9",X"e6",X"0f",X"c6",X"30",
X"fe",X"3a",X"d8",X"c6",X"07",X"c9",X"21",X"77",
X"0e",X"06",X"64",X"cd",X"b7",X"02",X"06",X"0a",
X"cd",X"b7",X"02",X"c6",X"30",X"77",X"c9",X"36",
X"2f",X"34",X"90",X"d2",X"b9",X"02",X"80",X"23",
X"c9",X"64",X"75",X"6d",X"70",X"0b",X"03",X"65",
X"78",X"65",X"63",X"24",X"01",X"65",X"6e",X"74",
X"72",X"cf",X"04",X"66",X"69",X"6c",X"65",X"41",
X"03",X"6c",X"69",X"73",X"74",X"29",X"06",X"64",
X"65",X"6c",X"74",X"40",X"06",X"61",X"73",X"73",
X"6d",X"b7",X"06",X"70",X"61",X"67",X"65",X"25",
X"03",X"63",X"75",X"73",X"74",X"00",X"20",X"62",
X"72",X"65",X"6b",X"2b",X"0d",X"70",X"72",X"6f",
X"63",X"e6",X"0d",X"3a",X"81",X"0e",X"b7",X"ca",
X"5d",X"04",X"c9",X"cd",X"03",X"03",X"cd",X"11",
X"01",X"2a",X"8d",X"0e",X"7e",X"cd",X"4d",X"02",
X"cd",X"66",X"02",X"d8",X"7d",X"e6",X"0f",X"c2",
X"11",X"03",X"c3",X"0e",X"03",X"cd",X"03",X"03",
X"3a",X"85",X"0e",X"b7",X"ca",X"5d",X"04",X"2a",
X"8d",X"0e",X"eb",X"2a",X"8f",X"0e",X"06",X"00",
X"1a",X"77",X"23",X"13",X"05",X"c2",X"38",X"03",
X"c9",X"cd",X"11",X"01",X"3a",X"79",X"0e",X"b7",
X"ca",X"bc",X"03",X"cd",X"1b",X"04",X"eb",X"c2",
X"66",X"03",X"3a",X"81",X"0e",X"b7",X"ca",X"60",
X"04",X"3a",X"80",X"0e",X"b7",X"c2",X"7b",X"03",
X"21",X"6e",X"04",X"c3",X"63",X"04",X"3a",X"81",
X"0e",X"b7",X"ca",X"8e",X"03",X"2a",X"8d",X"0e",
X"7c",X"b5",X"ca",X"8e",X"03",X"21",X"73",X"04",
X"c3",X"63",X"04",X"2a",X"7e",X"0e",X"eb",X"21",
X"79",X"0e",X"d5",X"0e",X"05",X"7e",X"12",X"13",
X"0d",X"23",X"c2",X"85",X"03",X"d1",X"21",X"27",
X"0e",X"0e",X"0d",X"1a",X"46",X"77",X"78",X"12",
X"13",X"23",X"0d",X"c2",X"93",X"03",X"3a",X"81",
X"0e",X"b7",X"ca",X"c6",X"03",X"2a",X"8d",X"0e",
X"22",X"2c",X"0e",X"22",X"2e",X"0e",X"7d",X"b4",
X"ca",X"b5",X"03",X"36",X"01",X"af",X"32",X"30",
X"0e",X"c3",X"c6",X"03",X"3a",X"ce",X"0e",X"fe",
X"73",X"0e",X"06",X"ca",X"c8",X"03",X"0e",X"01",
X"21",X"27",X"0e",X"79",X"32",X"80",X"0e",X"e5",
X"11",X"05",X"00",X"19",X"7e",X"b7",X"c2",X"e6",
X"03",X"23",X"86",X"23",X"c2",X"e6",X"03",X"33",
X"33",X"23",X"23",X"c3",X"fb",X"03",X"e1",X"0e",
X"05",X"46",X"cd",X"05",X"01",X"0d",X"23",X"c2",
X"e9",X"03",X"cd",X"07",X"04",X"cd",X"07",X"04",
X"cd",X"11",X"01",X"11",X"04",X"00",X"19",X"3a",
X"80",X"0e",X"3d",X"c2",X"cc",X"03",X"c9",X"cd",
X"60",X"02",X"23",X"7e",X"2b",X"e5",X"cd",X"3d",
X"02",X"e1",X"7e",X"23",X"23",X"e5",X"cd",X"4d",
X"02",X"e1",X"c9",X"af",X"32",X"80",X"0e",X"06",
X"06",X"11",X"27",X"0e",X"21",X"79",X"0e",X"0e",
X"05",X"cd",X"56",X"01",X"f5",X"d5",X"1a",X"b7",
X"c2",X"51",X"04",X"13",X"1a",X"b7",X"c2",X"51",
X"04",X"eb",X"11",X"fa",X"ff",X"19",X"22",X"7e",
X"0e",X"7a",X"32",X"80",X"0e",X"e1",X"f1",X"11",
X"08",X"00",X"19",X"eb",X"05",X"c8",X"c3",X"24",
X"04",X"e1",X"f1",X"c2",X"47",X"04",X"11",X"fb",
X"ff",X"19",X"7a",X"b7",X"c9",X"cd",X"11",X"01",
X"21",X"69",X"04",X"cd",X"7d",X"02",X"c3",X"69",
X"00",X"77",X"68",X"61",X"74",X"0d",X"66",X"75",
X"6c",X"6c",X"0d",X"6e",X"6f",X"20",X"6e",X"6f",
X"0d",X"49",X"4d",X"53",X"41",X"49",X"20",X"53",
X"43",X"53",X"2d",X"31",X"20",X"4d",X"6f",X"6e",
X"69",X"74",X"6f",X"72",X"2f",X"41",X"73",X"73",
X"65",X"6d",X"62",X"6c",X"65",X"72",X"20",X"28",
X"72",X"65",X"76",X"2e",X"20",X"32",X"20",X"30",
X"36",X"20",X"6f",X"63",X"74",X"2e",X"20",X"31",
X"39",X"37",X"36",X"29",X"0d",X"28",X"72",X"65",
X"76",X"69",X"73",X"65",X"64",X"20",X"66",X"6f",
X"72",X"20",X"6c",X"69",X"67",X"68",X"74",X"38",
X"30",X"38",X"30",X"20",X"46",X"50",X"47",X"41",
X"20",X"63",X"6f",X"72",X"65",X"29",X"0d",X"cd",
X"03",X"03",X"cd",X"dc",X"04",X"da",X"5d",X"04",
X"cd",X"11",X"01",X"c9",X"cd",X"11",X"01",X"cd",
X"82",X"00",X"21",X"ca",X"0e",X"22",X"99",X"0e",
X"cd",X"69",X"01",X"cd",X"66",X"09",X"da",X"dc",
X"04",X"fe",X"2f",X"c8",X"cd",X"ce",X"0b",X"78",
X"fe",X"03",X"3f",X"d8",X"01",X"81",X"0e",X"cd",
X"1e",X"02",X"d8",X"7d",X"2a",X"8d",X"0e",X"77",
X"cd",X"78",X"02",X"c3",X"e8",X"04",X"3a",X"27",
X"0e",X"b7",X"ca",X"5d",X"04",X"0e",X"04",X"21",
X"c9",X"0e",X"23",X"7e",X"fe",X"30",X"da",X"5d",
X"04",X"fe",X"3a",X"d2",X"5d",X"04",X"0d",X"c2",
X"1a",X"05",X"22",X"77",X"0e",X"11",X"33",X"0e",
X"cd",X"fb",X"05",X"d2",X"53",X"05",X"23",X"cd",
X"eb",X"05",X"21",X"33",X"0e",X"cd",X"f3",X"05",
X"11",X"c9",X"0e",X"2a",X"2e",X"0e",X"0e",X"01",
X"cd",X"d9",X"05",X"36",X"01",X"22",X"2e",X"0e",
X"c3",X"69",X"00",X"cd",X"ab",X"05",X"0e",X"02",
X"ca",X"5c",X"05",X"0d",X"46",X"2b",X"36",X"02",
X"22",X"75",X"0e",X"3a",X"c9",X"0e",X"0d",X"ca",
X"71",X"05",X"90",X"ca",X"94",X"05",X"da",X"84",
X"05",X"2a",X"2e",X"0e",X"54",X"5d",X"cd",X"d4",
X"05",X"22",X"2e",X"0e",X"0e",X"02",X"cd",X"e2",
X"05",X"c3",X"94",X"05",X"2f",X"3c",X"54",X"5d",
X"cd",X"d4",X"05",X"eb",X"cd",X"d9",X"05",X"36",
X"01",X"22",X"2e",X"0e",X"2a",X"75",X"0e",X"36",
X"0d",X"23",X"11",X"c9",X"0e",X"0e",X"01",X"cd",
X"d9",X"05",X"c3",X"69",X"00",X"21",X"84",X"0e",
X"22",X"77",X"0e",X"2a",X"2c",X"0e",X"7c",X"b5",
X"ca",X"69",X"00",X"cd",X"cd",X"05",X"eb",X"2a",
X"77",X"0e",X"eb",X"3e",X"04",X"cd",X"d4",X"05",
X"cd",X"fb",X"05",X"d8",X"c8",X"7e",X"cd",X"d4",
X"05",X"c3",X"b3",X"05",X"23",X"3e",X"01",X"be",
X"c0",X"c3",X"69",X"00",X"85",X"6f",X"d0",X"24",
X"c9",X"1a",X"13",X"b9",X"c8",X"77",X"23",X"c3",
X"d9",X"05",X"1a",X"1b",X"b9",X"c8",X"77",X"2b",
X"c3",X"e2",X"05",X"46",X"23",X"4e",X"23",X"56",
X"23",X"5e",X"c9",X"73",X"2b",X"72",X"2b",X"71",
X"2b",X"70",X"c9",X"06",X"01",X"0e",X"04",X"b7",
X"1a",X"9e",X"ca",X"06",X"06",X"04",X"1b",X"2b",
X"0d",X"c2",X"00",X"06",X"05",X"c9",X"0e",X"04",
X"1a",X"d6",X"01",X"c3",X"01",X"06",X"cd",X"eb",
X"05",X"af",X"b8",X"c8",X"bb",X"c4",X"f3",X"05",
X"c0",X"5a",X"51",X"48",X"06",X"30",X"c3",X"1c",
X"06",X"cd",X"11",X"01",X"cd",X"a5",X"05",X"23",
X"cd",X"7d",X"02",X"cd",X"11",X"01",X"cd",X"cc",
X"05",X"cd",X"eb",X"00",X"c2",X"2f",X"06",X"c9",
X"cd",X"03",X"03",X"cd",X"a5",X"05",X"22",X"75",
X"0e",X"21",X"88",X"0e",X"7e",X"b7",X"c2",X"54",
X"06",X"21",X"84",X"0e",X"22",X"77",X"0e",X"eb",
X"21",X"33",X"0e",X"cd",X"fb",X"05",X"2a",X"75",
X"0e",X"da",X"a2",X"06",X"22",X"2e",X"0e",X"36",
X"01",X"eb",X"2a",X"2c",X"0e",X"eb",X"06",X"0d",
X"2b",X"7d",X"93",X"7c",X"9a",X"3e",X"0d",X"da",
X"99",X"06",X"05",X"2b",X"be",X"c2",X"71",X"06",
X"2b",X"7d",X"93",X"7c",X"9a",X"da",X"9a",X"06",
X"be",X"23",X"23",X"ca",X"8f",X"06",X"23",X"cd",
X"eb",X"05",X"21",X"33",X"0e",X"cd",X"f3",X"05",
X"c9",X"b8",X"eb",X"c2",X"8e",X"06",X"32",X"30",
X"0e",X"c9",X"cd",X"b3",X"05",X"cc",X"c5",X"05",
X"eb",X"2a",X"75",X"0e",X"0e",X"01",X"cd",X"d9",
X"05",X"22",X"2e",X"0e",X"36",X"01",X"c9",X"cd",
X"03",X"03",X"3a",X"85",X"0e",X"b7",X"c2",X"c7",
X"06",X"2a",X"8d",X"0e",X"22",X"8f",X"0e",X"3a",
X"ce",X"0e",X"d6",X"65",X"32",X"91",X"0e",X"af",
X"32",X"9b",X"0e",X"32",X"97",X"0e",X"cd",X"11",
X"01",X"2a",X"8d",X"0e",X"22",X"95",X"0e",X"2a",
X"2c",X"0e",X"22",X"75",X"0e",X"2a",X"75",X"0e",
X"31",X"b5",X"0e",X"7e",X"fe",X"01",X"ca",X"5a",
X"09",X"eb",X"13",X"21",X"b5",X"0e",X"3e",X"c5",
X"cd",X"e3",X"00",X"0e",X"0d",X"cd",X"d9",X"05",
X"71",X"eb",X"22",X"75",X"0e",X"3a",X"97",X"0e",
X"b7",X"c2",X"12",X"07",X"cd",X"35",X"07",X"c3",
X"e5",X"06",X"cd",X"ec",X"07",X"21",X"b5",X"0e",
X"cd",X"1e",X"07",X"c3",X"e5",X"06",X"3a",X"91",
X"0e",X"b7",X"c2",X"2b",X"07",X"3a",X"b5",X"0e",
X"fe",X"20",X"c8",X"21",X"b5",X"0e",X"cd",X"7d",
X"02",X"cd",X"11",X"01",X"c9",X"cd",X"69",X"01",
X"32",X"97",X"0e",X"21",X"ca",X"0e",X"22",X"99",
X"0e",X"7e",X"fe",X"20",X"ca",X"77",X"07",X"fe",
X"2a",X"c8",X"cd",X"79",X"0b",X"da",X"38",X"0b",
X"ca",X"20",X"0d",X"cd",X"8e",X"07",X"c2",X"38",
X"0b",X"0e",X"05",X"21",X"81",X"0e",X"7e",X"12",
X"13",X"23",X"0d",X"c2",X"5e",X"07",X"eb",X"22",
X"93",X"0e",X"3a",X"96",X"0e",X"77",X"23",X"3a",
X"95",X"0e",X"77",X"21",X"9b",X"0e",X"34",X"cd",
X"69",X"01",X"cd",X"66",X"09",X"da",X"5f",X"0b",
X"cd",X"ce",X"0b",X"fe",X"20",X"da",X"be",X"0a",
X"c2",X"5f",X"0b",X"c3",X"be",X"0a",X"2a",X"99",
X"0e",X"7e",X"fe",X"20",X"c8",X"fe",X"3a",X"c0",
X"23",X"22",X"99",X"0e",X"c9",X"cd",X"66",X"09",
X"1a",X"b7",X"ca",X"b9",X"07",X"fa",X"e9",X"07",
X"e2",X"ce",X"07",X"fe",X"05",X"da",X"e1",X"07",
X"c2",X"5a",X"09",X"0e",X"02",X"af",X"c3",X"4e",
X"0b",X"cd",X"f0",X"0b",X"3a",X"b5",X"0e",X"fe",
X"20",X"c0",X"22",X"95",X"0e",X"3a",X"ca",X"0e",
X"fe",X"20",X"c8",X"c3",X"d9",X"07",X"cd",X"f0",
X"0b",X"3a",X"ca",X"0e",X"fe",X"20",X"ca",X"f8",
X"0c",X"eb",X"2a",X"93",X"0e",X"72",X"23",X"73",
X"c9",X"cd",X"f0",X"0b",X"44",X"4d",X"c3",X"46",
X"08",X"c3",X"4d",X"08",X"21",X"b7",X"0e",X"3a",
X"96",X"0e",X"cd",X"8c",X"02",X"23",X"3a",X"95",
X"0e",X"cd",X"8c",X"02",X"23",X"22",X"a1",X"0e",
X"cd",X"69",X"01",X"21",X"ca",X"0e",X"22",X"99",
X"0e",X"7e",X"fe",X"20",X"ca",X"77",X"07",X"fe",
X"2a",X"c8",X"cd",X"79",X"0b",X"da",X"1b",X"0d",
X"cd",X"8e",X"07",X"c2",X"1b",X"0d",X"c3",X"77",
X"07",X"1a",X"b7",X"ca",X"65",X"08",X"fa",X"4a",
X"08",X"e2",X"53",X"08",X"fe",X"05",X"da",X"3a",
X"08",X"c2",X"5a",X"09",X"cd",X"3a",X"09",X"c3",
X"b3",X"07",X"cd",X"ed",X"0b",X"44",X"4d",X"2a",
X"8f",X"0e",X"09",X"22",X"8f",X"0e",X"af",X"c3",
X"51",X"0b",X"cd",X"f9",X"08",X"af",X"0e",X"01",
X"c3",X"4e",X"0b",X"cd",X"ed",X"0b",X"eb",X"21",
X"b7",X"0e",X"7a",X"cd",X"8c",X"02",X"23",X"7b",
X"cd",X"8c",X"02",X"23",X"c9",X"cd",X"ed",X"0b",
X"3a",X"b5",X"0e",X"fe",X"20",X"c0",X"cd",X"56",
X"08",X"2a",X"95",X"0e",X"eb",X"22",X"95",X"0e",
X"7d",X"93",X"5f",X"7c",X"9a",X"57",X"2a",X"8f",
X"0e",X"19",X"22",X"8f",X"0e",X"c9",X"cd",X"47",
X"09",X"c9",X"cd",X"ed",X"0b",X"c4",X"da",X"0c",
X"7d",X"b7",X"ca",X"ae",X"08",X"fe",X"02",X"c4",
X"da",X"0c",X"c3",X"ae",X"08",X"cd",X"ed",X"0b",
X"c4",X"da",X"0c",X"7d",X"0f",X"dc",X"da",X"0c",
X"17",X"fe",X"08",X"d4",X"da",X"0c",X"07",X"17",
X"17",X"47",X"1a",X"80",X"fe",X"76",X"cc",X"da",
X"0c",X"c3",X"86",X"08",X"cd",X"ed",X"0b",X"c4",
X"da",X"0c",X"7d",X"fe",X"08",X"d4",X"da",X"0c",
X"1a",X"fe",X"40",X"ca",X"da",X"08",X"fe",X"c7",
X"7d",X"ca",X"ae",X"08",X"fa",X"b1",X"08",X"c3",
X"ae",X"08",X"29",X"29",X"29",X"85",X"12",X"cd",
X"18",X"09",X"cd",X"f0",X"0b",X"c4",X"da",X"0c",
X"7d",X"fe",X"08",X"d4",X"da",X"0c",X"c3",X"b1",
X"08",X"fe",X"06",X"cc",X"06",X"09",X"cd",X"47",
X"09",X"cd",X"ed",X"0b",X"3c",X"fe",X"02",X"d4",
X"f3",X"0c",X"7d",X"c3",X"86",X"08",X"cd",X"ed",
X"0b",X"c4",X"da",X"0c",X"7d",X"fe",X"08",X"d4",
X"da",X"0c",X"29",X"29",X"29",X"1a",X"85",X"5f",
X"2a",X"99",X"0e",X"7e",X"fe",X"2c",X"23",X"22",
X"99",X"0e",X"c2",X"e3",X"0c",X"7b",X"c9",X"fe",
X"01",X"c2",X"37",X"09",X"cd",X"06",X"09",X"e6",
X"08",X"c4",X"da",X"0c",X"7b",X"e6",X"f7",X"cd",
X"47",X"09",X"cd",X"ed",X"0b",X"7d",X"54",X"cd",
X"47",X"09",X"7a",X"c3",X"86",X"08",X"c9",X"2a",
X"8f",X"0e",X"77",X"23",X"22",X"8f",X"0e",X"2a",
X"a1",X"0e",X"23",X"cd",X"8c",X"02",X"22",X"a1",
X"0e",X"c9",X"3a",X"97",X"0e",X"b7",X"c2",X"69",
X"00",X"3e",X"01",X"c3",X"d3",X"06",X"2a",X"99",
X"0e",X"7e",X"fe",X"20",X"c0",X"23",X"22",X"99",
X"0e",X"c3",X"69",X"09",X"21",X"82",X"0e",X"22",
X"77",X"0e",X"06",X"02",X"cd",X"a9",X"0a",X"c9",
X"6f",X"72",X"67",X"00",X"00",X"65",X"71",X"75",
X"00",X"01",X"64",X"62",X"00",X"00",X"ff",X"64",
X"73",X"00",X"00",X"03",X"64",X"77",X"00",X"00",
X"05",X"65",X"6e",X"64",X"00",X"06",X"00",X"68",
X"6c",X"74",X"76",X"72",X"6c",X"63",X"07",X"72",
X"72",X"63",X"0f",X"72",X"61",X"6c",X"17",X"72",
X"61",X"72",X"1f",X"72",X"65",X"74",X"c9",X"63",
X"6d",X"61",X"2f",X"73",X"74",X"63",X"37",X"64",
X"61",X"61",X"27",X"63",X"6d",X"63",X"3f",X"65",
X"69",X"00",X"fb",X"64",X"69",X"00",X"f3",X"6e",
X"6f",X"70",X"00",X"00",X"78",X"63",X"68",X"67",
X"eb",X"78",X"74",X"68",X"6c",X"e3",X"73",X"70",
X"68",X"6c",X"f9",X"70",X"63",X"68",X"6c",X"e9",
X"00",X"73",X"74",X"61",X"78",X"02",X"6c",X"64",
X"61",X"78",X"0a",X"00",X"70",X"75",X"73",X"68",
X"c5",X"70",X"6f",X"70",X"00",X"c1",X"69",X"6e",
X"78",X"00",X"03",X"64",X"63",X"78",X"00",X"0b",
X"64",X"61",X"64",X"00",X"09",X"00",X"69",X"6e",
X"72",X"04",X"64",X"63",X"72",X"05",X"6d",X"6f",
X"76",X"40",X"61",X"64",X"64",X"80",X"61",X"64",
X"63",X"88",X"73",X"75",X"62",X"90",X"73",X"62",
X"62",X"98",X"61",X"6e",X"61",X"a0",X"78",X"72",
X"61",X"a8",X"6f",X"72",X"61",X"b0",X"63",X"6d",
X"70",X"b8",X"72",X"73",X"74",X"c7",X"00",X"61",
X"64",X"69",X"c6",X"61",X"63",X"69",X"ce",X"73",
X"75",X"69",X"d6",X"73",X"62",X"69",X"de",X"61",
X"6e",X"69",X"e6",X"78",X"72",X"69",X"ee",X"6f",
X"72",X"69",X"f6",X"63",X"70",X"69",X"fe",X"69",
X"6e",X"00",X"db",X"6f",X"75",X"74",X"d3",X"6d",
X"76",X"69",X"06",X"00",X"6a",X"6d",X"70",X"00",
X"c3",X"63",X"61",X"6c",X"6c",X"cd",X"6c",X"78",
X"69",X"00",X"01",X"6c",X"64",X"61",X"00",X"3a",
X"73",X"74",X"61",X"00",X"32",X"73",X"68",X"6c",
X"64",X"22",X"6c",X"68",X"6c",X"64",X"2a",X"00",
X"6e",X"7a",X"00",X"7a",X"00",X"08",X"6e",X"63",
X"10",X"63",X"00",X"18",X"70",X"6f",X"20",X"70",
X"65",X"28",X"70",X"00",X"30",X"6d",X"00",X"38",
X"00",X"2a",X"77",X"0e",X"1a",X"b7",X"ca",X"bb",
X"0a",X"48",X"cd",X"56",X"01",X"1a",X"c8",X"13",
X"c3",X"a9",X"0a",X"3c",X"13",X"c9",X"21",X"81",
X"0e",X"22",X"77",X"0e",X"11",X"80",X"09",X"06",
X"04",X"cd",X"a9",X"0a",X"ca",X"67",X"0b",X"05",
X"cd",X"a9",X"0a",X"ca",X"da",X"0a",X"04",X"cd",
X"a9",X"0a",X"21",X"86",X"08",X"0e",X"01",X"ca",
X"3a",X"0b",X"cd",X"a9",X"0a",X"21",X"8a",X"08",
X"ca",X"dd",X"0a",X"cd",X"a9",X"0a",X"21",X"9d",
X"08",X"ca",X"dd",X"0a",X"05",X"cd",X"a9",X"0a",
X"21",X"bc",X"08",X"ca",X"dd",X"0a",X"cd",X"a9",
X"0a",X"21",X"f1",X"08",X"0e",X"02",X"ca",X"3a",
X"0b",X"04",X"cd",X"a9",X"0a",X"ca",X"35",X"0b",
X"cd",X"74",X"09",X"c2",X"5f",X"0b",X"c6",X"c0",
X"57",X"06",X"03",X"3a",X"81",X"0e",X"4f",X"fe",
X"72",X"7a",X"ca",X"da",X"0a",X"79",X"14",X"14",
X"fe",X"6a",X"ca",X"34",X"0b",X"fe",X"63",X"c2",
X"5f",X"0b",X"14",X"14",X"7a",X"21",X"27",X"09",
X"0e",X"03",X"32",X"a0",X"0e",X"3e",X"81",X"80",
X"5f",X"3e",X"0e",X"ce",X"00",X"57",X"1a",X"b7",
X"c2",X"5f",X"0b",X"3a",X"97",X"0e",X"06",X"00",
X"eb",X"2a",X"95",X"0e",X"09",X"22",X"95",X"0e",
X"b7",X"c8",X"3a",X"a0",X"0e",X"eb",X"e9",X"21",
X"06",X"0d",X"0e",X"03",X"c3",X"4b",X"0b",X"21",
X"85",X"0e",X"7e",X"b7",X"c2",X"5f",X"0b",X"3a",
X"97",X"0e",X"b7",X"ca",X"9d",X"07",X"c3",X"21",
X"08",X"fe",X"61",X"d8",X"fe",X"7b",X"3f",X"d8",
X"cd",X"ce",X"0b",X"21",X"81",X"0e",X"22",X"77",
X"0e",X"05",X"c2",X"9d",X"0b",X"04",X"11",X"b9",
X"0b",X"cd",X"a9",X"0a",X"c2",X"9d",X"0b",X"6f",
X"26",X"00",X"c3",X"b3",X"0b",X"3a",X"9b",X"0e",
X"47",X"11",X"1d",X"0f",X"b7",X"ca",X"b6",X"0b",
X"3e",X"05",X"32",X"98",X"0e",X"cd",X"3f",X"01",
X"4c",X"65",X"69",X"37",X"3f",X"c9",X"3c",X"b7",
X"c9",X"61",X"07",X"62",X"00",X"63",X"01",X"64",
X"02",X"65",X"03",X"68",X"04",X"6c",X"05",X"6d",
X"06",X"70",X"06",X"73",X"06",X"00",X"06",X"00",
X"12",X"04",X"78",X"fe",X"0b",X"d0",X"13",X"23",
X"22",X"99",X"0e",X"7e",X"fe",X"30",X"d8",X"fe",
X"3a",X"da",X"d0",X"0b",X"fe",X"61",X"d8",X"fe",
X"7b",X"da",X"d0",X"0b",X"c9",X"cd",X"66",X"09",
X"21",X"00",X"00",X"22",X"9d",X"0e",X"24",X"22",
X"9e",X"0e",X"2a",X"99",X"0e",X"2b",X"cd",X"69",
X"01",X"32",X"9c",X"0e",X"23",X"7e",X"fe",X"21",
X"da",X"ac",X"0c",X"fe",X"2c",X"ca",X"ac",X"0c",
X"fe",X"2b",X"ca",X"1d",X"0c",X"fe",X"2d",X"c2",
X"2d",X"0c",X"32",X"9c",X"0e",X"3a",X"9f",X"0e",
X"fe",X"02",X"ca",X"e3",X"0c",X"3e",X"02",X"32",
X"9f",X"0e",X"c3",X"04",X"0c",X"4f",X"3a",X"9f",
X"0e",X"b7",X"ca",X"e3",X"0c",X"79",X"fe",X"24",
X"c2",X"45",X"0c",X"23",X"22",X"99",X"0e",X"2a",
X"95",X"0e",X"c3",X"81",X"0c",X"fe",X"27",X"c2",
X"71",X"0c",X"11",X"00",X"00",X"0e",X"03",X"23",
X"22",X"99",X"0e",X"7e",X"fe",X"0d",X"ca",X"01",
X"0d",X"fe",X"27",X"c2",X"68",X"0c",X"23",X"22",
X"99",X"0e",X"7e",X"fe",X"27",X"c2",X"82",X"0c",
X"0d",X"ca",X"01",X"0d",X"53",X"5f",X"c3",X"4f",
X"0c",X"fe",X"30",X"da",X"01",X"0d",X"fe",X"3a",
X"d2",X"a0",X"0c",X"cd",X"bc",X"0c",X"da",X"01",
X"0d",X"eb",X"2a",X"9d",X"0e",X"af",X"32",X"9f",
X"0e",X"3a",X"9c",X"0e",X"b7",X"c2",X"97",X"0c",
X"19",X"22",X"9d",X"0e",X"c3",X"fa",X"0b",X"7d",
X"93",X"6f",X"7c",X"9a",X"67",X"c3",X"91",X"0c",
X"cd",X"79",X"0b",X"ca",X"81",X"0c",X"da",X"01",
X"0d",X"c3",X"ee",X"0c",X"3a",X"9f",X"0e",X"b7",
X"c2",X"e3",X"0c",X"2a",X"9d",X"0e",X"7c",X"11",
X"a0",X"0e",X"b7",X"c9",X"cd",X"ce",X"0b",X"1b",
X"1a",X"01",X"81",X"0e",X"fe",X"68",X"ca",X"d4",
X"0c",X"fe",X"64",X"c2",X"d0",X"0c",X"af",X"12",
X"cd",X"04",X"02",X"c9",X"af",X"12",X"cd",X"1e",
X"02",X"c9",X"3e",X"72",X"21",X"00",X"00",X"32",
X"b5",X"0e",X"c9",X"3e",X"73",X"32",X"b5",X"0e",
X"21",X"00",X"00",X"c3",X"b6",X"0c",X"3e",X"75",
X"c3",X"e5",X"0c",X"3e",X"76",X"c3",X"dc",X"0c",
X"3e",X"6d",X"32",X"b5",X"0e",X"cd",X"2b",X"07",
X"c9",X"3e",X"61",X"c3",X"e5",X"0c",X"3e",X"6f",
X"32",X"b5",X"0e",X"3a",X"97",X"0e",X"b7",X"c8",
X"0e",X"03",X"af",X"cd",X"47",X"09",X"0d",X"c2",
X"12",X"0d",X"c9",X"3e",X"6c",X"c3",X"08",X"0d",
X"3e",X"64",X"32",X"b5",X"0e",X"cd",X"1e",X"07",
X"c3",X"77",X"07",X"3a",X"81",X"0e",X"b7",X"ca",
X"6d",X"0d",X"16",X"08",X"21",X"0f",X"0e",X"7e",
X"23",X"46",X"b0",X"ca",X"47",X"0d",X"23",X"23",
X"15",X"c2",X"37",X"0d",X"c3",X"5d",X"04",X"2b",
X"eb",X"2a",X"8d",X"0e",X"eb",X"7a",X"b7",X"c2",
X"58",X"0d",X"7b",X"fe",X"0b",X"da",X"5d",X"04",
X"72",X"23",X"73",X"23",X"1a",X"77",X"3e",X"cf",
X"12",X"3e",X"c3",X"32",X"08",X"00",X"21",X"87",
X"0d",X"22",X"09",X"00",X"c9",X"21",X"0f",X"0e",
X"06",X"08",X"af",X"56",X"77",X"23",X"5e",X"77",
X"23",X"46",X"23",X"7a",X"b3",X"ca",X"82",X"0d",
X"78",X"12",X"05",X"c2",X"72",X"0d",X"c9",X"22",
X"0b",X"0e",X"e1",X"2b",X"22",X"0d",X"0e",X"f5",
X"e1",X"22",X"03",X"0e",X"21",X"00",X"00",X"39",
X"31",X"0b",X"0e",X"e5",X"d5",X"c5",X"2f",X"31",
X"b5",X"0e",X"2a",X"0d",X"0e",X"eb",X"21",X"0f",
X"0e",X"06",X"08",X"7e",X"23",X"ba",X"c2",X"b6",
X"0d",X"7e",X"bb",X"ca",X"bf",X"0d",X"23",X"23",
X"05",X"ca",X"5d",X"04",X"c3",X"ab",X"0d",X"23",
X"7e",X"12",X"af",X"2b",X"77",X"2b",X"77",X"cd",
X"11",X"01",X"3a",X"0e",X"0e",X"cd",X"3d",X"02",
X"3a",X"0d",X"0e",X"cd",X"3d",X"02",X"21",X"df",
X"0d",X"cd",X"7d",X"02",X"c3",X"69",X"00",X"20",
X"62",X"72",X"65",X"61",X"6b",X"0d",X"3a",X"81",
X"0e",X"b7",X"ca",X"f3",X"0d",X"2a",X"8d",X"0e",
X"22",X"0d",X"0e",X"31",X"03",X"0e",X"f1",X"c1",
X"d1",X"e1",X"f9",X"2a",X"0d",X"0e",X"e5",X"2a",
X"0b",X"0e",X"c9",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",
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


-- @end_rom
);


-- i/o signals
signal data_io_in : 			std_logic_vector(7 downto 0);
signal data_mem_in : 			std_logic_vector(7 downto 0);



-- Clock & reset signals
signal clk_1hz :          std_logic;
signal counter_1hz : 			integer;
signal reset : 						std_logic;


begin


-- Program memory (it's RAM really)
rom_addr <= addr(11 downto 0);
process(clk_50MHz)
begin
  if (clk_50MHz'event and clk_50MHz='1') then
    data_mem_in <= rom(conv_integer(rom_addr));
    if wr = '1' then
      rom(conv_integer(rom_addr)) <= data_out;
    end if;  
  end if;
end process;


process(clk_50MHz)
begin
  if (clk_50MHz'event and clk_50MHz='1') then
    if reset='1' then
      reg_h <= "00000000";
      reg_l <= "00000000";
    else
      if io_write='1' then
        if addr(7 downto 0)=X"40" then
          reg_l <= data_out;
        end if;
        if addr(7 downto 0)=X"f1" then -- FIXME
          reg_h <= data_out;
        end if;
      end if;
    end if;
  end if;
end process;


-- CPU control signals
intr <= '0';

-- CPU instance
cpu: light8080 port map(
		clk => clk_50MHz,
		reset => reset,
		vma => vma,
		rd => rd,
		wr => wr,
		io => io,
		addr_out => addr, 
		data_in => data_in,
		data_out => data_out,
		intr => intr,
		inte => inte,
		inta => inta,
		halt => halt
);


process(clk_50MHz)
begin
	if clk_50MHz'event and clk_50MHz = '1' then
		if reset = '1' then
			io_q <= '0';	
			rd_q <= '0';				
			io_port <= X"00";	
			data_io_out <= X"00";
		else
			io_q <= io;		
			rd_q <= rd;				
			io_port <= addr(7 downto 0);			
			data_io_out <= data_out;
		end if;
	end if;
end process;

red_leds(0) <= halt;
red_leds(1) <= inte;
red_leds(2) <= vma;
red_leds(3) <= rd;
red_leds(4) <= wr;

red_leds(9) <= tx_rdy;
red_leds(8) <= rx_rdy;
red_leds(7 downto 5) <= "000";

--##### Input ports ###########################################################

-- mem vs. io input mux
data_in <= data_io_in when io_q='1' else data_mem_in;

-- io read enable (for async io ports; data read in cycle following io='1')
io_read <= '1' when io_q='1' and rd_q='1' else '0';

-- io write enable (for sync io ports; dara written in cycle following io='1') 
io_write <= '1' when io='1' and wr='1' else '0';

-- read/write signals for rs232 modules
read_rx <=  '1' when io_read='1' and addr(7 downto 0)=X"21" else '0';
write_tx <= '1' when io_write='1' and addr(7 downto 0)=X"21" else '0';

-- synchronized input port mux (using registered port address)
with io_port select
	data_io_in <= rs232_status	 				when X"20",
								rs232_data_rx					when X"21",
								switches(7 downto 0) 	when others; -- X"40"



--##############################################################################
-- terasIC Cyclone II STARTER KIT BOARD
--##############################################################################

--##############################################################################
-- FLASH
--##############################################################################

  -- Flash is unused
	flash_addr <= "000000000000" & switches;
	flash_we <= '1';
	flash_oe <= '1';
	flash_reset <= '1';
	--green_leds <= flash_data;

--##############################################################################
-- RESET, CLOCK
--##############################################################################

-- Use button 3 as reset
reset <= not buttons(3);

-- Generate a 1-Hz clock for visual reference 
process(clk_50MHz)
begin
  if clk_50MHz'event and clk_50MHz='1' then
    if buttons(3) = '1' then
      clk_1hz <= '0';
      counter_1hz <= 0;
    else
      if buttons(2) = '0' then
        if counter_1hz = 25000000 then
          counter_1hz <= 0;
          clk_1hz <= not clk_1hz;
        else
          counter_1hz <= counter_1hz + 1;
        end if;
      end if;
    end if;
  end if;
end process;


--##############################################################################
-- LEDS, SWITCHES
--##############################################################################

green_leds <= reg_l; 

--##############################################################################
-- SERIAL
--##############################################################################

--txd <= rxd; -- loopback rs-232

serial_rx : rs232_rx port map(
		rxd => rxd,
		data_rx => rs232_data_rx,
		rx_rdy => rx_rdy,
		read_rx => read_rx,
		clk => clk_50MHz,
		reset => reset 
	);

serial_tx : rs232_tx port map(
		clk => clk_50MHz,
		reset => reset,
		rdy => tx_rdy,
		load => write_tx,
		data_i => data_out,
		txd => txd
	);

rs232_status <= (not tx_rdy) & "000000" & (not rx_rdy);


end demo;
