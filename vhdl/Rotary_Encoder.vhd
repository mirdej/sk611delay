---------------------------------------------------------------------------------------------
--	VIDEO DELAY - Rotary Encoder Decoder
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
--------------------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Rotary_Encoder is
	port
	(
		Clk					: in std_logic;
		A,B					: in std_logic;
		step, dir			: out std_logic
	);
end entity;

--------------------------------------------------------------------------------------------
--																			ARCHITECTURE
architecture Rotary_Encoder_Arch of Rotary_Encoder is

signal storA,storB		: std_logic_vector (1 downto 0);
--signal trigger 			:	std_logic;
signal dir_int,step_int : std_logic;

begin

	process (clk)
	begin
  	 	if (clk'EVENT and clk = '1') then
			storA(1) <= storA(0);
			storA(0) <= A;
			storB(1) <= storB(0);
			storB(0) <= B;
  	  	end if;
	end process;

	process(storA)
	begin
		step_int <= '0';
		dir_int <= '0';
		case storA is
			when "01" =>	
				if (storB(0) = '1') then dir_int <= '1'; end if;
				step_int <= '1';
			when "10" =>
				if (storB(0) = '0') then dir_int <= '1'; end if;
				step_int <= '1';
			when others => null;
		end case;
	end process;

	--trigger <= storA(1) xor storA(0);
	dir <= dir_int;
	step <= step_int;
	
end Rotary_Encoder_Arch;

