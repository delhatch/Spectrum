// Code reference "FPGA Prototyping by Verilog Examples" pg.192
module Mod_counter
	#( parameter N, M )
	(
		input  clk,
		input  clk_en,
		input  reset,
		output max_tick,
		output [N-1:0] q,
		input pause
	);
	
reg [N-1:0] r_reg;
wire [N-1:0] r_next;

always @( posedge clk, posedge reset )
	if( reset )
		r_reg <= 0;
	else if ( pause || ~clk_en ) r_reg <= r_reg;
   else r_reg <= r_next;

assign r_next = ( r_reg == (M-1) ) ? 0 : r_reg + 1;
assign q = r_reg;
assign max_tick = ( r_reg == (M-2) ) ? 1'b1 : 1'b0;

endmodule