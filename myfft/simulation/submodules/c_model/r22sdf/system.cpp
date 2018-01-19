// ================================================================================
// Legal Notice: Copyright (C) 1991-2007 Altera Corporation
// Any megafunction design, and related net list (encrypted or decrypted),
// support information, device programming or simulation file, and any other
// associated documentation or information provided by Altera or a partner
// under Altera's Megafunction Partnership Program may be used only to
// program PLD devices (but not masked PLD devices) from Altera.  Any other
// use of such megafunction design, net list, support information, device
// programming or simulation file, or any other related documentation or
// information is prohibited for any other purpose, including, but not
// limited to modification, reverse engineering, de-compiling, or use with
// any other silicon devices, unless such use is explicitly licensed under
// a separate agreement with Altera or a megafunction partner.  Title to
// the intellectual property, including patents, copyrights, trademarks,
// trade secrets, or maskworks, embodied in any such megafunction design,
// net list, support information, device programming or simulation file, or
// any other related documentation or information provided by Altera or a
// megafunction partner, remains with Altera, the megafunction partner, or
// their respective licensors.  No other licenses, including any licenses
// needed under any third party's intellectual property, are provided herein.
// ================================================================================
//
#define SC_INCLUDE_FX

#include "systemc.h"
#include "fft.h"
#include "source.h"
#include "system.h"
#include "sink.h"
#include <alt_cusp.h>
#include <iostream>
using namespace std;

System::System(sc_module_name sc_name_, int in_dw_, int out_dw_, int nps_, int fftpts_size_, int twidw_, 
	       int rounding_type_, int output_order_,int input_order_, int rep_,
	       char* real_input_filename_, char* imag_input_filename_, char* fftpts_input_filename_,
	       char* inverse_input_filename_, char* real_output_filename_, char* imag_output_filename_) : sc_module(sc_name_) {
  //initialise fft
  fft_inst = new fft("fft_inst", in_dw_, out_dw_, fftpts_size_, twidw_, rounding_type_, output_order_, input_order_,rep_);
  
  source_inst = new source("source", in_dw_,fftpts_size_, real_input_filename_,imag_input_filename_, 
			   fftpts_input_filename_, inverse_input_filename_, nps_, input_order_);
  sink_inst = new sink("sink", out_dw_, fftpts_size_, real_output_filename_, imag_output_filename_);
  
  //connect the source to the fft
  channel_source_fft_data = new alt_avalon_st_point_to_point_channel<std::vector<sc_fixed<64,64> > >("channel_source_fft_data");
  
  channel_fft_sink_data = new alt_avalon_st_point_to_point_channel<std::vector<sc_fixed<64,64> > >("channel_fft_sink_data");
  

  source_inst->out_data(channel_source_fft_data->getInput());
  fft_inst->in_data(channel_source_fft_data->getOutput());
  fft_inst->out_data(channel_fft_sink_data->getInput()); 
  sink_inst->in_data(channel_fft_sink_data->getOutput());
 
  
}

System::~System()
{
  // This should be done properly
}




