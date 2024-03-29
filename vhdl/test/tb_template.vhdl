--------------------------------------------------------------------------------
-- Light8080 simulation test bench.
--------------------------------------------------------------------------------
-- Source for the 8080 program is in asm\@PROGNAME@.asm
-------------------------------------------------------------------------------- 
-- 
-- This test bench provides a simulated CPU system to test programs. This test 
-- bench does not do any assertions or checks, all assertions are left to the 
-- software.
--
-- The simulated environment has 2KB of RAM, mirror-mapped to all the memory 
-- map of the 8080, initialized with the test program object code. See the perl
-- script 'util\hexconv.pl' and BAT files in the asm directory.
--
-- Besides, it provides some means to trigger hardware irq from software, 
-- including the specification of the instructions fed to the CPU as interrupt
-- vectors during inta cycles.
--
-- We will simulate 8 possible irq sources. The software can trigger any one of 
-- them by writing at registers 0x010 and 0x011. Register 0x010 holds the irq
-- source to be triggered (0 to 7) and register 0x011 holds the number of clock
-- cycles that will elapse from the end of the instruction that writes to the
-- register to the assertion of intr. 
--
-- When the interrupt is acknowledged and inta is asserted, the test bench reads
-- the value at register 0x010 as the irq source, and feeds an instruction to 
-- the CPU starting from the RAM address 0040h+source*4.
-- That is, address range 0040h-005fh is reserved for the simulated 'interrupt
-- vectors', a total of 4 bytes for each of the 8 sources. This allows the 
-- software to easily test different interrupt vectors without any hand 
-- assembly. All of this is strictly simulation-only stuff.
--
--
-- Upon completion, the software must write a value to register 0x020. Writing 
-- a 0x055 means 'success', writing a 0x0aa means 'failure'. Success and 
-- failure conditions are defined by the software.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.ALL;

entity light8080_@PROGNAME@ is
end entity light8080_@PROGNAME@;

architecture behavior of light8080_@PROGNAME@ is

--------------------------------------------------------------------------------
-- Simulation parameters

-- T: simulated clock period
constant T : time := 100 ns;

-- MAX_SIM_LENGTH: maximum simulation time
constant MAX_SIM_LENGTH : time := T*7000; -- enough for the tb0


--------------------------------------------------------------------------------

	-- Component Declaration for the Unit Under Test (UUT)
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
    fetch :     out std_logic;
    data_in :   in std_logic_vector(7 downto 0);  
    data_out :  out std_logic_vector(7 downto 0);
    
    clk :       in std_logic;
    reset :     in std_logic );
end component;


signal data_i :           std_logic_vector(7 downto 0) := (others=>'0');
signal vma_o  :           std_logic;
signal rd_o :             std_logic;
signal wr_o :             std_logic;
signal io_o :             std_logic;
signal data_o :           std_logic_vector(7 downto 0);
signal data_mem :         std_logic_vector(7 downto 0);
signal addr_o :           std_logic_vector(15 downto 0);
signal fetch_o :          std_logic;
signal inta_o :           std_logic;
signal inte_o :           std_logic;
signal intr_i :           std_logic := '0';
signal halt_o :           std_logic;
                          
signal reset :            std_logic := '0';
signal clk :              std_logic := '1';
signal done :             std_logic := '0';

type t_rom is array(0 to 2047) of std_logic_vector(7 downto 0);

signal rom : t_rom := (

--@rom_data

);

signal irq_vector_byte:   std_logic_vector(7 downto 0);
signal irq_source :       integer range 0 to 7;
signal cycles_to_intr :   integer range -10 to 255;
signal int_vector_index : integer range 0 to 3;
signal addr_vector_table: integer range 0 to 65535;

begin

	-- Instantiate the Unit Under Test (UUT)
	uut: light8080 PORT MAP(
		clk => clk,
		reset => reset,
		vma => vma_o,
		rd => rd_o,
		wr => wr_o,
		io => io_o,
		fetch => fetch_o,
		addr_out => addr_o, 
		data_in => data_i,
		data_out => data_o,
		
		intr => intr_i,
		inte => inte_o,
		inta => inta_o,
		halt => halt_o
	);


-- clock: run clock until test is done
clock:
process(done, clk)
begin
	if done = '0' then
		clk <= not clk after T/2;
	end if;
end process clock;


-- Drive reset and done 
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
	wait for (MAX_SIM_LENGTH - T*1.5);

	-- Maximum sim time elapsed, assume the program ran away and
	-- stop the clk process asserting 'done' (which will stop the simulation)
	done <= '1';
	
  assert (done = '1') 
	report "Test timed out."
	severity failure;
	
	wait;
end process main_test;


-- Synchronous RAM; 2KB mirrored everywhere
synchronous_ram:
process(clk)
begin
  if (clk'event and clk='1') then
    data_mem <= rom(conv_integer(addr_o(10 downto 0)));
    if wr_o = '1' and addr_o(15 downto 11)="00000" then
      rom(conv_integer(addr_o(10 downto 0))) <= data_o;
    end if;  
  end if;
end process synchronous_ram;


irq_trigger_register:
process(clk)
begin
  if (clk'event and clk='1') then
    if reset='1' then
      cycles_to_intr <= -10; -- meaning no interrupt pending
      intr_i <= '0';
    else
      if io_o='1' and wr_o='1' and addr_o(7 downto 0)=X"11" then
        cycles_to_intr <= conv_integer(data_o) + 1;
      else
        if cycles_to_intr >= 0 then
          cycles_to_intr <= cycles_to_intr - 1;
        end if;
        if cycles_to_intr = 0 then
          intr_i <= '1';
        else
          intr_i <= '0';
        end if;
      end if;
    end if;
  end if;
end process irq_trigger_register;


irq_source_register:
process(clk)
begin
  if (clk'event and clk='1') then
    if reset='1' then
      irq_source <= 0;
    else
      if io_o='1' and wr_o='1' and addr_o(7 downto 0)=X"10" then
        irq_source <= conv_integer(data_o(2 downto 0));
      end if;
    end if;
  end if;
end process irq_source_register;


-- 'interrupt vector' logic.
irq_vector_table:
process(clk)
begin
  if (clk'event and clk='1') then
    if vma_o = '1' and rd_o='1' then
      if inta_o = '1' then
        int_vector_index <= int_vector_index + 1;
      else
        int_vector_index <= 0;
      end if;
    end if;
    -- this is the address of the byte we'll feed to the CPU
    addr_vector_table <= 64+irq_source*4+int_vector_index;
  end if;
end process irq_vector_table;
irq_vector_byte <= rom(addr_vector_table);

data_i <= data_mem when inta_o='0' else irq_vector_byte;


test_outcome_register:
process(clk)
variable outcome : std_logic_vector(7 downto 0);
begin
  if (clk'event and clk='1') then
    if io_o='1' and wr_o='1' and addr_o(7 downto 0)=X"20" then
    assert (data_o /= X"55") report "Software reports SUCCESS" severity failure;
    assert (data_o /= X"aa") report "Software reports FAILURE" severity failure;
    assert ((data_o = X"aa") or (data_o = X"55")) 
    report "Software reports unexpected outcome value." 
    severity failure;
    end if;
  end if;
end process test_outcome_register;


end;
