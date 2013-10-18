--------------------------------------------------------------------------------------------
--	VIDEO DELAY CONTROLLER
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
--
-- with code inspiration from http://www.geocities.ws/mikael262/sdram.html
--------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------
--OUTPUTS
--Bit 										13		12		11	10	9	8	7	6	5	4	3	2	1		0
--Pin											A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	BA1	BA0
																								
--ROW											A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	BA1	BA0
--COL											X		0		C9	C8	C7	C6	C5	C4	C3	C2	C1	C0	BA1	BA0

--------------------------------------------------------------------------------------------
--byte_counter																								
--Bit		23		22		21	20	19	18	17	16	15	14	13	12	11	10	9	8	7	6	5	4	3	2	1		0
--			A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	C9	C8	C7	C6	C5	C4	C3	C2	C1	C0	BA1	BA0
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
		DA_Data 		: out std_logic_vector (7 downto 0);

		Ram_Address : out std_logic_vector(13 downto 0);  -- 12 bits Address / 2 bits BANK
		Ram_WE		: out std_logic;
		Ram_CAS 		: out std_logic;
		Ram_RAS		: out std_logic;
		Ram_Data		: inout std_logic_vector(7 downto 0);
		Ram_Clk		: out std_logic;
		Ram_DQM		: out std_logic;
		
		btn1			: in std_logic

	);
end entity;

--------------------------------------------------------------------------------------------
-- Architecture

architecture Controller_arch of Controller is

constant MAX_NOPS : positive := 10;

	constant CLOCK_PERIOD : positive := 6; 

	constant tRC  : positive := 75;
	constant tRCD : positive := 20;
	constant tRP  : positive := 20;
	constant tREF : positive := 15000; -- for 1 row (for 4096 you need to divide number by 4096)        
	constant tRFC : positive := 65; 
	constant tWR  : positive := CLOCK_PERIOD + 7; 
	-- sdram initialization time
	-- fo eg.: if 100 us sdram initialization is needed, tSTARTUP_NOP should be 100000 [ns]
	constant tSTARTUP_NOP : positive := 100000;
	
	-- timing constants in cycles
	-- actual cycles will be one cycle longer (every) because of state transition time (1 cycle time)
	constant tRC_CYCLES  : natural := tRC  / CLOCK_PERIOD;	 -- tRC_time = tRC_CYCLES + 1
	constant tRCD_CYCLES : natural := tRCD / CLOCK_PERIOD;	 --	tRCD_time = tRCD_CYCLES + 1
	constant tRP_CYCLES  : natural := tRP  / CLOCK_PERIOD;	 -- tRP_time = tRP_CYCLES + 1
	constant tMRD_CYCLES : natural := 2; 					 -- tMRD_time = 2 tCK
	constant tREF_CYCLES : natural := tREF / CLOCK_PERIOD;	 --	tREF_time = tREF_CYCLES + 1
	constant tRFC_CYCLES : NATURAL := tRFC / CLOCK_PERIOD;	 -- tRFC_time = tRFC_CYCLES + 1
	constant tWR_CYCLES  : natural := tWR / CLOCK_PERIOD; 	 --	tWR_time = tWR_CYCLES + 1


type ram_state_type is (
		init,
		set_mode_register,
		precharge,
		auto_refresh,
		act,
		ram_read,
		ram_write,
		nop
	);
	
signal another_refresh 		: std_logic;	
signal ram_state 			: ram_state_type;
signal ram_next_state		: ram_state_type;
signal ram_nops				: integer range 0 to MAX_NOPS;

signal address_temp			: std_logic_vector(13 downto 0);	-- 12 bits Address / 2 bits BANK--	




begin
	-- MASTER CLOCK ------------------------------------------------------------
	-- Control the state machine
	process(Clk, ResetN)
	begin
		if (ResetN	= '0') then
		-- do reset stuff
			
			ram_state <= init;
			address_temp <= (others => '0');
			Ram_RAS <= '1';
			Ram_CAS <= '1';
			Ram_WE <= '1';	
			LED1 <= '1';		
			LED2 <= '0';
	
		elsif ((Clk'event) and (Clk = '1')) then 
			

			case ram_state is
			
				when nop =>
					Ram_RAS <= '1';
					Ram_CAS <= '1';
					Ram_WE <= '1';	
				
					if (ram_nops = 0) then
						ram_state <= ram_next_state;
					else
						ram_state <= nop;
						ram_nops <= ram_nops - 1;
					end if;
				---------------------------------
				-- Start Ram Initialization 
				---------------------------------
				when init =>
					Ram_DQM <= '1';
					ram_next_state <= precharge;
					ram_state <= nop;
					ram_nops <= MAX_NOPS;
					another_refresh <= '1';

				---------------------------------
				-- Precharge
				---------------------------------			
				when precharge =>
					Ram_RAS <= '0';
					Ram_CAS <= '1';
					Ram_WE <= '0';	 
					address_temp(12) <= '1'; 		-- precharge all banks  (A10 = 1)
					ram_nops <= 2;					-- do we care ????
					ram_state <= nop;
					ram_next_state <= auto_refresh;
					
				---------------------------------
				-- Auto Refresh
				---------------------------------			
				when auto_refresh =>
					Ram_RAS <= '0';
					Ram_CAS <= '0';
					Ram_WE <= '1';	 
					ram_nops <= tRFC_CYCLES;
					ram_state <= nop;
					if (another_refresh = '1') then 
						ram_next_state <= auto_refresh;
						another_refresh <= '0';
					else 
						ram_next_state <= set_mode_register;
					end if;

				---------------------------------
				-- Set Mode
				---------------------------------			
				when set_mode_register =>
					Ram_RAS <= '0';
					Ram_CAS <= '0';
					Ram_WE  <= '0'; 
					address_temp <= (others=>'0');
					address_temp (7 downto 6) <= "11";				-- set bits 5 and 4 of Mode register high for CAS latency of 3 
					ram_nops <= tMRD_CYCLES;
					ram_state <= nop;
					ram_next_state <= act;
					
				when others => null;
			end case;
		end if;		
	end process ;
	
	Ram_clk <= not Clk;
end architecture Controller_arch;