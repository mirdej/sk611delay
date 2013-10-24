---------------------------------------------------------------------------------------------
--	VIDEO DELAY - Slow Clock
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Slow_Clock is 	
	port
	(
		Clk				: in std_logic;
		ResetN			: in std_logic;
		Ms1				: out std_logic;		-- 1 ms clock cycle			/  	  1000 Hz
		Ms40			: out std_logic;			-- 40 ms clock cycle		/	    25 Hz
		Ms500			: out std_logic			-- 2 hz
	);
end entity;


--------------------------------------------------------------------------------------------
--																			ARCHITECTURE
architecture Slow_Clock_Arch of Slow_Clock is


-- 	uncomment for real world
	constant FCLK  			: positive 		:= 156250000;			-- clock cycles / second
	constant CYC_P_MS		: natural 		:= FCLK  / 2000;	

-- 	for testing -> speed up
--	constant CYC_P_MS		: natural 		:= 10;	


signal clk_int	: std_logic;
signal clk2_int	: std_logic;
signal clk3_int	: std_logic;

begin

	process(Clk, ResetN)
	variable count : integer range 0 to CYC_P_MS := 0;
	begin
		if(ResetN = '0') then
			count := 0;
				
		elsif((Clk'event) and (Clk = '1')) then
			
			if (count = CYC_P_MS - 1) then
				count := 0;
				clk_int <= not clk_int;
			else
				count := count + 1;
			end if;
		end if;
	end process;
	

	a40msclock: process(clk_int)
	variable count : integer range 0 to 40 := 0;
	begin
		if((clk_int'event) and (clk_int = '1')) then
			
			if (count = 39) then
				count := 0;
				clk2_int <= not clk2_int;
			else
				count := count + 1;
			end if;
		end if;
	end process;

	a500_ms_clock: process(clk_int)
	variable count : integer range 0 to 500 := 0;
	begin
		if((clk_int'event) and (clk_int = '1')) then
			
			if (count = 499) then
				count := 0;
				clk3_int <= not clk3_int;
			else
				count := count + 1;
			end if;
		end if;
	end process;

		
	Ms1 		<= clk_int;
	Ms40 		<= clk2_int;
	Ms500 		<= clk3_int;
	
end Slow_Clock_Arch;