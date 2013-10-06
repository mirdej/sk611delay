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
		
		Ram_Address : out std_logic_vector(13 downto 0);  -- 12 bits Address / 2 bits BANK
		Ram_WE		: out std_logic;
		Ram_CAS 		: out std_logic;
		Ram_RAS		: out std_logic;
		Ram_DQM		: out std_logic;
		Ram_Data		: inout std_logic_vector(7 downto 0);
		Ram_Clk		: out std_logic;
		Ram_CKE		: out std_logic;
		
		AD_Clk		: out std_logic;
		AD_Data 		: in  std_logic_vector (7 downto 0);
		
		DA_Clk 		: out std_logic;
		DA_Data 		: out std_logic_vector (7 downto 0)
	);
end entity;


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


-- Clock: 133.33333Mhz -> clock period 7.5ns

architecture Controller_arch of Controller is


-- burst size	   
	-- "000" burst size of 1
	-- "001" b.s. of 2
	-- "010" b.s. of 4
	-- "011" b.s. of 8
	constant burst_size : std_logic_vector(2 downto 0) := "011";
	
	constant CLOCK_PERIOD : positive := 8; -- in ns, should be 7.5
	-- timing constants in ns:
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
	constant tSTARTUP_NOP_CYCLES : positive := tSTARTUP_NOP / (2*CLOCK_PERIOD);
	
	constant CAS_LATENCY : positive := 3; 

	type state_type is (
		initialize,
		set_ModeRegister,
		precharge,
		auto_refresh,
		running,
		nop
	);
	
	signal state : state_type;
	

	signal address_temp			:  std_logic_vector(13 downto 0);	-- 12 bits Address / 2 bits BANK--	
	signal data_temp 			:  std_logic_vector (7 downto 0);
	signal byte_counter			:  std_logic_vector(23 downto 0);   -- 12 bits ROW / 10 bits COL / 2 bits BANK - Total 24 Bits
	signal top_count			: natural;
	
	signal step : integer range 0 to 15;
	signal startup_timer 		: integer range 0 to tSTARTUP_NOP_CYCLES; 
	signal startup_pending 		: std_logic;	-- '1' - in startup sequence
	signal wait_counter 			: integer range 0 to 15; -- how many cycles wait until next command can be issued
	signal twice_autorefresh 	: std_logic; -- double autorefresh command needed in startup sequence

	signal execute_nop : std_logic;
	signal blink : std_logic;
	
