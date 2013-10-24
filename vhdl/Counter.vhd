---------------------------------------------------------------------------------------------
--	VIDEO DELAY - Counter
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Counter is 	
	port
	(
		Clk				: in std_logic;
		ResetN			: in std_logic;
		Direction		: in std_logic;
		Highspeed		: in std_logic;
		Count			: out std_logic_vector(7 downto 0)
	);
end entity;


--------------------------------------------------------------------------------------------
--																			ARCHITECTURE
architecture Counter_Arch of Counter is

signal counter : integer;

begin
	process(Clk, ResetN)
	begin
		if(ResetN = '0') then
			counter <= 128;
		elsif((Clk'event) and (Clk = '1')) then
			if (Highspeed ='0') then
				if (Direction = '0') then
					counter <= counter + 10;
				else
					counter <= counter - 10;
				end if;
			else 
				if (Direction = '0') then
					counter <= counter + 1;
				else
					counter <= counter - 1;
				end if;
			end if;
		end if;
	end process;
	
        Count <= std_logic_vector(to_unsigned(counter,8));
	
end Counter_Arch;