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
#include "sink.h"
#include "util.h"
#include <sstream>
void sink::entry() 
{

  std::vector<sc_fixed<64,64> > input_data;

  fp_real.open(real_output_filename);
  if (strcmp(real_output_filename,imag_output_filename)) {
    fp_imag.open(imag_output_filename);
  } 

  while(true){ 
   input_data = in_data.read();
   //  real_tmp = input_data.range(in_real_high,in_real_low);
   // imag_tmp = input_data.range(in_imag_high,in_imag_low);
 
   string real_tmp_str;
   string imag_tmp_str;
   if (dw >32) {
     real_tmp_str = input_data[AV_OUT_REAL].to_string(SC_BIN);
     imag_tmp_str = input_data[AV_OUT_IMAG].to_string(SC_BIN);
     //remove the 0b at the start
     real_tmp_str.erase(0,2);
     imag_tmp_str.erase(0,2);
   } else {
     real_tmp_str = input_data[AV_OUT_REAL].to_string(SC_DEC);
     imag_tmp_str = input_data[AV_OUT_IMAG].to_string(SC_DEC);
   } 
   fp_real << real_tmp_str << endl;
   if (strcmp(real_output_filename,imag_output_filename)) {
     fp_imag << imag_tmp_str << endl;
   } else {
     fp_real << imag_tmp_str << endl;
   }
     cout.flush();
  }
 
}
