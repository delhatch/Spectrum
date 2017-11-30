// This module interface memory-maps into the Nios processor address space.
//    It allows the Nios to read the output values of the FFT (via the dual-port RAM).
// This module instantiates and controls the audio interface, audio-to-FIFO,
//    FIFO-to-FFT, and then FFT-dual-port-RAM.
// The Nios then reads the dual-port RAM to get the data (amplitudes in each audio
//    frequency bin).  The Nios will draw the bars into the VGA memory to create
//    the image.
// Instructions for changing the FFT size (number of FFT points)
//   1) Change the three `defines below.
//   2) Generate a new FFT called "myfft"
//   3) Generate a new FIFO, with depth to match the number of FFT points. Called "audioFIFO"
//   4) Generate a new dual-port RAM, with depth to match the number of FFT points. Called "fftram"
//   5) Run "Platform Designer" and edit the "Coproc_Top" item. (Re-import the .v file. Verify that
//          the width of the Nios address bus is `FFT_BUS bits wide.)
//   6) Generate the HDL code in Platform Designer. Compile design.
//   7) Optional: Change NIOS C-code software to display the proper number of bars.

// Number of samples that the FFT works on.
`define FFT_POINTS 512
// Binary value for the number above. For example, for 32, set this to 5'b10_0000
`define FFT_POINTS_IN_BINARY 10'b10_0000_0000
// log2 of the number of points in the FFT. Used by counters of fft words. ie., for 32 points, set to 5.
`define FFT_BUS 9

module Coproc_Top (
   //	NIOS Host Side
	output [31:0] avs_s1_readdata_oDATA,
   input	[`FFT_BUS-1:0] avs_s1_address_iADDR,
	input avs_s1_read_iRD,
	input avs_s1_chipselect_iCS,
	input rsi_reset_n,
	input csi_clk,		//	Host processor clock
   // Audio codec interface
   input avs_s2_export_adcdata,
   input avs_s2_export_adclrc,    // 48.0 ksps clock
   input avs_s2_export_bclk,       // 48 kHz * 4. The audio bit clock.
   input avs_s2_export_fft_clk,
   // DEBUG SIGNALS ----------------------------------
   output wire [9:0] avs_s2_export_debug
);

