----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:55:20 04/11/2010 
-- Design Name: 
-- Module Name:    propcog - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

use work.alu_common.all;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity propcog is
	port(
		clk		: in std_logic;
		rst		: in std_logic;
		
		ina		: in std_logic_vector(31 downto 0);
		inb		: in std_logic_vector(31 downto 0);
		outa	: out std_logic_vector(31 downto 0);
		outb	: out std_logic_vector(31 downto 0);
		dira	: out std_logic_vector(31 downto 0);
		dirb	: out std_logic_vector(31 downto 0);
		
		cnt		: in std_logic_vector(31 downto 0);
		par		: in std_logic_vector(13 downto 0);
		
		run		: in std_logic
	);
end propcog;

architecture Behavioral of propcog is
	constant SIMULATION	: boolean	:= false
	-- synthesis translate_off
		or true
	-- synthesis translate_on
		;
	component alu is
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
	end component;
	component cogram
		port (
		clka: IN std_logic;
		dina: IN std_logic_VECTOR(31 downto 0);
		addra: IN std_logic_VECTOR(8 downto 0);
		wea: IN std_logic_VECTOR(0 downto 0);
		douta: OUT std_logic_VECTOR(31 downto 0);
		clkb: IN std_logic;
		dinb: IN std_logic_VECTOR(31 downto 0);
		addrb: IN std_logic_VECTOR(8 downto 0);
		web: IN std_logic_VECTOR(0 downto 0);
		doutb: OUT std_logic_VECTOR(31 downto 0));
	end component;
	-- synthesis translate_off
	component fakecogram
		port (
		clka: IN std_logic;
		dina: IN std_logic_VECTOR(31 downto 0);
		addra: IN std_logic_VECTOR(8 downto 0);
		wea: IN std_logic_VECTOR(0 downto 0);
		douta: OUT std_logic_VECTOR(31 downto 0);
		clkb: IN std_logic;
		dinb: IN std_logic_VECTOR(31 downto 0);
		addrb: IN std_logic_VECTOR(8 downto 0);
		web: IN std_logic_VECTOR(0 downto 0);
		doutb: OUT std_logic_VECTOR(31 downto 0));
	end component;
	-- synthesis translate_on
	
	signal addra	: std_logic_vector(8 downto 0);
	signal addrb	: std_logic_vector(8 downto 0);
	signal douta	: std_logic_vector(31 downto 0);
	signal doutb	: std_logic_vector(31 downto 0);
	signal dina		: std_logic_vector(31 downto 0);
	signal wea		: std_logic;
	
	signal pc		: std_logic_vector(8 downto 0);
	signal z		: std_logic;
	signal c		: std_logic;
	
	type fetch_decode_branch_state_type is (
		opfetch,
		opfetchwait,
		op_decode_branch_arg,
		argwait
	);
	
	signal fetch_decode_branch_state	: fetch_decode_branch_state_type;
	
	signal pc_next						: std_logic_vector(8 downto 0);
	signal pc_branch_target				: std_logic_vector(8 downto 0);
	signal old_pc_next					: std_logic_vector(8 downto 0);
	signal use_branch_target			: std_logic;
	signal use_branch_target_intent		: std_logic;
	signal use_old_pc					: std_logic;
	
	signal src_value					: std_logic_vector(31 downto 0);
	signal src_reg						: std_logic_vector(8 downto 0);
	signal imm_value					: std_logic_vector(31 downto 0);
	signal dst_value					: std_logic_vector(31 downto 0);
	signal dst_reg						: std_logic_vector(8 downto 0);
	
	signal instr						: std_logic_vector(5 downto 0);
	signal cond							: std_logic_vector(3 downto 0);
	signal cond_met						: std_logic;
	signal wr							: std_logic;
	signal wz							: std_logic;
	signal wc							: std_logic;
	signal imm							: std_logic;
	
	signal addra_fetch					: std_logic_vector(8 downto 0);
	
	type execute_writeback_state_type is (
		execute,
		execute2,
		execute3,
		writeback
	);
	
	signal execute_writeback_state		: execute_writeback_state_type;
	
	signal result						: std_logic_vector(31 downto 0);
	signal resultz						: std_logic;
	signal resultc						: std_logic;
	signal throw_away_opcode			: std_logic;
	
	signal dst_reg_copy					: std_logic_vector(8 downto 0);
	
	signal instr_copy					: std_logic_vector(5 downto 0);
	
	signal real_src						: std_logic_vector(31 downto 0);
	signal real_dst						: std_logic_vector(31 downto 0);
	signal real_wr						: std_logic;
	signal real_wc						: std_logic;
	signal real_wz						: std_logic;
	
	signal wea_execute					: std_logic;
	signal addra_execute				: std_logic_vector(8 downto 0);
	
	--these help debugging by lining up the state with what is actually happening
	-- synthesis translate_off
	signal debug_fetch_state			: fetch_decode_branch_state_type;
	signal debug_execute_state			: execute_writeback_state_type;
	-- synthesis translate_on
	
	signal aluop						: alu_opcodes;
	signal alua							: std_logic_vector(31 downto 0);
	signal alub							: std_logic_vector(31 downto 0);
	signal aluresult					: std_logic_vector(31 downto 0);
	signal alucin						: std_logic;
	signal aluzin						: std_logic;
	signal alucout						: std_logic;
	signal aluzout						: std_logic;
	
	signal outa_reg						: std_logic_vector(31 downto 0);
	signal outb_reg						: std_logic_vector(31 downto 0);
	signal dira_reg						: std_logic_vector(31 downto 0);
	signal dirb_reg						: std_logic_vector(31 downto 0);
	
	signal use_special_register			: std_logic;
	signal special_reg					: std_logic_vector(31 downto 0);
