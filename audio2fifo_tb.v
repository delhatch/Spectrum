module audio2fifo_tb ();

// signal into the DUT are variables
reg reset, start2fill, adcdata, bclk, adclrc, wrempty, wrfull;
// signal from DUT get wires
wire wrclk, wrreq, abclk, mytest;
wire [15:0] audiodata;

assign abclk = bclk;

// instantiate the DUT
audio2fifo DUT (
   .reset(reset),
   .start2fill(start2fill),
   .adcdata(adcdata),
   .bclk(abclk),
   .adclrc(adclrc),
   // FIFO signals
   .wrempty(wrempty),
   .wrfull(wrfull),
   .audiodata(audiodata),
   .wrclk(wrclk),
   .wrreq(wrreq)
);

always
   #1664 adclrc = ~adclrc;   // adclrc runs at 48.0 kHz
   
always
   #26 bclk = ~bclk;   // bclk @ 48 kHz * 4.
   
initial begin
   bclk = 1'b0;
   adclrc = 1'b0;
   adcdata = 1'b0;
   wrempty = 1'b1;  // fifo empty
   wrfull = 1'b0;
   reset = 1'b0;
   start2fill = 1'b0;
   
   #60;
   reset = 1'b1;
   #60;
   reset = 1'b0;
   #100;
   start2fill = 1'b1;
   
   @(negedge adclrc );
   @(negedge bclk );
   adcdata = 1'b1;     // MSB = 
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b1;
   @(negedge bclk );
   adcdata = 1'b0;
   @(negedge bclk );
   adcdata = 1'b1;
   @(negedge bclk );
   adcdata = 1'b1;     // LSB
   @(negedge bclk );
   adcdata = 1'b0;     // no more data
   
   #3200;
   $stop;
   end
endmodule
   
   

   