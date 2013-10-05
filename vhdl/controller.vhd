library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Controller is
	port(
		Clk    		: in  std_logic;
		ResetN 		: in  std_logic;
		
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
--COUNTER																								
--Bit		23		22		21	20	19	18	17	16	15	14	13	12	11	10	9	8	7	6	5	4	3	2	1		0
--			A11	A10	A9	A8	A7	A6	A5	A4	A3	A2	A1	A0	C9	C8	C7	C6	C5	C4	C3	C2	C1	C0	BA1	BA0
--------------------------------------------------------------------------------------------


architecture Controller_arch of Controller is
	signal step 		: 	natural;
	signal AddrTemp	:  std_logic_vector(13 downto 0);	-- 12 bits Address / 2 bits BANK
																			--	
	signal Counter		:  std_logic_vector(23 downto 0);   -- 12 bits ROW / 10 bits COL / 2 bits BANK - Total 24 Bits
	signal TopCount	: natural;
	signal DataTemp 	:  std_logic_vector (7 downto 0);
	
begin

	process(Clk, ResetN)
	begin
		if (ResetN	= '0') then
			AddrTemp <= (others=>'0');
			Counter <= (others=>'0');
			step <= 0;
			
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
			step <= step + 1;	
			
			
			
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
			
			case step is
				when 0 =>
					-- ACTIVATE
					Ram_WE <= '1';
					Ram_CAS <= '1';
					Ram_RAS <= '0';
					-- Also: Falling Edge DA-Converter
					DA_Clk <= '0';
					
				when 2 => 
					-- NOP ... but prepare column adress for next read
					AddrTemp (13 downto 12) <= "00";  											-- bit 10 needs to be 0 otherwise theres auto precharge
					AddrTemp (11 downto 0) <= Counter (11 downto 0) ;						-- 9 Column bits + 2 Bank bits
				
				when 3 => 
					-- READ
					Ram_WE <= '1';
					Ram_CAS <= '0';
					Ram_RAS <= '1';
				
				when 4 =>
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
					
				when 10 =>
					-- Falling edge AD-Clock:
					AD_Clk <= '0';
					
				when 11 =>
					-- PRECHARGE
					Ram_WE <= '0';
					Ram_CAS <= '1';
					Ram_RAS <= '0';
					
				when 13 =>
					-- count up
					Counter <= Counter + 1;
					
					-- prepare Row for next read
					AddrTemp (13 downto 2) <= Counter(23 downto 12);		-- Row Address
					AddrTemp (1 downto 0) <= Counter(1 downto 0);			-- Bank
					
					step <= 0;
				when others => null;
			end case;
			
		end if;
		
	end process;
	
	Ram_Address <= AddrTemp;
	Ram_Clk <= Clk;

end architecture Controller_arch;

