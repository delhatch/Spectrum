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
#ifndef SOURCE_H
#define SOURCE_H

#include "systemc.h"
#include <alt_cusp.h>
#include <iostream>
using namespace std;

SC_MODULE(source) {
 public:
  ALT_AVALON_ST_OUTPUT<std::vector<sc_fixed<64,64> > > out_data;
  
  SC_HAS_PROCESS(source);

  source(sc_module_name sc_name_, int dw_, int fftpts_size_,char* real_input_filename_, char* imag_input_filename_,
	 char* fftpts_input_filename_, char* inverse_input_filename_, int nps_, int output_order_): sc_module(sc_name_)
    {
     dw = dw_;
     fftpts_size = fftpts_size_;
     real_input_filename = real_input_filename_;
     imag_input_filename = imag_input_filename_;
     fftpts_input_filename = fftpts_input_filename_;
     inverse_input_filename = inverse_input_filename_;
     nps = nps_;
     output_order = output_order_;
     SC_THREAD(entry);//, CLK.pos());
    }

 //Process Functionality: in member function below
 protected:
 void entry();
 //void func_bit_reverse(double*, double*, int);

 private:
  int dw;
  int fftpts_size;
  int nps;
  int output_order; //desired order of the input samples to the fft
  char* real_input_filename;
  char* imag_input_filename;
  char* fftpts_input_filename;
  char* inverse_input_filename;
};
#endif
