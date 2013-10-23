---------------------------------------------------------------------------------------------
--	VIDEO DELAY - Hex to 7 Segment
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

entity Hex_7_Seg is
	port
	(
		x	: in std_logic_vector (3 downto 0);		-- hex input
		a2g : out std_logic_vector (6 downto 0);		-- 7 seg out
	);
end Hex_7_Seg;


architecture Hex_7_Seg_Arch of Hex_7_Seg is
begin
	process(x)
	begin
		case x is
		  when "0000" => a2g  <= "1111110"
			when "0001" => a2g  <= "0110000"
			when "0010" => a2g  <= "1101101"
			when "0011" => a2g  <= "1111001"
			when "0100" => a2g  <= "0110011"
			when "0101" => a2g  <= "1011011"
			when "0110" => a2g  <= "1011111"
			when "0111" => a2g  <= "1110000"
			when "1000" => a2g  <= "1111111"
			when "1001" => a2g  <= "1111011"
			when "1010" => a2g  <= "1110111"
			when "1011" => a2g  <= "0011111"
			when "1100" => a2g  <= "1001111"
			when "1101" => a2g  <= "0111101"
			when "1110" => a2g  <= "1001111"
			when "1111" => a2g  <= "1000111"
		  when others => a2g <= "0000000";
		end case;
	end process;
end Hex_7_Seg_Arch;
