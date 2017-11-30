module	VGA_NIOS_CTRL (	//	Host Side
						avs_s1_writedata_iDATA,
						avs_s1_readdata_oDATA,
						avs_s1_address_iADDR,
						avs_s1_write_iWR,
						avs_s1_read_iRD,
						avs_s1_chipselect_iCS,
						avs_s1_reset_n_iRST_N,
						avs_s1_clk_iCLK,		//	Host Clock
						//	Export Side
						avs_s1_export_VGA_R,
						avs_s1_export_VGA_G,
						avs_s1_export_VGA_B,
						avs_s1_export_VGA_HS,
						avs_s1_export_VGA_VS,
						avs_s1_export_VGA_SYNC,
						avs_s1_export_VGA_BLANK,
						avs_s1_export_VGA_CLK,
						avs_s1_export_iCLK_25	);

parameter	RAM_SIZE	=	19'h4B000;

//	Host Side
output	[15:0]	avs_s1_readdata_oDATA;
input	[15:0]	avs_s1_writedata_iDATA;	
input	[18:0]	avs_s1_address_iADDR;
input			avs_s1_write_iWR,avs_s1_read_iRD,avs_s1_chipselect_iCS;
input			avs_s1_clk_iCLK,avs_s1_reset_n_iRST_N;
reg		[15:0]	avs_s1_readdata_oDATA;
//	Export Side
output	[9:0]	avs_s1_export_VGA_R;
output	[9:0]	avs_s1_export_VGA_G;
output	[9:0]	avs_s1_export_VGA_B;
output			avs_s1_export_VGA_HS;
output			avs_s1_export_VGA_VS;
output			avs_s1_export_VGA_SYNC;
output			avs_s1_export_VGA_BLANK;
output			avs_s1_export_VGA_CLK;
input			avs_s1_export_iCLK_25;

reg		[3:0]	mCursor_RGB_N;
reg		[9:0]	mCursor_X;
reg		[9:0]	mCursor_Y;
reg		[9:0]	mCursor_R;
reg		[9:0]	mCursor_G;
reg		[9:0]	mCursor_B;
reg		[9:0]	mON_R;
reg		[9:0]	mON_G;
reg		[9:0]	mON_B;
reg		[9:0]	mOFF_R;
reg		[9:0]	mOFF_G;
reg		[9:0]	mOFF_B;
wire	[18:0]	mVGA_ADDR;
wire	[9:0]	mVGA_R;
wire	[9:0]	mVGA_G;
wire	[9:0]	mVGA_B;
//color lut
wire NCLK_n;	
wire [7:0] index;
reg [23:0] bgr_data;
wire [23:0] bgr_data_raw;

