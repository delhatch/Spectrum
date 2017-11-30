module	TERASIC_SRAM(
	//	global clk/reset
	clk,
	reset_n,
	// avalon slave
	s_chipselect_n,
	s_byteenable_n,
	s_write_n,
	s_read_n,
	s_address,
	s_writedata,
	s_readdata,
	
	// SRAM interface
	SRAM_DQ,
	SRAM_ADDR,
	SRAM_UB_n,
	SRAM_LB_n,
	SRAM_WE_n,
	SRAM_CE_n,
	SRAM_OE_n
);

parameter DATA_BITS		= 16;
parameter ADDR_BITS		= 20;

input						clk;
input						reset_n;

input						s_chipselect_n;
input	[(DATA_BITS/8-1):0]	s_byteenable_n;
input						s_write_n;
input						s_read_n;
input	[(ADDR_BITS-1):0]	s_address;
input	[(DATA_BITS-1):0]	s_writedata;
output	[(DATA_BITS-1):0]	s_readdata;

output						SRAM_CE_n;
output						SRAM_OE_n;
output				 		SRAM_LB_n;
output				 		SRAM_UB_n;
output						SRAM_WE_n;
output	[(ADDR_BITS-1):0]	SRAM_ADDR;
inout	[(DATA_BITS-1):0]	SRAM_DQ;

assign	SRAM_DQ 				=	SRAM_WE_n ? 'hz : s_writedata;
assign	s_readdata				=	SRAM_DQ;
assign	SRAM_ADDR				=	s_address;
assign	SRAM_WE_n				=	s_write_n;
assign	SRAM_OE_n				=	s_read_n;
assign	SRAM_CE_n				=	s_chipselect_n;
assign	{SRAM_UB_n,SRAM_LB_n}	=	s_byteenable_n;

/*						
//	Host Side
input	[15:0]	iDATA;
output	[15:0]	oDATA;
input	[17:0]	iADDR;
input			iWE_N,iOE_N;
input			iCE_N,iCLK;
input	[1:0]	iBE_N;
//	SRAM Side
inout	[15:0]	SRAM_DQ;
output	[17:0]	SRAM_ADDR;
output			SRAM_UB_N,
				SRAM_LB_N,
				SRAM_WE_N,
				SRAM_CE_N,
				SRAM_OE_N;

assign	SRAM_DQ 	=	SRAM_WE_N ? 16'hzzzz : iDATA;
assign	oDATA		=	SRAM_DQ;
assign	SRAM_ADDR	=	iADDR;
assign	SRAM_WE_N	=	iWE_N;
assign	SRAM_OE_N	=	iOE_N;
assign	SRAM_CE_N	=	iCE_N;
assign	SRAM_UB_N	=	iBE_N[1];
assign	SRAM_LB_N	=	iBE_N[0];
*/

endmodule