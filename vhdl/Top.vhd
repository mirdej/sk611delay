---------------------------------------------------------------------------------------------
--	VIDEO DELAY - TOP FILE
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
--------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity Top is
	port 
	(
		Clk				: in std_logic;
		ResetN			: in std_logic;
		Display_C  		: out std_logic_vector(6 downto 0);
		Display_A  		: out std_logic_vector(2 downto 0);
		Encoder_A		: in std_logic;
		Encoder_B		: in std_logic;
		Encoder_C		: in std_logic;
		Led1			: out std_logic;
		Led2			: out std_logic;
		Led3			: out std_logic;
		AD_Clk			: out std_logic;
		AD_Data 		: in  std_logic_vector (7 downto 0);
		DA_Clk 			: out std_logic;
		DA_Data 		: out std_logic_vector (7 downto 0);
		Switch1			: in std_logic;
		Ram_Address 	: out std_logic_vector(13 downto 0);  -- 12 bits Address / 2 bits BANK
		Ram_RAS			: out std_logic;
		Ram_CAS 		: out std_logic;
		Ram_WE			: out std_logic;
		Ram_Data		: inout std_logic_vector(7 downto 0);
		Ram_Clk			: out std_logic;
		Ram_DQM			: out std_logic
	);
end entity;

--------------------------------------------------------------------------------------------
--																			ARCHITECTURE
--------------------------------------------------------------------------------------------
architecture Top_Arch of Top is

-------------------------------------------------------------------------------  Display
component Display is
	port
	(
		Clk					: in std_logic;
		Number				: in std_logic_vector (9 downto 0);
		To7seg_Cathodes		: out std_logic_vector (6 downto 0);
		To7Seg_Anodes		: out std_logic_vector (2 downto 0)
	);
end component;

-------------------------------------------------------------------------------  150 Hz Clock
component Slow_Clock is
	port
	(
		Clk				: in std_logic;
		ResetN			: in std_logic;
		Ms1				: out std_logic;		-- 1 ms clock cycle			/  	  1000 Hz
		Ms40			: out std_logic;		-- 40 ms clock cycle		/	    25 Hz
		Ms500			: out std_logic			-- 2 hz
	);
end component;

-------------------------------------------------------------------------------  Counter
component Counter is
	port
	(
		Clk				: in std_logic;
		ResetN			: in std_logic;
		Direction		: in std_logic;
		Highspeed		: in std_logic;
		Count			: out std_logic_vector(9 downto 0)
	);
end component;

component Rotary_Encoder is
	port
	(
		Clk					: in std_logic;
		A,B					: in std_logic;
		step, dir			: out std_logic
	);
end component;

-------------------------------------------------------------------------------  Analog Converters
component AD_DA is
port (
		Clk    		: in  std_logic;
		ResetN 		: in  std_logic;
		Loopthru	: in  std_logic;
		Data_from_AD 	: out  std_logic_vector (7 downto 0);
		Data_to_DA 		: in  std_logic_vector (7 downto 0);
		AD_Clk		: out std_logic;
		AD_Input 	: in  std_logic_vector (7 downto 0);
		DA_Clk 		: out std_logic;
		DA_Out	 	: out std_logic_vector (7 downto 0)
);
end component;
-------------------------------------------------------------------------------  Analog Converters
component Ram_Controller is
	port(
		Clk    		: in  std_logic;
		ResetN 		: in  std_logic;
		Overflow		: out std_logic;

		Write_Data		: in std_logic_vector (7 downto 0);
		Read_Data		: out std_logic_vector (7 downto 0);
		
		Ram_Address : out std_logic_vector(13 downto 0);  -- 12 bits Address / 2 bits BANK
		Ram_RAS		: out std_logic;
		Ram_CAS 	: out std_logic;
		Ram_WE		: out std_logic;
		Ram_Data	: inout std_logic_vector(7 downto 0);
		Ram_Clk		: out std_logic;
		Ram_DQM		: out std_logic
	);
end component;
--------------------------------------------------------------------------------------------
--																			Implementation
--------------------------------------------------------------------------------------------

signal slow_clk_int					: std_logic;
signal pretty_slow_clk_int			: std_logic;
signal very_slow_clk_int			: std_logic;
signal counter_int					: std_logic_vector(9 downto 0);
signal enc_step,enc_dir 			: std_logic;
signal ad_buf,da_buf				: std_logic_vector(7 downto 0);

begin

-------------------------------------------------------------------------------  AD-DA
	AD_DA_Inst : AD_DA
	port map
	(
		Clk					=> Clk,
		ResetN				=> ResetN,
		Loopthru			=> Switch1,
		Data_from_AD		=> ad_buf,
		Data_to_DA			=> da_buf, 
		AD_Clk				=> AD_Clk,
		AD_Input			=> AD_Data,
		DA_Clk 				=> DA_Clk,
		DA_Out				=> DA_Data
	);
-------------------------------------------------------------------------------  SDRAM
	Ram_Controller_Inst : Ram_Controller
	port map(
		Clk    				=> Clk,
		ResetN 				=> ResetN,
		Overflow			=> LED2,
		Write_Data			=> ad_buf,
		Read_Data			=> da_buf,
		Ram_Address 		=> Ram_Address,
		Ram_RAS				=> Ram_RAS,
		Ram_CAS				=> Ram_CAS,
		Ram_WE				=> Ram_WE,
		Ram_Data			=> Ram_Data,
		Ram_Clk				=> Ram_Clk,
		Ram_DQM				=> Ram_DQM
	);
-------------------------------------------------------------------------------  LEDs
	LED3 					<= very_slow_clk_int;
	
	Display_C <= "1111111";
	
end Top_Arch;
