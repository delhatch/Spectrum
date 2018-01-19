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
#include "util.h"
#include "systemc.h"
#include "source.h"
#include <iostream>
using namespace std;

void source::entry(){ 
  FILE *fp_real, *fp_imag, *fp_fftpts, *fp_inverse;

  double* real = new double[MAX_FFTPTS];
  double* imag = new double[MAX_FFTPTS];
  int* fftpts= new int[MAX_FFTPTS];
  int* inverse= new int[MAX_FFTPTS];

  int frame_cnt, sample_cnt = 0;
  int tmp_val;
  int this_fftpts;
  int this_inverse;
 
  // if real and imaginary files have the same name then assume that real and imaginary 
  // are together in the file as alternate values
  fp_real = fopen(real_input_filename, "r");
  if (strcmp(real_input_filename,imag_input_filename)) {
    fp_imag = fopen(imag_input_filename, "r");
  } else {
    fp_imag= fp_real;
  }
  fp_fftpts = fopen(fftpts_input_filename, "r");
  fp_inverse = fopen(inverse_input_filename, "r");
  int index = 0;
  bool input_finished = false;
  // read the data from the file
  while(!input_finished) { 
   //only read in fftpts at the start of the frame
    if (index == 0) {
      // if fp_fftpts, is null, then assume the maximum block size
      if (fp_fftpts == 0) {
	tmp_val = nps;
      } else {
	if (fscanf(fp_fftpts,"%d", &tmp_val) == EOF){ 
	  cout << "Found end of Input Stream: " << fftpts_input_filename << endl;
	  input_finished = true;
	  break;
	}
      }
      this_fftpts=tmp_val;
      fftpts[frame_cnt] = tmp_val;
      
      // if fp_inverse is null, then assume the fft
      if (fp_inverse == 0) {
	tmp_val = 0;
     } else {
	if (fscanf(fp_inverse,"%d", &tmp_val) == EOF){ 
	  cout << "Found end of Input Stream: " << inverse_input_filename << endl;
	  input_finished = true;
	  break;
	}
      }
      inverse[frame_cnt] = tmp_val;
      frame_cnt++;
    }
    if (fscanf(fp_real,"%x", &tmp_val) == EOF){ 
      cout << "Found end of Input Stream: " << real_input_filename << endl;
      input_finished = true;
      break;
    }
    real[sample_cnt] = tmp_val;

    if (fscanf(fp_imag,"%x", &tmp_val) == EOF){
      cout << "Found end of Input Stream: " << imag_input_filename << endl;
      input_finished = true;
      break;
    }
    imag[sample_cnt] = tmp_val;

    sample_cnt++;
    index=(index+1)%this_fftpts;
    
  }
  int max_frame_cnt = frame_cnt;
  int max_sample_cnt = sample_cnt;

  //if the output order is bit reversed, then bit reverse the array
  //if (output_order == BIT_REVERSE) {
    //cout << "source: Bit reversing input fil\n";
    //sample_cnt = 0;
    //for (int i = 0; i < max_frame_cnt; i++) {
    //int this_fftpts=fftpts[i];
    // func_bit_reverse(&(real[sample_cnt]),&(imag[sample_cnt]),this_fftpts);
    // sample_cnt += this_fftpts;
    //}
    
  //#ifdef DEBUG_FFT
  //    cout << "source:After bit reverse The samples are : "<< endl;
  //   for (int s =0; s < max_sample_cnt; s++) {
  //     cout << "source:func_compute_fft :" << s <<" real " << real[s] << " imag " << imag[s] << endl;
  //   }
  //  cout << "source:func_compute_fft :End : "<< endl;
  //#endif
  //  }

  std::vector<sc_fixed<64,64> > output_data;
  
  index = 0;
  sample_cnt =0;
  frame_cnt = 0;
  // now write these to the fft.
  while(true) { 
   //only read in fftpts at the start of the frame
    if (index == 0) {
      // if fp_fftpts, is null, then assume the maximum block size
      if (frame_cnt == max_frame_cnt){ 
	  cout << "Found end of Input Stream: " << fftpts_input_filename << endl;
	  sc_stop();
	  break;
      }
      this_fftpts=fftpts[frame_cnt];
      this_inverse=inverse[frame_cnt];
      frame_cnt++;
    } 
    if (sample_cnt == max_sample_cnt){ 
      cout << "Found end of Input Stream: " << real_input_filename << endl;
      sc_stop();
      break;
    }
    output_data.resize(AV_IN_SIZE); 
    output_data[AV_IN_REAL] = real[sample_cnt];
    output_data[AV_IN_IMAG] = imag[sample_cnt];
    output_data[AV_IN_ERROR] = 0;
    output_data[AV_IN_FFTPTS] = this_fftpts;
    output_data[AV_IN_INVERSE] =this_inverse;
    if (index == this_fftpts - 1) {
      output_data[AV_IN_EOP] = 1;
    }else {
      output_data[AV_IN_EOP] = 0;
    }
    if (index == 0) {
      output_data[AV_IN_SOP] = 1;
  
    }else {
      output_data[AV_IN_SOP] = 0;
    } 
    out_data.write(output_data);
    
    sample_cnt++;
    index=(index+1)%this_fftpts;
       
  }


}
