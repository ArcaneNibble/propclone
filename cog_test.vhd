
--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:45:23 04/11/2010
-- Design Name:   propcog
-- Module Name:   C:/Users/main/fpga/prop_clone_test/cog_test.vhd
-- Project Name:  prop_clone_test
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: propcog
--
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends 
-- that these types always be used for the top-level I/O of a design in order 
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.ALL;

ENTITY cog_test_vhd IS
END cog_test_vhd;

ARCHITECTURE behavior OF cog_test_vhd IS 

	-- Component Declaration for the Unit Under Test (UUT)
	COMPONENT propcog
	PORT(
		clk : IN std_logic;
		rst : IN std_logic;
		ina : IN std_logic_vector(31 downto 0);
		inb : IN std_logic_vector(31 downto 0);
		cnt : IN std_logic_vector(31 downto 0);
		par : IN std_logic_vector(13 downto 0);
		run : IN std_logic;          
		outa : OUT std_logic_vector(31 downto 0);
		outb : OUT std_logic_vector(31 downto 0);
		dira : OUT std_logic_vector(31 downto 0);
		dirb : OUT std_logic_vector(31 downto 0)
		);
	END COMPONENT;

	--Inputs
	SIGNAL clk :  std_logic := '0';
	SIGNAL rst :  std_logic := '0';
	SIGNAL run :  std_logic := '1';
	SIGNAL ina :  std_logic_vector(31 downto 0) := (others=>'0');
	SIGNAL inb :  std_logic_vector(31 downto 0) := (others=>'0');
	SIGNAL cnt :  std_logic_vector(31 downto 0) := (others=>'0');
	SIGNAL par :  std_logic_vector(13 downto 0) := (others=>'0');

	--Outputs
	SIGNAL outa :  std_logic_vector(31 downto 0);
	SIGNAL outb :  std_logic_vector(31 downto 0);
	SIGNAL dira :  std_logic_vector(31 downto 0);
	SIGNAL dirb :  std_logic_vector(31 downto 0);

BEGIN

	-- Instantiate the Unit Under Test (UUT)
	uut: propcog PORT MAP(
		clk => clk,
		rst => rst,
		ina => ina,
		inb => inb,
		outa => outa,
		outb => outb,
		dira => dira,
		dirb => dirb,
		cnt => cnt,
		par => par,
		run => run
	);

	process is
	begin
		clk <= '1' after 0 ns, '0' after 10 ns;
		wait for 20 ns;
	end process;

	process is
	begin
		rst <= '1' after 0 ns, '0' after 60 ns;
		wait;
	end process;

END;
