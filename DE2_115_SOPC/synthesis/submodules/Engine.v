module Engine (
   input signed [31:0] eRegRe, eRegIm,  // (x,y)
	input [15:0] eMaxItr,
	input GO,
	input eRST_N,
	input Engine_CLK,
	// Dual-port RAM signals (to write data to it)
	output reg [15:0] ItrCounter,  // Numer of iterations completed w/o escaping
	output reg eDONE  // DONE output. Signals x,y escaped, or it hit MaxItr.
);

localparam	state_a = 3'b000,
				state_b = 3'b001,
				state_c = 3'b010,
				state_d = 3'b011,
				state_e = 3'b100,
				state_f = 3'b101;
				
//localparam DONE = eWR_Status_DATA;
//localparam GO   = eMaxItr[0];

// Wire declarations
reg [2:0] state = 3'b000;
reg signed [31:0] NewRe, OldRe, NewIm, OldIm;
reg signed [63:0] temp1, temp2, temp4;

// State machine
always @ ( posedge Engine_CLK or negedge eRST_N ) begin
   if ( ~eRST_N )
     state <= state_a;
	else
	case( state )
	   state_a : begin
						eDONE <= 1'b0;
						NewRe <= 0;
						OldRe <= 0;
						NewIm <= 0;
						OldIm <= 0;
						ItrCounter <= 0;
						if( GO == 1'b0 ) state <= state_a;
						else state <= state_b;
					 end
		
		state_b : begin
						OldRe <= NewRe;
						OldIm <= NewIm;
						state <= state_c;
					 end
		
		state_c : begin
						//NewRe <= ((OldRe * OldRe)>>>24) - ((OldIm * OldIm)>>>24) + eRegRe;
						temp1 = (OldRe * OldRe)>>>24;
						temp2 = (OldIm * OldIm)>>>24;
						NewRe <= temp1 - temp2 + eRegRe;
						//NewIm <= (((2 * OldRe) * OldIm)>>>24) + eRegIm;
						temp4 = (OldRe * OldIm)>>>24;
						NewIm <= (2 * temp4) + eRegIm;
						state <= state_d;
					 end
					 
		state_d : begin
		        temp1 = (NewRe * NewRe) >>> 24;
		        temp2 = (NewIm * NewIm) >>> 24;
						//if( (((NewRe*NewRe)>>>24) + ((NewIm*NewIm)>>>24)) > 32'h04000000 ) begin
						if( (temp1 + temp2) > 32'h04000000 ) begin
						   eDONE <= 1'b1;
							state <= state_f;
							end
						else begin
							ItrCounter <= ItrCounter + 1;
							state <= state_e;
							end
					 end
					 
		state_e : begin
						if( ItrCounter == eMaxItr ) begin
							eDONE <= 1'b1;
							state <= state_f;
							end
						else state <= state_b;
					 end
					 
		state_f : begin
						eDONE <= 1'b1;
						if( GO == 1'b1 ) state <= state_f;
						else state <= state_a;
					 end
					 
		default : state <= state_a;
		
	endcase
end     // end of state logic

endmodule