wire [7:0] b_data; 
wire [7:0] g_data;  
wire [7:0] r_data;
//2-value when set the pixel via mouse
wire    [9:0]   mMouse_R;
wire    [9:0]   mMouse_G;
wire    [9:0]   mMouse_B;
assign  mMouse_R = {r_data,2'b00};
assign  mMouse_G = {g_data,2'b00};
assign  mMouse_B = {b_data,2'b00};

always@(negedge avs_s1_clk_iCLK or negedge avs_s1_reset_n_iRST_N)
    begin
        if(!avs_s1_reset_n_iRST_N)
            begin
                mCursor_RGB_N	<=	0;
                mCursor_X		<=	0;
                mCursor_Y		<=	0;
                mCursor_R		<=	0;
                mCursor_G		<=	0;
                mCursor_B		<=	0;
                mON_R			<=	0;
                mON_G			<=	0;
                mON_B			<=	0;
                mOFF_R			<=	0;
                mOFF_G			<=	0;
                mOFF_B			<=	0;
                avs_s1_readdata_oDATA			<=	0;
            end
        else
            begin
                if(avs_s1_chipselect_iCS)
                    begin
                        if(avs_s1_write_iWR)
                            begin
                                case(avs_s1_address_iADDR)
                                RAM_SIZE+0 :	mCursor_RGB_N	<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+1 :	mCursor_X		<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+2 :	mCursor_Y		<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+3 :	mCursor_R		<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+4 :	mCursor_G		<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+5 :	mCursor_B		<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+6 :	mON_R			<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+7 :	mON_G			<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+8 :	mON_B			<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+9 :	mOFF_R			<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+10:	mOFF_G			<=	avs_s1_writedata_iDATA;
                                RAM_SIZE+11:	mOFF_B			<=	avs_s1_writedata_iDATA;
                                endcase
                            end
                        else if(avs_s1_read_iRD)
                            begin
                                case(avs_s1_address_iADDR)
                                RAM_SIZE+0 :	avs_s1_readdata_oDATA	<=	mCursor_RGB_N	;
                                RAM_SIZE+1 :	avs_s1_readdata_oDATA	<=	mCursor_X		;
                                RAM_SIZE+2 :	avs_s1_readdata_oDATA	<=	mCursor_Y		;
                                RAM_SIZE+3 :	avs_s1_readdata_oDATA	<=	mCursor_R		;
                                RAM_SIZE+4 :	avs_s1_readdata_oDATA	<=	mCursor_G		;
                                RAM_SIZE+5 :	avs_s1_readdata_oDATA	<=	mCursor_B		;
                                RAM_SIZE+6 :	avs_s1_readdata_oDATA	<=	mON_R			;
                                RAM_SIZE+7 :	avs_s1_readdata_oDATA	<=	mON_G			;
                                RAM_SIZE+8 :	avs_s1_readdata_oDATA	<=	mON_B			;
                                RAM_SIZE+9 :	avs_s1_readdata_oDATA	<=	mOFF_R			;
                                RAM_SIZE+10:	avs_s1_readdata_oDATA	<=	mOFF_G			;
                                RAM_SIZE+11:	avs_s1_readdata_oDATA	<=	mOFF_B			;
                                endcase
                            end
                    end
            end
    end

VGA_Controller		u0	(	//	Host Side
								.iCursor_RGB_EN(4'b0111),
								.iCursor_X(mCursor_X),
								.iCursor_Y(mCursor_Y),
								.iCursor_R(mCursor_R),
								.iCursor_G(mCursor_G),
								.iCursor_B(mCursor_B),							
								.oAddress(mVGA_ADDR),
								.iRed	(mMouse_R),
								.iGreen	(mMouse_G),
								.iBlue	(mMouse_B),
								//	VGA Side
								.oVGA_R(avs_s1_export_VGA_R ),
								.oVGA_G(avs_s1_export_VGA_G ),
								.oVGA_B(avs_s1_export_VGA_B ),
								.oVGA_H_SYNC(avs_s1_export_VGA_HS),
								.oVGA_V_SYNC(avs_s1_export_VGA_VS),
								.oVGA_SYNC(avs_s1_export_VGA_SYNC),
								.oVGA_BLANK(avs_s1_export_VGA_BLANK),
								.oVGA_CLOCK(avs_s1_export_VGA_CLK),
								//	Control Signal
								.iCLK_25(avs_s1_export_iCLK_25),
								.iRST_N(avs_s1_reset_n_iRST_N)	);

//VGA_OSD_RAM			u1	(	//	Read Out Side
//							.oRed(mVGA_R),
//							.oGreen(mVGA_G),
//							.oBlue(mVGA_B),
//							.iVGA_ADDR(mVGA_ADDR),
//							.iVGA_CLK(avs_s1_export_VGA_CLK),
							//	Write In Side
//							.iWR_DATA(avs_s1_writedata_iDATA),
//							.iWR_ADDR(avs_s1_address_iADDR),
//							.iWR_EN(avs_s1_write_iWR && (avs_s1_address_iADDR < RAM_SIZE) && avs_s1_chipselect_iCS),
//							.iWR_CLK(avs_s1_clk_iCLK),
							//	CLUT
//							.iON_R(mON_R),
//							.iON_G(mON_G),
//							.iON_B(mON_B),
//							.iOFF_R(mOFF_R),
//							.iOFF_G(mOFF_G),
//							.iOFF_B(mOFF_B),
							//	Control Signals
//							.iRST_N(avs_s1_reset_n_iRST_N)	);

//background pic read,based on color 256 lut
assign NCLK_n = ~avs_s1_export_VGA_CLK;
//color LUT index output
//--- NEW:
my_img_data img_data_inst (
   .rdaddress( mVGA_ADDR ),
   .rdclock( NCLK_n ),
	.wrclock( avs_s1_clk_iCLK ),
   .q( index ),
   .wraddress( avs_s1_address_iADDR ),
   .wren( avs_s1_write_iWR && (avs_s1_address_iADDR < RAM_SIZE) && avs_s1_chipselect_iCS ),
	.data( avs_s1_writedata_iDATA[7:0] )
   );

//--- WAS:
//img_data	img_data_inst (
//	.address ( mVGA_ADDR ),
//	.clock ( NCLK_n ),
//	.q ( index ),
//	);
//---------

//Color LUT output
img_index	img_index_inst (
	.address ( index ),
	.clock ( avs_s1_export_VGA_CLK ),
	.q ( bgr_data_raw)
	);	

//latch valid data at falling edge;
always@(posedge NCLK_n) 
	bgr_data <= bgr_data_raw;
//red	
assign b_data = bgr_data[23:16];
//green
assign g_data = bgr_data[15:8];
//blue
assign r_data = bgr_data[7:0];
								
endmodule