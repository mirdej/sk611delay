library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity Memory is
	port(
		Clk    		: in  std_logic;
		ResetN 		: in  std_logic;
		
		Address  	: out std_logic_vector(11 downto 0);
		Bank 			: out std_logic_vector(1 downto 0);
		WE				: out std_logic;
		CAS 			: out std_logic;
		RAS			: out std_logic;
		RamData		: inout std_logic_vector(7 downto 0);
		
		AD_Clk		: out std_logic;
		AD_Data 		: in  std_logic_vector (7 downto 0);
		
		DA_Clk 		: out std_logic;
		DA_Data 		: out std_logic_vector (7 downto 0)
	);
end entity;

architecture Memory_arch of Memory is
	signal step 	: 	natural;
	signal AddrTemp	:  std_logic_vector(11 downto 0);
	signal BankTemp	:  std_logic_vector(1 downto 0);
	signal DataTemp 	:  std_logic_vector (7 downto 0);
	signal Row			:  std_logic_vector(11 downto 0);
	signal Column		:  std_logic_vector(9 downto 0);

	
begin
	process(Clk, ResetN)
	begin
		if (ResetN	= '0') then
			AddrTemp <= (others=>'0');
			BankTemp <= (others=>'0');
			Column <= (others=>'0');
			Row <= (others=>'0');
			step <= 0;
			AD_Clk <= '0';
			DA_Clk <= '0';
			CAS <= '0';
			RAS <= '0';
			WE <= '0';
			DA_Data <= x"00";
			AD_Clk <= '0';
			RamData <= "ZZZZZZZZ";

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
					WE <= '1';
					CAS <= '1';
					RAS <= '0';
					-- Also: Falling Edge DA-Converter
					DA_Clk <= '0';
				when 2 => 
					-- NOP ... but prepare column adress for next read
					AddrTemp (11 downto 10) <= '0';  -- bit 10 needs to be 0 otherwise theres auto precharge
					AddrTemp (9 downto 0) <= Column (9 downto 0) ;
				when 3 => 
					-- READ
					WE <= '1';
					CAS <= '0';
					RAS <= '1';
				when 4 =>
					-- Clock AD-Converter at least 12ns before we need Data
					AD_Clk <= '1';
				when 6 =>
					-- DATA from RAM ready-> buffer
					DA_Data <= RamData;
				
				when 7 =>
					-- prep Data for write
					RamData <= AD_Data;
				
				when 8 =>
					-- WRITE
					WE <= '0';
					CAS <= '0';
					RAS <= '1';
					-- Also: Clock DA-Converter > 10ns after Data Ready
					DA_Clk <= '1';
				when 10 =>
					-- Falling edge AD-Clock:
					AD_Clk <= '0';
					
				when 11 =>
					-- PRECHARGE
					WE <= '0';
					CAS <= '1';
					RAS <= '0';
				when 13 =>
					-- count up
					BankTemp <= BankTemp + 1;
					if (BankTemp = 0) then
						Column <= Column + 1;
						if (Column = 0) then
							Row <= Row + 1;
						end if;
					end if;
					-- prepare Row for next read
					AddrTemp <= Row;
					
					step <= 0;
				when others => null;
			end case;
			
		end if;
		
	end process;
	Address <= AddrTemp;
	Bank <= BankTemp;
	
end architecture memory_arch;