wire reset = ~rsi_reset_n;
wire fifo_wrreq, fifo_wrempty, fifo_wrfull;
wire fifo_rdempty, fifo_rdfull, fifio_rdreq;
wire fft_ready2receive;
wire [15:0] data_to_fifo, data_fifo_to_fft;
wire signed [31:0] real2, imag2, sum;
wire tstart2fill, tsink_valid, tsink_sop, tsink_eop;
wire tsource_valid, tsource_error, tsource_eop, tsource_sop;
wire fifo_rdreq;
wire [`FFT_BUS-1:0] ram_wr_address;
wire signed [15:0] tsource_imag, tsource_real;
wire [15:0] power;
wire [15:0] fft_q;

assign avs_s1_readdata_oDATA = { 16'h00, fft_q[15:0] };

// The audio2fifo module takes the audio from the codec, de-serializes it, and
//    puts it into the FIFO. It automatically stops when the FIFO is full.
audio2fifo u1 (
   .reset( reset ),
   .start2fill( tstart2fill ),
   .adcdata( avs_s2_export_adcdata ),
   .bclk( avs_s2_export_bclk ),
   .adclrc( avs_s2_export_adclrc ),
   .wrempty( fifo_wrempty ),
   .wrfull( fifo_wrfull ),
   .audiodata( data_to_fifo ),
   .wrclk(),         // is just bclk. FIFO input clocked with bclk.
   .wrreq( fifo_wrreq )
);

fifo2fft #( .FFT_POINTS(`FFT_POINTS), .FFT_BUS(`FFT_BUS) )
   u2 (
   .reset( reset ),
   .clk( avs_s2_export_fft_clk ),
   .start2fill( tstart2fill ),
   .adclrc( avs_s2_export_adclrc ),
   // FIFO interface
   .fifo_rdempty( fifo_rdempty ),
   .fifo_wrempty( fifo_wrempty ),
   .fifo_rdfull( fifo_rdfull ),
   .fifo_wrfull( fifo_wrfull ),
   .fifo_rdreq( fifo_rdreq ),
   // FFT interface
   .sink_ready( fft_ready2receive ),
   .source_valid( tsource_valid ),
   .sink_valid( tsink_valid ),
   .sink_sop( tsink_sop ),
   .sink_eop( tsink_eop )
);

// FIFO. Audio in at 48 ksps. Audio out to FFT at 50 Msps.
audioFIFO u3 (
	.data( data_to_fifo ),
	.rdclk( avs_s2_export_fft_clk ),
	.rdreq( fifo_rdreq ),
	.wrclk( avs_s2_export_bclk ),
	.wrreq( fifo_wrreq ),
	.q( data_fifo_to_fft ),
	.rdempty( fifo_rdempty ),
	.rdfull( fifo_rdfull),
	.wrempty( fifo_wrempty ),
	.wrfull( fifo_wrfull )
);

myfft anfft (
   .clk( avs_s2_export_fft_clk ),
	.reset_n( rsi_reset_n ),
	.inverse( 1'b0 ),          // set the fft for forward transform
	.sink_valid( tsink_valid ),
	.sink_sop( tsink_sop ),
	.sink_eop( tsink_eop ),
	.sink_real( data_fifo_to_fft ),
	.sink_imag( 16'h0000 ),     
	.sink_error( 2'b00 ),             // The fifo is always doing it's job.
	.source_ready( 1'b1 ),        // The fifo2fft state machine is always ready for the fft to work.
	.sink_ready( fft_ready2receive ),
	.source_error( tsource_error ),
	.source_sop( tsource_sop ),
	.source_eop( tsource_eop ),
	.source_valid( tsource_valid ),
	.source_real( tsource_real ),
   .source_imag( tsource_imag ),
   .fftpts_in( `FFT_POINTS_IN_BINARY ), // example: for 32 FFT points, set to 6'b100000
   .fftpts_out()
);

Mod_counter #( .N(`FFT_BUS), .M(`FFT_POINTS) )   // N = N-bit counter, M = count modulo
   ram_wr_addr ( 
		.clk( avs_s2_export_fft_clk ),  // Must be FFT clock
		.clk_en( tsource_valid ),
		.reset( ~tsource_valid ),
		.max_tick(),              // not used
		.q( ram_wr_address ),
		.pause( 1'b0 )      // Never pause. addresses will be either held in reset by fft, or running.
 );

assign avs_s2_export_debug[9] = avs_s2_export_fft_clk;
assign avs_s2_export_debug[8] = tsource_valid;
assign avs_s2_export_debug[3:0] = ram_wr_address[3:0];
assign avs_s2_export_debug[5:4] = power[1:0];
assign avs_s2_export_debug[7] = rsi_reset_n;
assign avs_s2_export_debug[6] = tsink_valid;

fftram myram (    // Dual-port ram. Holds FFT output. Allows Nios to read values.
	.wrclock( avs_s2_export_fft_clk ),
	.data( power ),
	.rdaddress( avs_s1_address_iADDR[`FFT_BUS-1:0] ),
   .rdclock( csi_clk ),
	.rden( avs_s1_read_iRD && avs_s1_chipselect_iCS  ),
	.wraddress( ram_wr_address ),
	.wren( tsource_valid ),
	.q( fft_q )
);

// This next section calculates the power in each fft bin.
// Power = sqrt( real^2 + imag^2 )
assign real2 = tsource_real * tsource_real;
assign imag2 = tsource_imag * tsource_imag;
assign sum = real2 + imag2;

mysqrt sqrt ( 
	.radical( sum ),
	.q( power ),
	.remainder()
);

endmodule
