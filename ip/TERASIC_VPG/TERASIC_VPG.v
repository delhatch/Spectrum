
`include ".\vga_time_generator.v"

module TERASIC_VPG(
        // global Signals
        clk,
        reset_n,
   
		
		// avalon
		s_cs_n,
		s_write,
		s_writedata,
		s_read,
		s_readdata,
		
		// VGA export interface
		vga_clk,
		vga_hs,
		vga_vs,
		vga_de,
		vga_r,
		vga_g,
		vga_b
);


/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/
parameter SYMBOLS_PER_BEAT   = 1; 
parameter BITS_PER_SYMBOL    = 24;
parameter READY_LATENCY      = 0; 
parameter MAX_CHANNEL        = 0;

parameter H_DISP	         = 640;
parameter H_FPORCH	         = 16;
parameter H_SYNC	         = 96;
parameter H_BPORCH	         = 48;
parameter V_DISP	         = 480;
parameter V_FPORCH	         = 10;
parameter V_SYNC	         = 2;
parameter V_BPORCH	         = 33;



/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/


`define STATE_IDLE    		0
`define STATE_WAIT_SOP		1   // start of packet
`define STATE_WAIT_EOF		2   // end of frame
`define STATE_STREAMING 	3

`define	PAT_SCALE		3'd0
`define	PAT_RED			3'd1
`define	PAT_GREEN		3'd2
`define	PAT_BLUE		3'd3
`define	PAT_WHITE		3'd4
`define	PAT_BLACK		3'd5


/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
        // global signal
input							clk;
input							reset_n;
	
		
		// avalon
input					s_cs_n;
input					s_write;
input		[7:0]		s_writedata;
input					s_read;
output	reg	[7:0]		s_readdata;


		
		// VGA export interface
input					vga_clk;
output	reg			vga_hs;
output	reg			vga_vs;
output	reg			vga_de;
output	reg	[7:0]	vga_r;
output	reg	[7:0]	vga_g;
output	reg	[7:0]	vga_b;


/*****************************************************************************
 *                 Internal wires and registers Declarations                 *
 *****************************************************************************/




/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential logic                              *
 *****************************************************************************/
 



/*****************************************************************************
 *                            Combinational logic                            *
 *****************************************************************************/


/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/
 
 
 always @ (posedge clk or negedge reset_n)
 begin
 	if (!reset_n)
 		vga_pattern <= `PAT_SCALE;
 	else if (!s_cs_n & s_write)
 		vga_pattern <= s_writedata;
 	else if (!s_cs_n & s_read)
 		s_readdata <= vga_pattern;
 	
 end
 
 
wire			pix_hs;
wire			pix_vs;
wire			pix_de;
wire	[11:0]	pix_x;
wire	[11:0]	pix_y;



vga_time_generator vga_time_generator_instance(
		.clk      (vga_clk),
		.reset_n  (reset_n),
	//	.timing_change(timing_chang),
		.h_disp   (H_DISP),
		.h_fporch (H_FPORCH),
		.h_sync   (H_SYNC), 
		.h_bporch (H_BPORCH),
		
		.v_disp   (V_DISP),
		.v_fporch (V_FPORCH),
		.v_sync   (V_SYNC),
		.v_bporch (V_BPORCH),
		.hs_polarity(1'b0),
		.vs_polarity(1'b0),
		.frame_interlaced(1'b0),
		
		.vga_hs   (pix_hs),
		.vga_vs   (pix_vs),
		.vga_de   (pix_de),
		.pixel_x  (pix_x),
		.pixel_y ( pix_y),
		.pixel_i_odd_frame() 
);



//============ stage 1 =======
reg	[2:0]	vga_pattern;
reg 		vga_hs_1;
reg 		vga_vs_1;
reg 		vga_de_1;
reg [23:0]	vga_data_1;
wire [7:0]	video_scale;

assign video_scale = pix_x[7:0];

always @ (posedge vga_clk)
begin
	vga_hs_1 <= pix_hs;
	vga_vs_1 <= pix_vs;
	vga_de_1 <= pix_de;
end

always @ (posedge vga_clk)
begin
	if (!pix_de)
		vga_data_1 <= 24'h000000;
	else if (vga_pattern == `PAT_SCALE)
	begin
		if (pix_y < V_DISP/4)
			vga_data_1 <= {8'h00,8'h00,video_scale} ; // RED
		else if (pix_y < V_DISP/2)
			vga_data_1 <= {8'h00,video_scale,8'h00} ; // GREEN
		else if (pix_y < V_DISP*3/4)
			vga_data_1 <= {video_scale,8'h00,8'h00} ; // Blue
		else
			vga_data_1 <= {video_scale,video_scale,video_scale} ; // gray
	end
	else if (vga_pattern == `PAT_RED)		
		vga_data_1 <= {8'h00,8'h00,8'hFF} ; 
	else if (vga_pattern == `PAT_GREEN)		
		vga_data_1 <= {8'h00,8'hFF,8'h00} ; 
	else if (vga_pattern == `PAT_BLUE)		
		vga_data_1 <= {8'hFF,8'h00,8'h00} ; 
	else if (vga_pattern == `PAT_WHITE)		
		vga_data_1 <= {8'hFF,8'hFF,8'hFF} ; 
	else if (vga_pattern == `PAT_BLACK)		
		vga_data_1 <= {8'h00,8'h00,8'h00} ; 

end


//============ stage 2 =======
always @ (posedge vga_clk)
begin
	{vga_b,vga_g,vga_r} <= vga_data_1;
	vga_hs <= vga_hs_1;
	vga_vs <= vga_vs_1;
	vga_de <= vga_de_1;
end



endmodule