begin

	process(Clk, ResetN)
	begin
		if (ResetN	= '0') then
			address_temp <= (others=>'0');
			byte_counter <= (others=>'0');

			state <= initialize; 
			startup_pending <= '1';	
			wait_counter <= 0;	 
			twice_autorefresh <= '1';
			startup_timer <= 0;
			execute_nop <= '0';	

			LED1 <= '1';
			LED2 <= '0';
			blink <= '0';
			
			AD_Clk <= '0';
			DA_Clk <= '0';
			DA_Data <= x"00";

			Ram_CAS <= '0';
			Ram_RAS <= '0';
			Ram_WE <= '0';
			Ram_CKE <= '1';
			Ram_Data <= "ZZZZZZZZ";
			Ram_DQM <= '0';			-- think this can sty low

		elsif ((Clk'event) and (Clk = '1')) then 
		
			case state is		 		
				--------------------------
				-- initialization		 
				--------------------------
				when initialize =>
				Ram_CKE <= '1';	
				state <= nop;	
				
				-----------------------------
				-- MODE REGISTER SET command
				-----------------------------
				when set_ModeRegister =>
				Ram_RAS <= '0';
				Ram_CAS <= '0';
				Ram_WE  <= '0'; 
				-- SEND MODE REGISTER SET
				address_temp <= (others=>'0');
				address_temp (7 downto 6) <= "11";				-- set bits 5 and 4 of Mode register high for CAS latency of 3 

				-- after MRS command issue n nop cycles where n = tMRD_CYCLES 
				if execute_nop = '1' then
					Ram_RAS <= '1';
					Ram_CAS <= '1';
					Ram_WE <= '1';		
				end if;
				
				-- wait for tMRD_CYCLES before issue
				if wait_counter < tMRD_CYCLES then
					wait_counter <= wait_counter + 1; 
					execute_nop <= '1';
				else			
					-- sdram initialization complete
					wait_counter <= 0;	
					startup_pending <= '0';	
					state <= running;	
					execute_nop <= '0';
				end if;	
				
				--------------------------
				-- NOP command			 
				--------------------------
				when nop =>
				Ram_RAS <= '1';
				Ram_CAS <= '1';
				Ram_WE <= '1';		 
				Ram_DQM <= '0';	
				
				execute_nop <= '0';	
				
				if startup_pending = '1' then
					if startup_timer < tSTARTUP_NOP_CYCLES then
						startup_timer <= startup_timer + 1;
						state <= initialize;
					else
						state <= precharge;
					end if;	 				 
				end if;
				
				--------------------------
				-- PRECHARGE command	  
				--------------------------
				when precharge =>	 
				Ram_RAS <= '0';
				Ram_CAS <= '1';
				Ram_WE <= '0';	 
				address_temp(10) <= '1'; -- precharge all banks  
				
				if execute_nop = '1' then
					Ram_RAS <= '1';
					Ram_CAS <= '1';
					Ram_WE <= '1';		
				end if;
				
				if wait_counter < tRP_CYCLES then
					wait_counter <= wait_counter + 1;
					execute_nop <= '1';
				else
					execute_nop <= '0';
					wait_counter <= 0;
					
					if startup_pending = '1' then 
						state <= auto_refresh;
					else
						state <= nop;
					end if;	
				end if;
				
				-------------------------
				-- AUTO REFRESH command
				-------------------------
				when auto_refresh =>
				Ram_RAS <= '0';
				Ram_CAS <= '0';
				Ram_WE <= '1';	
				
				if execute_nop = '1' then
					Ram_RAS <= '1';
					Ram_CAS <= '1';
					Ram_WE <= '1';		
				end if;
				
				if wait_counter < (tRFC_CYCLES-1)+conv_integer(startup_pending) then
					wait_counter <= wait_counter + 1; 
					execute_nop <= '1';
				else   
					execute_nop <= '0';
					wait_counter <= 0;
					if twice_autorefresh = '1' then
						twice_autorefresh <= '0';
					else
						if startup_pending = '1' then
							state <= set_ModeRegister;
						else
							state <= nop;
						end if;
					end if;
				end if;	  
				
				-------------------------
				-- ACTIVE command
				-------------------------
				when running =>
				LED1 <= '0';
				LED2 <= '1';
				
				if (byte_counter = 0) then 
					blink <= NOT blink;
				end if;

-- ----------------------------------------------------------------------------------------
--  													NORMAL OPERATION		
-- ----------------------------------------------------------------------------------------
	
--												CS		RAS	CAS	WE
--0		ACTIVATE 	(Bank / Row)	0		0		1		1		BA, RA	
--1		NOP
--2		NOP
--3		READ		(Column)				0		1		0		1		BA, CA, A10: Low?
--4		NOP , DQM High on falling edge
--5		NOP,
--6		NOP,	Data ready (CAS = 3)
--7		NOP			(prep data? settling time 1.5 ns befor clk)
--8		WRITE		(Column)				0		1		0		0		BA, CA, A10: + DATA
--9		NOP
--10		NOP
--11		PRECHARGE						0		0		1		0
--12		NOP
--13		NOP
			
			step <= step + 1;	--	


			case step is
				when 0 =>
					-- ACTIVATE
					Ram_WE <= '1';
					Ram_CAS <= '1';
					Ram_RAS <= '0';
					-- Also: Falling Edge DA-Converter
					DA_Clk <= '0';
				
				when 1 =>
					-- NOP
					Ram_WE <= '1'; Ram_CAS <= '1'; Ram_RAS <= '1';

				when 2 => 
					-- NOP ... but prepare column adress for next read
					address_temp (13 downto 12) <= "00";  											-- bit 10 needs to be 0 otherwise theres auto precharge
					address_temp (11 downto 0) <= byte_counter (11 downto 0) ;						-- 9 Column bits + 2 Bank bits
				
				when 3 => 
					-- READ
					Ram_WE <= '1';
					Ram_CAS <= '0';
					Ram_RAS <= '1';
				
				when 4 =>
					-- NOP
					Ram_WE <= '1'; Ram_CAS <= '1'; Ram_RAS <= '1';
					-- Clock AD-Converter at least 12ns before we need Data
					AD_Clk <= '1';
				
				when 6 =>
					-- DATA from RAM ready-> buffer
					DA_Data <= Ram_Data;
				
				when 7 =>
					-- prep Data for write
					Ram_Data <= AD_Data;
				
				when 8 =>
					-- WRITE
					Ram_WE <= '0';
					Ram_CAS <= '0';
					Ram_RAS <= '1';
					-- Also: Clock DA-Converter > 10ns after Data Ready
					DA_Clk <= '1';
					
				when 9 =>
					-- NOP
					Ram_WE <= '1'; Ram_CAS <= '1'; Ram_RAS <= '1';
					
				when 10 =>
					-- Falling edge AD-Clock:
					AD_Clk <= '0';
					
				when 11 =>
					-- PRECHARGE
					Ram_WE <= '0';
					Ram_CAS <= '1';
					Ram_RAS <= '0';
					
				when 12 =>
					-- NOP
					Ram_WE <= '1'; Ram_CAS <= '1'; Ram_RAS <= '1';
					
				when 13 =>
					-- count up
					byte_counter <= byte_counter + 1;
					
					-- prepare Row for next read
					address_temp (13 downto 2) <= byte_counter(23 downto 12);		-- Row Address
					address_temp (1 downto 0) <= byte_counter(1 downto 0);			-- Bank
					
					step <= 0;
				when others => null;
			end case;
-- ----------------------------------------------------------------------------------------
--																					END NORMAL OPERATION





			when others =>
				State <= initialize;
			end case;
		end if; -- Rising Clock Edge
		
	end process;
	
	Ram_Address <= address_temp;
	Ram_Clk <= Clk;
	LED3 <= blink;
	
end architecture Controller_arch;

