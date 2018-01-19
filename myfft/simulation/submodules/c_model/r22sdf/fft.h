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
#ifndef FFT_H
#define FFT_H

#ifndef MEX_COMPILE
#ifndef LIB_COMPILE
	#include "alt_cusp.h"
#endif
#endif
#ifndef FFT_NAME
#define FFT_NAME fft
#endif
#ifndef MEX_COMPILE
#define SC_INCLUDE_FX
#endif
#include "systemc.h"
#include "util.h"
#include "math.h"
#include <iostream>
using namespace std;

SC_MODULE(FFT_NAME) {
 public:
 #ifndef MEX_COMPILE
#ifndef LIB_COMPILE 
  ALT_AVALON_ST_INPUT<std::vector<sc_fixed<64,64> > > in_data;

  ALT_AVALON_ST_OUTPUT<std::vector<sc_fixed<64,64> > > out_data;
  
  double *real_pts, *imag_pts;
  double *real_pts_cpy, *imag_pts_cpy;

SC_HAS_PROCESS(FFT_NAME);
#endif
#endif

  FFT_NAME(sc_module_name sc_name_, int in_dw_, int out_dw_, int fftpts_size_, int twidw_, 
      int rounding_type_, int output_order_, int input_order_, int rep_ );
  FFT_NAME(sc_module_name sc_name_, int in_dw_, int out_dw_, int fftpts_size_, int twidw_, 
      int rounding_type_, int output_order_, int input_order_, int rep_ ,
      double* prune_);
      
  ~FFT_NAME();    


 void SVSfftmodel(double*,double*);
 void setThisFftpts(int);
 void setThisInverse(int);
 int getThisFftpts();
 int getThisInverse();
 void func_compute_fft(double*,double*);
 
 protected:
  void entry();
  
 private:
  void fft_fixedpt_kernel(double*,double*,double*,double*,int,int,int);
  void fft_floatpt_kernel(double*,double*,double*,double*,int,int,int);
  void func_radix_2_fixedpt_bfI (double*,double*,int,int );
  void func_radix_2_fixedpt_bfII (double*,double*,int,int );
  void func_radix_2_floatpt_bfI (double*,double*,int,int );
  void func_radix_2_floatpt_bfII (double*,double*,int,int );
  int func_gen_fixedpt_twids(double*,double*, int);
  int func_gen_floatpt_twids(double*,double*, int);
  void print_fixedpt_values(double*,double*,int,string,int,int);
  void print_floatpt_values(double*,double*,int,string,int,int);
   void calc_all_cma_datawidths(double*);
  bool perform_mult(int,int);
  bool perform_bfii(int,int);
  void inverse_data(double* &real,double* &imag);
  int calc_delay(int);
  bool is_first_stage(int,int);
  void calc_stage(double*,double*,int&,int,int&,int,int);

  //  void func_bit_reverse(double*,double*);
  int in_dw;
  int out_dw;
  int twidw;
  int fftpts_size;
  int max_fftpts;
  int rounding_type;
  int output_order;
  int input_order;
  int representation;
  bool bit_reverse_core;
  bool max_pwr_2;
  // settings for the current block
  int this_fftpts;
  int this_inverse;
  bool radix_2_lp;
  int effective_fftpts;
  int* cma_datawidths;
  int max_num_stages;

 };      
#endif


