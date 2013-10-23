-------------------------------------------------------------------------------------------------------------------
--	VIDEO DELAY - SDRAM Controller
--
-- Part of the Synkie Project: www.synkie.net
--
-- © 2013 Michael Egger, Licensed under GNU GPLv3
--
------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------
--OUTPUTS
--Bit 											13	12	11	10	9	8	7	6	5	4	3	2	1	0
--Pin											A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	BA1	BA0
																								
--ROW											A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	BA1	BA0
--COL											X	0	C9	C8	C7	C6	C5	C4	C3	C2	C1	C0	BA1	BA0

------------------------------------------------------------------------------------------------------------------
--byte_counter																								
--Bit		23	22	21	20	19	18	17	16	15	14	13	12	11	10	9	8	7	6	5	4	3	2	1	0
--			A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	C9	C8	C7	C6	C5	C4	C3	C2	C1	C0	BA1	BA0
------------------------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Controller is
	port(
		Clk    		: in  std_logic;
		ResetN 		: in  std_logic;
		
		Write_data		: in std_logic_vector (31 downto 0);
		data_in		: in std_logic_vector (31 downto 0);
		
		Ram_Address : out std_logic_vector(13 downto 0);  -- 12 bits Address / 2 bits BANK
		Ram_RAS		: out std_logic;
		Ram_CAS 	: out std_logic;
		Ram_WE		: out std_logic;
		Ram_Data	: inout std_logic_vector(7 downto 0);
		Ram_Clk		: out std_logic;
		Ram_DQM		: out std_logic;
	);
end entity;