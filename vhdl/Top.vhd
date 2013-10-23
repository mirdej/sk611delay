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
		LED3			: out std_logic
	);
end entity;

--------------------------------------------------------------------------------------------
--																			ARCHITECTURE
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


--------------------------------------------------------------------------------------------
--																			Implementation
--------------------------------------------------------------------------------------------

signal slow_clk_int		: std_logic;
signal pretty_slow_clk_int		: std_logic;
signal very_slow_clk_int		: std_logic;
signal counter_int		: std_logic_vector(9 downto 0);
signal enc_step,enc_dir : std_logic;


begin

	Display_Inst : Display
	port map
	(
		Clk				=> slow_clk_int,
		Number 			=> counter_int,
		To7seg_Cathodes		=> Display_C,
		To7Seg_Anodes		=> Display_A
	);
	
	Slow_Clock_Inst : Slow_Clock
	port map
	(
		Clk			=> Clk,
		ResetN		=> ResetN,
		Ms1	  		=> slow_clk_int,
		Ms40	  	=> pretty_slow_clk_int,
		Ms500	  	=> very_slow_clk_int
	);

	Counter_Inst : Counter
	port map
	(
		Clk			=> enc_step,
		ResetN		=> ResetN,
		Count	  	=> counter_int,
		Direction	=> enc_dir,
		Highspeed	=> Encoder_C
	);
	
	Rotary_Inst : Rotary_Encoder
	port map
	(
		Clk					=> slow_clk_int,	-- sample every 1 ms
		A					=> Encoder_A,
		B					=> Encoder_B,
		step				=> enc_step,
		dir					=> enc_dir
	);
	
	LED3 <= very_slow_clk_int;

end Top_Arch;
