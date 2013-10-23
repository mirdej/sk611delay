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
		Ram_RAS		: out std_logic;
		Ram_CAS 		: out std_logic;
		Ram_WE		: out std_logic;
		Ram_Data		: inout std_logic_vector(7 downto 0);
		Ram_Clk		: out std_logic;
		Ram_DQM		: out std_logic;
		
		btn1			: in std_logic

	);
end entity;

--------------------------------------------------------------------------------------------
-- Architectureentity Controller is

architecture Controller_arch of Controller is

	constant CLOCK_PERIOD : positive := 7; 

<<<<<<< HEAD
	constant tRC  : positive := 68;			-- Command Period (PRE to PRE / ACT to ACT)
	constant tRCD : positive := 20 ;		-- Active Command To Read / Write Command Delay Time
	constant tRP  : positive := 20;			-- Command Period (PRE to ACT)
	constant tREF : positive := 15000; 		-- for 1 row (for 4096 you need to divide number by 4096)        
=======
-- burst size	   
	-- "000" burst size of 1
	-- "001" b.s. of 2
	-- "010" b.s. of 4
	-- "011" b.s. of 8
	constant burst_size : std_logic_vector(2 downto 0) := "011";
	
	constant CLOCK_PERIOD : positive := 15; -- in ns, should be 7.5
	-- timing constants in ns:
	constant tRC  : positive := 75;
	constant tRCD : positive := 20;
	constant tRP  : positive := 20;
	constant tREF : positive := 15000; -- for 1 row (for 4096 you need to divide number by 4096)        
>>>>>>> 40d288d7d79e1be06d9d1c0c8a838702118c9f4c
	constant tRFC : positive := 65; 
	constant tWR  : positive := CLOCK_PERIOD + 7; 
	-- sdram initialization time
	-- fo eg.: if 100 us sdram initialization is needed, tSTARTUP_NOP should be 100000 [ns]
	constant tSTARTUP_NOP : positive := 100000;
	
	-- timing constants in cycles
	-- actual cycles will be one cycle longer (every) because of state transition time (1 cycle time)
	constant tRC_CYCLES  : natural := tRC  / CLOCK_PERIOD;	 -- tRC_time = tRC_CYCLES + 1
	constant tRCD_CYCLES : natural := tRCD / CLOCK_PERIOD;	 --	tRCD_time = tRCD_CYCLES + 1
	constant tRP_CYCLES  : natural := tRP  / CLOCK_PERIOD - 1;	 -- tRP_time = tRP_CYCLES + 1
	constant tMRD_CYCLES : natural := 2; 					 -- tMRD_time = 2 tCK
	constant tREF_CYCLES : natural := tREF / CLOCK_PERIOD;	 --	tREF_time = tREF_CYCLES + 1
	constant tRFC_CYCLES : NATURAL := tRFC / CLOCK_PERIOD;	 -- tRFC_time = tRFC_CYCLES + 1
	constant tWR_CYCLES  : natural := tWR / CLOCK_PERIOD; 	 --	tWR_time = tWR_CYCLES + 1
	--constant tSTARTUP_NOP_CYCLES : positive := 10;-- tSTARTUP_NOP / (2*CLOCK_PERIOD);
constant tSTARTUP_NOP_CYCLES : positive := tSTARTUP_NOP / (2*CLOCK_PERIOD);

	constant CAS_LATENCY : positive := 3; 

type ram_state_type is (
		init,
		set_mode_register,
		precharge,
		auto_refresh,
		activate,
		ram_read,
		ram_get_data,
		nop_dqm_down,
		ram_write,
		nop
	);
	
signal another_refresh 		: std_logic;	
signal ram_state 			: ram_state_type;
signal ram_next_state		: ram_state_type;
signal ram_nops				: integer range 0 to tSTARTUP_NOP_CYCLES;

signal address_temp			: std_logic_vector(13 downto 0);	-- 12 bits Address / 2 bits BANK--	
signal byte_counter			:  std_logic_vector(23 downto 0);   -- 12 bits ROW / 10 bits COL / 2 bits BANK - Total 24 Bits

