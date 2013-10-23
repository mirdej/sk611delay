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

entity Bin_2_BCD is
	port
	(
		bin	: in std_logic_vector (8 downto 0);			-- binary input
		bcd : out std_logic_vector (9 downto 0);		-- bcd output
	);
end Hex_7_Seg;


architecture Bin_2_BCD_Arch of Bin_2_BCD is
begin
	process(bin)
		variable z : std_logic_vector (17 downto 0);
	
		for i in o to 17 loop
			z(i) := '0';
		end loop;
		z(10 downto 3) := bin;
	
		for i in 0 to 4 loop
			if z(11 downto 8) > 4 then
				z(11 downto 8) := z(11 downto 8) + 3;
			end if;
			if z (15 downto 12) > 4 then
				z (15 downto 12) := z (15 downto 12) + 3;
			end if
			z(17 downto 1) := z (16 downto 0);
		end loop;
		
		p <= z(17 downto 8);
	end process;
end Bin_2_BCD;
