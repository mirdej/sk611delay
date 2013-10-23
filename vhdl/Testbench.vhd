-- Copyright (C) 1991-2013 Altera Corporation
-- Your use of Altera Corporation's design tools, logic functions 
-- and other software and tools, and its AMPP partner logic 
-- functions, and any output files from any of the foregoing 
-- (including device programming or simulation files), and any 
-- associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License 
-- Subscription Agreement, Altera MegaCore Function License 
-- Agreement, or other applicable license agreement, including, 
-- without limitation, that your use is for the sole purpose of 
-- programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the 
-- applicable agreement for further details.

-- ***************************************************************************
-- This file contains a Vhdl test bench template that is freely editable to   
-- suit user's needs .Comments are provided in each section to help the user  
-- fill out necessary details.                                                
-- ***************************************************************************
-- Generated on "10/22/2013 17:09:59"
                                                            
-- Vhdl Test Bench template for design  :  Top
-- 
-- Simulation tool : ModelSim-Altera (VHDL)
-- 

LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;                                

ENTITY Top_vhd_tst IS
END Top_vhd_tst;
ARCHITECTURE Top_arch OF Top_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL Clk : STD_LOGIC;
SIGNAL Display_A : STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL Display_C : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL Encoder_A : STD_LOGIC;
SIGNAL Encoder_B : STD_LOGIC;
SIGNAL Encoder_C : STD_LOGIC;
SIGNAL ResetN : STD_LOGIC;
SIGNAL Slow : STD_LOGIC;

COMPONENT Top
	PORT (
	Clk : IN STD_LOGIC;
	Display_A : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
	Display_C : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
	Encoder_A : IN STD_LOGIC;
	Encoder_B : IN STD_LOGIC;
	Encoder_C : IN STD_LOGIC;
	ResetN : IN STD_LOGIC;
	Slow : OUT STD_LOGIC
	);
END COMPONENT;
BEGIN
	i1 : Top
	PORT MAP (
-- list connections between master ports and signals
	Clk => Clk,
	Display_A => Display_A,
	Display_C => Display_C,
	Encoder_A => Encoder_A,
	Encoder_B => Encoder_B,
	Encoder_C => Encoder_C,
	Slow => Slow,
	ResetN => ResetN
	);
	
init : PROCESS                                               
BEGIN                                                        
		ResetN <= '0';
		wait for 50 ns;
		ResetN <= '1';
		WAIT;                                                       
END PROCESS init;        
                                   
always : PROCESS                                              
-- optional sensitivity list                                  
-- (        )                                                 
-- variable declarations                                      
BEGIN                                                         
loop
    Clk <= '0'; wait for 3200 ps;
    Clk <= '1'; wait for 3200 ps;
end loop;
WAIT;                                                        
END PROCESS always;                                          
END Top_arch;
