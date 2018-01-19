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
#ifndef SINK_H
#define SINK_H

#include <alt_cusp.h>
#include "systemc.h"
#include <iostream>
#include <fstream>
using namespace std;

SC_MODULE(sink) {
 public:
  ALT_AVALON_ST_INPUT<std::vector<sc_fixed<64,64> > > in_data;
 
  ofstream fp_real;
  ofstream fp_imag;

  SC_HAS_PROCESS(sink);

  sink(sc_module_name sc_name_, int dw_, int fftpts_size_, char* real_output_filename_, char* imag_output_filename_): sc_module(sc_name_){
    dw = dw_;
    fftpts_size = fftpts_size_;
    real_output_filename = real_output_filename_;
    imag_output_filename = imag_output_filename_;
    SC_THREAD(entry);//, CLK.pos());
  }


  ~sink() {
    fp_real.close();
    fp_imag.close();
  }
  
  void entry(); 
  
 private:
  int dw;
  int fftpts_size;
  char* real_output_filename;
  char* imag_output_filename;
};
#endif
