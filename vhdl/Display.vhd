---------------------------------------------------------------------------------------------
--	VIDEO DELAY - 7 Segment Display Controller
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

entity Display is
	port
	(
		Clk					: in std_logic;
		Number				: in std_logic_vector (9 downto 0);
		To7seg_Cathodes		: out std_logic_vector (6 downto 0);
		To7Seg_Anodes		: out std_logic_vector (2 downto 0)
	);
end entity;


--------------------------------------------------------------------------------------------
--																			ARCHITECTURE
architecture Display_Arch of Display is

signal disp_num :  std_logic_vector (12 downto 0);
signal disp_mux : integer range 0 to 3;
signal x : std_logic_vector (3 downto 0);		-- hex input


begin
	
	process(Number) 
	begin
		disp_num <= "000" & Number;
	end process;
	
	
	process(Clk)
	begin
		if((Clk'event) and (Clk = '1')) then
			if (disp_mux = 2) then 
				disp_mux <= 0;
			else 
				disp_mux <= disp_mux + 1;
			end if;
		end if;
	end process;
	
	process (disp_mux)
	begin
		x <= disp_num((3 + (4 * disp_mux)) downto (4 * disp_mux));
		To7Seg_Anodes <= (others => '1');
		To7Seg_Anodes(disp_mux) <= '0';
	end process;	
	
	process(x)
	begin
	
	--											abcdefg
		case x is
			when "0000" => To7seg_Cathodes  <= "0000001"; -- 0
			when "0001" => To7seg_Cathodes  <= "1001111"; -- 1
			when "0010" => To7seg_Cathodes  <= "0010010"; -- 2
			when "0011" => To7seg_Cathodes  <= "0000110"; -- 3
			when "0100" => To7seg_Cathodes  <= "1001100"; -- 4
			when "0101" => To7seg_Cathodes  <= "0100100"; -- 5
			when "0110" => To7seg_Cathodes  <= "0100000"; -- 6
			when "0111" => To7seg_Cathodes  <= "0001111"; -- 7
			when "1000" => To7seg_Cathodes  <= "0000000"; -- 8
			when "1001" => To7seg_Cathodes  <= "0000100"; -- 9
			when "1010" => To7seg_Cathodes  <= "0001000"; -- A
			when "1011" => To7seg_Cathodes  <= "1100000"; -- B
			when "1100" => To7seg_Cathodes  <= "0110001"; -- C
			when "1101" => To7seg_Cathodes  <= "1000010"; -- D
			when "1110" => To7seg_Cathodes  <= "0110000"; -- E
			when "1111" => To7seg_Cathodes  <= "0111000"; -- F
			when others => To7seg_Cathodes <= "0000000";
		end case;
	end process;
end Display_Arch;