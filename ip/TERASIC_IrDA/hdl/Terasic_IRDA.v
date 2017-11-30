// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies (china)Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
//
// Major Functions:	IRDA receiver SOPC IP core
//
// --------------------------------------------------------------------
//
// Revision History :
// --------------------------------------------------------------------
//   Ver  :| Author            :| Mod. Date :| Changes Made:
//   V1.0 :| PeLi Li           :| 2010/03/23:|      Initial Revision
//													for DE2 v2.X PCB.
// --------------------------------------------------------------------

module Terasic_IRDA  
         (	
            clk,           //clk 50M
	        reset_n,       //reset
	        chip_select,   //chip select
	        //address,       //adress signal
	        //write,         
	        //write_data,
	        read,          //read command
	        read_data,     //read data
	       // byte_enable,   //
	        irda_data,           //IRDA data input
	        //ioclock,       
	        //cs_n ,
	        irq            //data ready ,low----->high
            );            
            
//////////////////port declaration////////////////////            
input    	clk;          //clk 50M
input       reset_n;       //reset
input       chip_select;   //chip select
	        //address,       //adress signal
	        //write,         
	        //write_data,
input       read;          //read command
//input       byte_enable;   //
input       irda_data;           //IRDA data input

output [31:0] read_data;     //read data
	        //ioclock,       
	        //cs_n ,
output      irq  ;          //data ready ,low----->high IS
/////////////////wire&reg/////////////////////////////

//wire valid_read;
//wire ready_irq;

wire   [31:0]    read_data;
wire             ready_irq;

///////////////strcutural code//////////////////////
assign irq = ready_irq;

IRDA_RECEIVE_Terasic u0(
					.iCLK(clk),         //clk   50MHz
					.iRST_n(reset_n),       //reset
					
					.iIRDA(irda_data),        //IRDA code input
					.iREAD(chip_select & read),        //read command
					
					.oDATA_REAY(ready_irq),	  //data ready
					.oDATA(read_data)         //decode data output
					);




endmodule



