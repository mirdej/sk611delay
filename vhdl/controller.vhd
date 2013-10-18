--------------------------------------------------------------------------------------------
--	VIDEO DELAY CONTROLLER
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
--
-- with code from http://www.geocities.ws/mikael262/sdram.html
--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Controller is
	port(
		Clk    		: in  std_logic;
		ResetN 		: in  std_logic;
		
		Led1			: out std_logic;
		Led2			: out std_logic;
		Led3			: out std_logic;
		
		AD_Clk		: out std_logic;
		AD_Data 		: in  std_logic_vector (7 downto 0);
		
		DA_Clk 		: out std_logic;
		DA_Data 		: out std_logic_vector (7 downto 0)

	);
end entity;



architecture Controller_arch of Controller is


	-- Clock: 156.25 Mhz -> clock period 6.4ns

	constant CLOCK_PERIOD : positive := 7; -- in ns, should be 6.4

	signal inbuf_f 		: std_logic_vector (7 downto 0);
	signal inbuf_ff 		: std_logic_vector (7 downto 0);
	signal ada_clk			: std_logic;
	
	signal blink 			: std_logic;
	signal step 			: integer range 0 to 16;
	signal counter 		: integer range 0 to 16000000;
		
begin

	process(Clk, ResetN)
	begin
		if (ResetN	= '0') then
			LED1 <= '1';		
			LED2 <= '0';
			
			ada_clk <= '0';
	
		elsif ((Clk'event) and (Clk = '1')) then 
			LED1 <= '0';		
			LED2 <= '0';
	
			step <= step + 1;
			if (step = 7) then
				ada_clk <= '0';
			end if ;
			
			if (step = 14) then
				step <= 0; -- ca 10 Mhz Clock
				
				ada_clk <= '1';
				
			end if;
		end if; -- Rising Clock Edge
		
	end process;
	
	process (ada_clk, ResetN)
	begin
		if (ResetN	= '0') then
			blink <= '0';
			inbuf_f <= (others => '0');
			inbuf_ff <= (others => '0');
			
		elsif ((ada_clk'event) and (ada_clk = '0')) then -- AD Data is certainly valid on falling clock edge
			counter <= counter + 1;
				
			if (counter = 500000) then
				blink <= not blink;
				counter <= 0;
			end if;
			
			-- sample AD
			inbuf_f <= AD_Data;
			inbuf_ff <= inbuf_f;
			
			-- push to DA
			DA_Data <= inbuf_ff;
		end if;
	end process;
	
	
	LED3 <= blink;
	AD_Clk <= ada_clk;
	DA_Clk <= ada_clk;
	
end architecture Controller_arch;

