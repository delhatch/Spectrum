// Takes audio stream from the codec and puts it into the FIFO.
// Note: The FIFO size is the same as the number of points for the FFT to process.
//         It does not matter how big the FIFO is, for this module. It just fills
//            the FIFO until the FIFO signals it is full.
// Note: external module needs to drop the start2fill line shortly after 
//       data begins to be entered into the fifo. Gate with !fifo's rdempty.
module audio2fifo (
   input reset,
   input start2fill,
   input adcdata,
   input bclk,
   input adclrc,
   // FIFO signals
   input wrempty,
   input wrfull,
   output [15:0] audiodata,
   output wrclk,
   output reg wrreq
);

parameter s0 = 0,
          s1 = 1,
          s1a = 2,
          s2 = 3,
          s3 = 4,
          s4 = 5;

reg [3:0] state = 0;
//reg [3:0] neg_state = 0;
reg [15:0] shiftreg;    // as wide as the audio word sample.
reg [7:0] bitcntr;
//reg wrreq;
assign wrclk = bclk;
assign audiodata = shiftreg;    // the input to the fifo is the output of the shiftregister.
                
always @ ( posedge bclk or posedge reset ) begin
   if( reset ) begin
      state <= s0;
      wrreq <= 1'b0;
      bitcntr = 0;
   end
   else
      case( state )
         s0 : begin   // stay here until order to start filling FIFO.
                 bitcntr <= 0;
                 if( (start2fill==1'b1) && (adclrc==1'b0) && (~wrfull) ) state <= s1;  
                 else state <= s0;
              end
              
         s1 :  begin
                  if( wrfull ) state <= s0;   // Check if the last fifo write filled it.
                  else if( ~adclrc ) state <= s1; // adclrc still low, so wait.
                  else state <= s2;    // rising edge of adclrc.
               end
               
         s2 : begin
                  bitcntr <= 0;
                  if( adclrc ) state <= s2; // now high, but need to catch the falling edge.
                  else state <= s3;
               end
              
         s3 : begin
                  shiftreg[15:0] <= {shiftreg[14:0], adcdata};
                  bitcntr <= bitcntr + 1;
                  if( bitcntr == 15 ) begin   // number of bits in an audio word sample.
                     wrreq <= 1'b1;
                     state <= s4;
                     end
                  else state <= s3;
              end
              
         s4 : begin      // sample fully shifted into shiftreg, ready to put into fifo.
                  wrreq <= 1'b0;
                  state <= s1; 
              end
              
         default : state <= s0;
      endcase
end

// wrreq is sampled on the falling edge of bclk. The code above centers the wrreq pulse
//    at the falling edge. Which is good. The code below centers the pulse on the
//    rising edge, which is wrong. Probably. Need to verify with simulation.
/*
always @ ( negedge bclk or posedge reset ) begin
   if( reset ) begin
      neg_state <= s0;
      wrreq_out <= 1'b0;
   end
   else
      case( neg_state )
         s0 : begin   // stay here until it's time to send fifo the wrreq signals
                 if( wrreq == 1'b0 ) neg_state <= s0;
                 else begin
                    wrreq_out = 1'b1;
                    neg_state <= s1;
                 end
              end
              
         s1 : begin
                 wrreq_out = 1'b0;
                 neg_state <= s0;
              end
              
         default : begin
                      wrreq_out <= 1'b0;
                      neg_state <= s0;
                   end
      endcase
end
*/

endmodule
                  
                  