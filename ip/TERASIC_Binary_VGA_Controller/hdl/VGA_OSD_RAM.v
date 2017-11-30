module	VGA_OSD_RAM	(	//	Read Out Side
						oRed,
						oGreen,
						oBlue,
						iVGA_ADDR,
						iVGA_CLK,
						//	Write In Side
						iWR_DATA,
						iWR_ADDR,
						iWR_EN,
						iWR_CLK,
						//	CLUT
						iON_R,
						iON_G,
						iON_B,
						iOFF_R,
						iOFF_G,
						iOFF_B,
						//	Control Signals
						iRST_N	);
//	Read Out Side
output	reg	[9:0]	oRed;
output	reg	[9:0]	oGreen;
output	reg	[9:0]	oBlue;
input	[18:0]		iVGA_ADDR;
input				iVGA_CLK;
//	Write In Side
input	[18:0]		iWR_ADDR;
input				iWR_DATA;
input				iWR_EN;
input				iWR_CLK;
//	CLUT
input	[9:0]	iON_R;
input	[9:0]	iON_G;
input	[9:0]	iON_B;
input	[9:0]	iOFF_R;
input	[9:0]	iOFF_G;
input	[9:0]	iOFF_B;
//	Control Signals
input				iRST_N;
//	Internal Registers/Wires
reg		[2:0]		ADDR_d;
reg		[2:0]		ADDR_dd;
wire	[7:0]		ROM_DATA;

always@(posedge iVGA_CLK or negedge iRST_N)
    begin
        if(!iRST_N)
            begin
                oRed	<=	0;
                oGreen	<=	0;
                oBlue	<=	0;
                ADDR_d	<=	0;
                ADDR_dd	<=	0;
            end
        else
            begin
                ADDR_d	<=	iVGA_ADDR[2:0];
                ADDR_dd	<=	~ADDR_d;
                oRed	<=	ROM_DATA[ADDR_dd]?	iON_R:iOFF_R;
                oGreen	<=	ROM_DATA[ADDR_dd]?	iON_G:iOFF_G;
                oBlue	<=	ROM_DATA[ADDR_dd]?	iON_B:iOFF_B;
            end
    end

Img_RAM 	u0	(	//	Write In Side
					.data(iWR_DATA),
					.wren(iWR_EN),
					.wraddress({iWR_ADDR[18:3],~iWR_ADDR[2:0]}),
					.wrclock(iWR_CLK),
					//	Read Out Side
					.rdaddress(iVGA_ADDR[18:3]),
					.rdclock(iVGA_CLK),
					.q(ROM_DATA));

endmodule