signal slow_clk				: std_logic;

signal blink 			: std_logic;
signal ada_clk			: std_logic;

signal da_buf			: std_logic_vector (7 downto 0);
signal ad_buf			: std_logic_vector (7 downto 0);
signal OEn				: std_logic;

<<<<<<< HEAD
=======
	signal execute_nop : std_logic;
	signal blink : std_logic;
	
	signal Data_From_Ram_ff: std_logic_vector(7 downto 0);
	signal Data_From_Ram_f: std_logic_vector(7 downto 0);

	signal Data_From_AD_ff: std_logic_vector(7 downto 0);
	signal Data_From_AD_f: std_logic_vector(7 downto 0);
	
>>>>>>> 40d288d7d79e1be06d9d1c0c8a838702118c9f4c
begin
	-- MASTER CLOCK ------------------------------------------------------------
		process(Clk, ResetN)
		begin
				if (ResetN	= '0') then
	slow_clk <= '0';
				elsif ((Clk'event) and (Clk = '1')) then 
				slow_clk <= not slow_clk;
				end if;
		end process;

	-- Control the state machine
	process(slow_clk, ResetN)
	begin
		if (ResetN	= '0') then
		-- do reset stuff
			
			ram_state <= init;
			address_temp <= (others => '0');
			byte_counter <= (others=>'0');
<<<<<<< HEAD
			Ram_RAS <= '1'; 	Ram_CAS <= '1';		Ram_WE <= '1';	
			LED1 <= '1';		
			LED2 <= '0';
			blink <= '0';
=======

			state <= initialize; 
			startup_pending <= '1';	
			wait_counter <= 0;	 
			twice_autorefresh <= '1';
			startup_timer <= 0;
			execute_nop <= '0';	

			LED1 <= '0';		-- LEDs are inversed: 0 means On
			LED2 <= '1';
			blink <= '1';
			
			AD_Clk <= '0';
			DA_Clk <= '0';
			DA_Data <= x"00";

>>>>>>> 40d288d7d79e1be06d9d1c0c8a838702118c9f4c
			Ram_CAS <= '0';
			Ram_RAS <= '0';
			Ram_WE <= '0';
			--Ram_Data <= "ZZZZZZZZ";
			
			--DA_Data <= (others => '0');
		
		elsif ((slow_clk'event) and (slow_clk = '1')) then 
			LED1 <= '0';		
   		  --	ad_buf <= AD_Data;                    
        --	DA_Data <= da_buf;                  

			case ram_state is
				---------------------------------
				-- Nop
				---------------------------------
				when nop =>
					Ram_RAS <= '1'; 	Ram_CAS <= '1';		Ram_WE <= '1';	
					Ram_DQM <= '1';

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
					ram_nops <= tSTARTUP_NOP_CYCLES;
					another_refresh <= '1';

				---------------------------------
				-- Precharge
				---------------------------------			
				when precharge =>
					Ram_RAS <= '0';		Ram_CAS <= '1';		Ram_WE <= '0';	 
					ram_nops <= tRP_CYCLES;					
					ram_state <= nop;
					address_temp(12) <= '1'; 			-- precharge all banks  (A10 = 1)
					if (another_refresh = '1') then 		-- we're in startup sequence
						ram_next_state <= auto_refresh;
					else
						ram_next_state <= activate;
					end if;
					
					ada_clk <= '1';
					
				---------------------------------
				-- Auto Refresh
				---------------------------------			
				when auto_refresh =>
					Ram_RAS <= '0';		Ram_CAS <= '0';		Ram_WE <= '1';	 
					ram_nops <= tRFC_CYCLES;
					ram_state <= nop;
					if (another_refresh = '1') then 
						ram_next_state <= auto_refresh;
						another_refresh <= '0';
					else 
						ram_next_state <= set_mode_register;
					end if;
<<<<<<< HEAD
=======
				end if;	  
				
				-------------------------
				-- ACTIVE command
				-------------------------
				when running =>
				LED1 <= '1';
				LED2 <= '0';
			
>>>>>>> 40d288d7d79e1be06d9d1c0c8a838702118c9f4c

				---------------------------------
				-- Set Mode
				---------------------------------			
				when set_mode_register =>
					Ram_RAS <= '0';		Ram_CAS <= '0';		Ram_WE  <= '0'; 
					address_temp <= (others=>'0');
					address_temp (7 downto 6) <= "11";				-- set bits 5 and 4 of Mode register high for CAS latency of 3 
					ram_nops <= tMRD_CYCLES;
					ram_state <= nop;
					ram_next_state <= precharge;


				---------------------------------
				-- Activate
				---------------------------------			
				when activate =>
					Ram_RAS <= '0';		Ram_CAS <= '1';		Ram_WE <= '1';
					LED2 <= '1';

					--Ram_Data <= "ZZZZZZZZ";

<<<<<<< HEAD
=======
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
					Data_From_Ram_f <= Ram_Data;
				--	Data_From_Ram_ff <= Data_From_Ram_f;
					DA_Data <= Data_From_Ram_f;
				
				when 7 =>
					-- prep Data for write
					Data_From_AD_f <= AD_Data;
				--	Data_From_AD_ff <= Data_From_AD_f;
					Ram_Data <= Data_From_AD_f;
				
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
>>>>>>> 40d288d7d79e1be06d9d1c0c8a838702118c9f4c
					-- count up
					byte_counter <= byte_counter + 1;
					if (byte_counter = x"0FFFFF") then 
							blink <= NOT blink;
							byte_counter <= (others => '0');
					end if;
<<<<<<< HEAD
=======
					
					-- prepare Row for next read
>>>>>>> 40d288d7d79e1be06d9d1c0c8a838702118c9f4c
					address_temp (13 downto 2) <= byte_counter(23 downto 12);		-- Row Address
					address_temp (1 downto 0) <= byte_counter(1 downto 0);			-- Bank
					ram_nops <= tRCD_CYCLES;
					ram_state <= nop;
					ram_next_state <= ram_read;
					
				---------------------------------
				-- Read
				---------------------------------			
				when ram_read =>
					Ram_RAS <= '1';		Ram_CAS <= '0';		Ram_WE <= '1';
					Ram_DQM <= '0';
					OEn <= '1';		-- disable output on data bus
					address_temp (13 downto 12) <= "00";  											-- bit 10 needs to be 0 otherwise theres auto precharge
					address_temp (11 downto 0) <= byte_counter (11 downto 0) ;						-- 9 Column bits + 2 Bank bits
					ram_state <= nop_dqm_down;
					
					ada_clk <= '0';

				---------------------------------
				-- Keep DQM down once
				---------------------------------			
				when nop_dqm_down =>
					Ram_RAS <= '1';		Ram_CAS <= '1';		Ram_WE <= '1';			-- nop
					ram_nops <= 1;
					ram_state <= nop;
					ram_next_state <= ram_get_data;
		
			---------------------------------
				-- Copy read data to DAC
				---------------------------------			
				when ram_get_data =>
					Ram_RAS <= '1';		Ram_CAS <= '1';		Ram_WE <= '1';			-- nop
					ram_state <= ram_write;

				---------------------------------
				-- Write
				---------------------------------			
				when ram_write =>
					Ram_RAS <= '1';		Ram_CAS <= '0';		Ram_WE <= '0';
					Ram_DQM <= '0';
					OEn <= '0';
					ram_nops <= 1;
					ram_state <= nop;
					ram_next_state <= precharge;
					
				when others => null;
			end case;
		end if;		
	end process ;
	
	process (ada_clk) 
	begin
		if ((ada_clk'event) and (ada_clk = '0')) then 
			ad_buf <= AD_Data;
			DA_Data <= da_buf;
		end if;
	end process;
	
	da_buf <= Ram_Data when (OEn = '1') else (others => 'Z');
	Ram_Data <= ad_buf when (OEn = '0') else (others => 'Z');
	
	
	Ram_clk <= not slow_clk;
	AD_Clk <= ada_clk;
	DA_Clk <= not ada_clk;
	Ram_Address <= address_temp;
	LED3 <= blink;
	
end architecture Controller_arch;
