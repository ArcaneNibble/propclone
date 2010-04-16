----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:03:34 04/15/2010 
-- Design Name: 
-- Module Name:    alu - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.numeric_std.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

package alu_common is
	type alu_opcodes is (
		add,
		addx,
		sub,
		subx,
		andop,
		orop,
		xorop,
		absop,
		neg
	);
end alu_common;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use work.alu_common.all;

entity alu is
	port(
		opcode	: in alu_opcodes;
	
		a		: in std_logic_vector(31 downto 0);
		b		: in std_logic_vector(31 downto 0);
		
		result	: out std_logic_vector(31 downto 0);
		
		cin		: in std_logic;
		zin		: in std_logic;
		
		cout	: out std_logic;
		zout	: out std_logic
	);
end alu;

architecture Behavioral of alu is
	signal aext			: std_logic_vector(32 downto 0);
	signal bext			: std_logic_vector(32 downto 0);
	
	signal outext		: std_logic_vector(32 downto 0);
	
	signal parityin		: std_logic_vector(31 downto 0);
	signal paritytmp	: std_logic_vector(30 downto 0);
	signal paritybit	: std_logic;
	
	signal result0_32	: std_logic;
	signal result0_33	: std_logic;
	
	signal a0			: std_logic;
	signal b0			: std_logic;
begin
	aext <= '0' & a;
	bext <= '0' & b;
	result <= outext(31 downto 0);
	parityin <= outext(31 downto 0);
	
	paritytmp(0) <= parityin(0) xor parityin(1);
	parity:	for i in 2 to 31 generate
		paritytmp(i-1) <= parityin(i) xor paritytmp(i-2);
	end generate parity;
	paritybit <= paritytmp(30);
	
	result0_32 <= '1' when outext(31 downto 0)=X"00000000" else '0';
	result0_33 <= '1' when outext=('0' & X"00000000") else '0';
	a0 <= '1' when a=X"00000000" else '0';
	b0 <= '1' when b=X"00000000" else '0';
	
	flags:	process(opcode, aext, bext, cin, zin, outext, result0_32, result0_33, paritybit, a0, b0)
	begin
		case opcode is
			when add|sub =>
				cout <= outext(32);
				zout <= result0_32;
				
			when addx|subx =>
				cout <= outext(32);
				zout <= result0_32 and zin;
			
			when andop|orop|xorop =>
				cout <= paritybit;
				zout <= result0_32;
			
			when absop|neg =>
				cout <= aext(31);
				zout <= a0;
			
			when others =>
				cout <= '0';
				zout <= '0';
		end case;
	end process;
	
	value:	process(aext, bext, cin, zin, opcode)
	begin
		case opcode is
			when add =>
				outext <= aext + bext;
				
			when addx =>
				if cin='1' then
					outext <= aext + bext + ('0' & X"00000001");
				else
					outext <= aext + bext;
				end if;
				
			when sub =>
				outext <= aext - bext;
				
			when subx =>
				if cin='1' then
					outext <= aext - bext - ('0' & X"00000001");
				else
					outext <= aext - bext;
				end if;
			
			when andop =>
				outext <= aext and bext;
			
			when orop =>
				outext <= aext or bext;
			
			when xorop =>
				outext <= aext xor bext;
			
			when absop =>
				outext(32) <= '0';
				outext(31 downto 0) <= (abs(signed(aext(31 downto 0))));
			
			when neg =>
				outext(32) <= '0';
				outext(31 downto 0) <= (-(signed(aext(31 downto 0))));
		
			when others =>
				outext <= (others => '0');
		end case;
	end process;
end Behavioral;