begin
	propalu	: alu port map(
		opcode => aluop,
		a => alua,
		b => alub,
		result => aluresult,
		cin => alucin,
		zin => aluzin,
		cout => alucout,
		zout => aluzout
	);

	zzz: if SIMULATION generate
		-- synthesis translate_off
		cog_ram	: fakecogram port map(
			clka => clk,
			clkb => clk,
			
			addra => addra,
			addrb => addrb,
			
			douta => douta,
			doutb => doutb,
			
			dina => dina,
			dinb => X"00000000",
			
			wea(0) => wea,
			web(0) => '0'
		);
		-- synthesis translate_on
	end generate;
	zzzz: if not SIMULATION generate
		cog_ram	: cogram port map(
			clka => clk,
			clkb => clk,
			
			addra => addra,
			addrb => addrb,
			
			douta => douta,
			doutb => doutb,
			
			dina => dina,
			dinb => X"00000000",
			
			wea(0) => wea,
			web(0) => '0'
		);
	end generate;
	
	-- synthesis translate_off
	debug_states:	process(clk)
	begin
		if rising_edge(clk) then
			debug_fetch_state <= fetch_decode_branch_state;
			debug_execute_state <= execute_writeback_state;
		end if;
	end process;
	-- synthesis translate_on
	
	outa <= outa_reg;
	outb <= outb_reg;
	dira <= dira_reg;
	dirb <= dirb_reg;
	
	pc_next_calculator:	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				pc_next <= (others => '0');
			else
				pc_next <= pc + "000000001";
			end if;
		end if;
	end process;
	
	cond_checker:	process(cond,z,c)
	begin
		case cond is
			when "0000" =>	--IF_NEVER
				cond_met <= '0';
		
			when "0001" =>	--IF_NZ_AND_NC
				if (c='0') and (z='0') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "0010" =>	--IF_NC_AND_Z
				if (c='0') and (z='1') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "0011" =>	--IF_NC
				if c='0' then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "0100" =>	--IF_C_AND_NZ
				if (c='1') and (z='0') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "0101" =>	--IF_NZ
				if z='0' then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "0110" =>	--IF_C_NE_Z
				if c/=z then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "0111" =>	--IF_NC_OR_NZ
				if (c='0') or (z='0') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1000" =>	--IF_C_AND_Z
				if (c='1') and (z='1') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1001" =>	--IF_C_EQ_Z
				if c=z then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1010" =>	--IF_Z
				if z='1' then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1011" =>	--IF_NC_OR_Z
				if (c='0') or (z='1') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1100" =>	--IF_C
				if c='1' then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1101" =>	--IF_C_OR_NZ
				if (c='1') or (z='0') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1110" =>	--IF_C_OR_Z
				if (c='1') or (z='1') then
					cond_met <= '1';
				else
					cond_met <= '0';
				end if;
		
			when "1111" =>
				cond_met <= '1';
			
			when others => null;
		end case;
	end process;
	
	dst_value <= douta when use_special_register='0' else special_reg;
	src_value <= imm_value when imm='1' else doutb;
	pc_branch_target <= imm_value(8 downto 0) when imm='1' else doutb(8 downto 0);
	
	use_branch_target <= use_branch_target_intent and cond_met;
	
	pc_determine:	process(fetch_decode_branch_state, pc_next, pc_branch_target, old_pc_next, use_branch_target, use_old_pc,rst)
	begin
		if rst='1' then
			pc <= (others => '0');
		elsif fetch_decode_branch_state=opfetch then
			if use_old_pc='1' then
				pc <= old_pc_next;
			elsif use_branch_target='1' then
				pc <= pc_branch_target;
			else
				pc <= pc_next;
			end if;
		end if;
	end process;
	
	fetch_decode_branch:	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				fetch_decode_branch_state <= opfetch;
				
				imm <= '0';
				imm_value <= (others => '0');
				src_reg <= (others => '0');
				dst_reg <= (others => '0');
				
				instr <= (others => '0');
				cond <= (others => '0');
				wr <= '0';
				wz <= '0';
				wc <= '0';
				
				addra_fetch <= (others => '0');
				addrb <= (others => '0');
				
				use_branch_target_intent <= '0';
				
				use_special_register <= '0';
				special_reg <= (others => '0');
			else
				if run='1' then
					case fetch_decode_branch_state is
						when opfetch =>
							use_special_register <= '0';
							addra_fetch <= pc;
							fetch_decode_branch_state <= opfetchwait;
						
						when opfetchwait =>
							fetch_decode_branch_state <= op_decode_branch_arg;
						
						when op_decode_branch_arg =>
							instr <= douta(31 downto 26);
							wz <= douta(25);
							wc <= douta(24);
							wr <= douta(23);
							cond <= douta(21 downto 18);
				
							--branching
							case douta(31 downto 26) is
								when "010111"|"111001" =>	--jmpret (also jmp, call, ret)|djnz
									use_branch_target_intent <= '1';
								when others =>	--not a branch
									use_branch_target_intent <= '0';
							end case;
							
							--fetch src
							imm <= douta(22);
							if douta(22)='1' then	--immediate
								imm_value <= X"0000" & "0000000" & douta(8 downto 0);
							else	--indirect
								addrb <= douta(8 downto 0);
							end if;
							src_reg <= douta(8 downto 0);
							
							--fetch dst
							dst_reg <= douta(17 downto 9);
							addra_fetch <= douta(17 downto 9);
							
							fetch_decode_branch_state <= argwait;
						
						when argwait =>
							if dst_reg(8 downto 4)="11111" then	--it is a special register
								use_special_register <= '1';
								
								case dst_reg(3 downto 0) is
									when "0000" =>	--PAR
										special_reg <= X"0000" & par & "00";
										
									when "0001" =>	--CNT
										special_reg <= cnt;
										
									when "0010" =>	--INA
										special_reg <= ina;
										
									when "0011" =>	--INB
										special_reg <= inb;
										
									when "0100" =>	--OUTA
										special_reg <= outa_reg;
										
									when "0101" =>	--OUTB
										special_reg <= outb_reg;
										
									when "0110" =>	--DIRA
										special_reg <= dira_reg;
										
									when "0111" =>	--DIRB
										special_reg <= dirb_reg;
								
									when others =>
										special_reg <= (others => '0');
								end case;
							end if;
							
							fetch_decode_branch_state <= opfetch;
						
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;
	
	addra <= addra_fetch when wea='0' else addra_execute;
	wea <= wea_execute;

	execute_writeback:	process(clk)
	begin
		if rising_edge(clk) then
			if rst='1' then
				z <= '0';
				c <= '0';
				
				execute_writeback_state <= execute;
				
				throw_away_opcode <= '1';	--first opcode thrown away
				result <= (others => '0');
				resultc <= '0';
				resultz <= '0';
				
				wea_execute <= '0';
				dina <= (others => '0');
				addra_execute <= (others => '0');
				
				use_old_pc <= '0';
				old_pc_next <= (others => '0');
				
				dst_reg_copy <= (others => '0');
				
				real_src <= (others => '0');
				real_dst <= (others => '0');
				
				real_wr <= '0';
				real_wc <= '0';
				real_wz <= '0';
				
				instr_copy <= (others => '0');
				
				aluop <= add;
				alua <= (others => '0');
				alub <= (others => '0');
				alucin <= '0';
				aluzin <= '0';
				
				outa_reg <= (others => '0');
				outb_reg <= (others => '0');
				dira_reg <= (others => '0');
				dirb_reg <= (others => '0');
			else
				if run='1' then
					case execute_writeback_state is
						when execute =>
							throw_away_opcode <= '0';
							use_old_pc <= '0';
							
							old_pc_next <= pc_next;
							dst_reg_copy <= dst_reg;
							
							wea_execute <= '0';
							
							if (cond_met='0') or (throw_away_opcode='1') then	--nop
								real_wr <= '0';
								real_wc <= '0';
								real_wz <= '0';
							else	--do something
								real_wr <= wr;
								real_wc <= wc;
								real_wz <= wz;
							end if;
							
							if (dst_reg_copy=src_reg) and (real_wr='1') and (imm='0') then
								real_src <= result;	--bypass src
							else
								real_src <= src_value;
							end if;
							
							if (dst_reg_copy=dst_reg) and (real_wr='1') then
								real_dst <= result;	--bypass dst
							else
								real_dst <= dst_value;
							end if;
							
							instr_copy <= instr;
							
							execute_writeback_state <= execute2;
						
						when execute2 =>
							--calculate result value
							case instr_copy is
								when "010111" =>	--jmpret (also jmp, call, ret)
									result <= real_dst(31 downto 9) & pc_next;
									resultc <= '1';	--fake it
									resultz <= '0';
								
								---------------------------------------------
								
								when "111001" =>	--djnz
									aluop <= sub;
									alua <= real_dst;
									alub <= X"00000001";
								
								when "111010"|"111011" =>	--tjnz, tjz
									resultc <= '0';
									aluop <= add;	--add 0, only for z flag
									alua <= real_dst;
									alub <= X"00000000";
								
								------------------------------------
								
								--moving opcodes
								
								when "101000" =>	--mov
									result <= real_src;
									resultc <= real_src(31);
									if real_src=X"00000000" then
										resultz <= '1';
									else
										resultz <= '0';
									end if;
								
								-----------------------------------------
									
								--all simple alu opcodes
								
								when "100000" =>	--add
									aluop <= add;
									alua <= real_dst;
									alub <= real_src;
								
								when "110010" =>	--addx
									aluop <= addx;
									alua <= real_dst;
									alub <= real_src;
									alucin <= c;
									aluzin <= z;
								
								when "100001" =>	--sub
									aluop <= sub;
									alua <= real_dst;
									alub <= real_src;
								
								when "110011" =>	--subx
									aluop <= subx;
									alua <= real_dst;
									alub <= real_src;
									alucin <= c;
									aluzin <= z;
								
								when "011000" =>	--and
									aluop <= andop;
									alua <= real_dst;
									alub <= real_src;
								
								when "011010" =>	--or
									aluop <= orop;
									alua <= real_dst;
									alub <= real_src;
								
								when "011011" =>	--xor
									aluop <= xorop;
									alua <= real_dst;
									alub <= real_src;
								
								when "101010" =>	--abs
									aluop <= absop;
									alua <= real_src;
								
								when "101001" =>	--neg
									aluop <= neg;
									alua <= real_src;
								
								when "110100" =>	--adds
									aluop <= adds;
									alua <= real_dst;
									alub <= real_src;
								
								when "110101" =>	--subs
									aluop <= subs;
									alua <= real_dst;
									alub <= real_src;
								
								when "110110" =>	--addsx
									aluop <= addsx;
									alua <= real_dst;
									alub <= real_src;
									alucin <= c;
									aluzin <= z;
								
								when "110111" =>	--subsx
									aluop <= subsx;
									alua <= real_dst;
									alub <= real_src;
									alucin <= c;
									aluzin <= z;
								
								------------------------------------------------------
								
								--2 step alu opcodes
								
								when "101011" =>	--absneg
									aluop <= absop;
									alua <= real_src;
								
								when "100010"|"100011" =>	--addabs, subabs
									aluop <= absop;
									alua <= real_src;
								
								when "011001" =>	--andn
									aluop <= xorop;
									alua <= real_src;
									alub <= X"FFFFFFFF";
								
								------------------------------------------------------
							
								when others =>	--datasheet does not define illegal opcode result
									result <= (others => '0');
									resultc <= '0';
									resultz <= '0';
							end case;
							
							execute_writeback_state <= execute3;
						
						when execute3 =>
							case instr_copy is
								when "111001" =>	--djnz
									result <= aluresult;
									resultc <= alucout;
									resultz <= aluzout;
									if aluzout='1' then	--it is zero, don't jump
										throw_away_opcode <= '1';
										use_old_pc <= '1';
									end if;
									
								when "111010" =>	--tjnz
									result <= aluresult;
									resultz <= aluzout;
									if aluzout='0' then	--it is not zero, jump
										throw_away_opcode <= '1';
										use_old_pc <= '1';
									end if;
									
								when "111011" =>	--tjz
									result <= aluresult;
									resultz <= aluzout;
									if aluzout='1' then	--it is zero, jump
										throw_away_opcode <= '1';
										use_old_pc <= '1';
									end if;
									
								when "100000"|"110010"|"100001"|"110011"|"011000"|"011010"|"011011"|"101010"|"101001"|"110100"|"110101"|"110110"|"110111" =>	--all simple alu opcodes
									result <= aluresult;
									resultc <= alucout;
									resultz <= aluzout;
								
								when "101011" =>	--absneg
									resultc <= alucout;
									resultz <= aluzout;
									aluop <= neg;
									alua <= aluresult;
									
								when "100010" =>	--addabs
									aluop <= add;
									alua <= real_dst;
									alub <= aluresult;
									
								when "100011" =>	--subabs
									aluop <= sub;
									alua <= real_dst;
									alub <= aluresult;
								
								when "011001" =>	--andn
									aluop <= andop;
									alua <= real_dst;
									alub <= aluresult;
								
								when others => null;
							end case;
							
							execute_writeback_state <= writeback;
						
						when writeback =>
							if real_wr='1' then
								if dst_reg(8 downto 4)/="11111" then
									wea_execute <= '1';
								else
									wea_execute <= '0';
								end if;
								
								addra_execute <= dst_reg;
								
								case instr_copy is
									when "010111"|"111001"|"100000"|"110010"|"100001"|"110011"|"011000"|"011010"|"011011"|"101010"|"101001"|"101000"|"110100"|"110101"|"110110"|"110111"|"111010"|"111011" =>
										if dst_reg(8 downto 4)="11111" then
											case dst_reg(3 downto 0) is
												when "0100" =>	--OUTA
													outa_reg <= result;
													
												when "0101" =>	--OUTB
													outb_reg <= result;
													
												when "0110" =>	--DIRA
													dira_reg <= result;
													
												when "0111" =>	--DIRB
													dirb_reg <= result;
											
												when others => null;
											end case;
										else
											dina <= result;
										end if;
									
									when "101011"|"100010"|"100011"|"011001" =>	--absneg, addabs, subabs, andn
										if dst_reg(8 downto 4)="11111" then
											case dst_reg(3 downto 0) is
												when "0100" =>	--OUTA
													outa_reg <= aluresult;
													
												when "0101" =>	--OUTB
													outb_reg <= aluresult;
													
												when "0110" =>	--DIRA
													dira_reg <= aluresult;
													
												when "0111" =>	--DIRB
													dirb_reg <= aluresult;
											
												when others => null;
											end case;
										else
											dina <= aluresult;
										end if;
									
									when others => null;
								end case;
							end if;
							if real_wc='1' then
								case instr_copy is
									when "010111"|"111001"|"100000"|"110010"|"100001"|"110011"|"011000"|"011010"|"011011"|"101010"|"101001"|"101011"|"101000"|"110100"|"110101"|"110110"|"110111"|"111010"|"111011" =>
										c <= resultc;
									
									when "100010"|"100011"|"011001" =>	--addabs, subabs, andn
										c <= alucout;
									
									when others => null;
								end case;
							end if;
							if real_wz='1' then
								case instr_copy is
									when "010111"|"111001"|"100000"|"110010"|"100001"|"110011"|"011000"|"011010"|"011011"|"101010"|"101001"|"101011"|"101000"|"110100"|"110101"|"110110"|"110111"|"111010"|"111011" =>
										z <= resultz;
									
									when "100010"|"100011"|"011001" =>	--addabs, subabs, andn
										z <= aluzout;
									
									when others => null;
								end case;
							end if;
								
							execute_writeback_state <= execute;
						
						when others => null;
					end case;
				end if;
			end if;
		end if;
	end process;
end Behavioral;

