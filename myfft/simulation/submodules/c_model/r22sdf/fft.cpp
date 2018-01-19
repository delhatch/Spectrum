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
#define TWO_PI 6.283185307179586476925286766559
#define RND_CONV 1
#define TRN_0 0
#define COUT_FMT SC_DEC
#define FIXEDPT 0
#define FLOATPT 1
#ifndef _USE_MATH_DEFINES
#define _USE_MATH_DEFINES
#endif
/* This is the implementation file for the synchronous process "fft" */
#include <iostream>
#include "util.h"
#include "fpCompiler.h"
#include "systemc.h"
#include "fft.h"
#include <cmath>
#include <stdio.h>
#include <stdlib.h>
#ifdef MEX_COMPILE
#include "mex.h"
#endif

using namespace std;
extern void _main();

//Function for butterfly computation
FFT_NAME::FFT_NAME(sc_module_name sc_name_, int in_dw_, int out_dw_, int fftpts_size_, int twidw_, 
	 int rounding_type_, int output_order_, int input_order_, int rep_, double* prune_): sc_module(sc_name_) {
    in_dw = in_dw_;
    out_dw=out_dw_;
    fftpts_size=fftpts_size_;
    twidw=twidw_;
    rounding_type = rounding_type_;
    output_order = output_order_;
    input_order = input_order_;
    representation = rep_;
    
    //derived parameters
    max_fftpts = 1<<(fftpts_size_-1);
    max_pwr_2 = log2_int(max_fftpts) % 2;//(bool)((int)ceil(log2(max_fftpts)) % 2);
    max_num_stages=(int)ceil(double((log((double)max_fftpts)/log(2.0))/log2_int(4)));
    cma_datawidths = new int[max_num_stages];
    calc_all_cma_datawidths(prune_);
   
    if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER) {
#ifdef DEBUG_FFT
      cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using natural-order inputs.\n";
#endif
      bit_reverse_core = false;
    } else {
#ifdef DEBUG_FFT
      cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using bit-reversed inputs.\n";
#endif
      bit_reverse_core = true;
    }
#ifndef MEX_COMPILE
#ifndef LIB_COMPILE
    real_pts = NULL;
    imag_pts = NULL;
    real_pts_cpy = NULL;
    imag_pts_cpy = NULL;
    SC_THREAD(entry);//, CLK.pos());
#endif
#endif
    //dont_initialize();
  }


//Function for butterfly computation
FFT_NAME::FFT_NAME(sc_module_name sc_name_, int in_dw_, int out_dw_, int fftpts_size_, int twidw_, 
	 int rounding_type_, int output_order_, int input_order_, int rep_): sc_module(sc_name_) {
    in_dw = in_dw_;
    out_dw=out_dw_;
    fftpts_size=fftpts_size_;
    twidw=twidw_;
    rounding_type = rounding_type_;
    output_order = output_order_;
    input_order = input_order_;
    representation = rep_;

    //derived parameters
    max_fftpts = 1<<(fftpts_size_-1);
    max_pwr_2 = log2_int(max_fftpts) % 2;//(bool)((int)ceil(log2(max_fftpts)) % 2);
    max_num_stages=(int)ceil(double((log((double)max_fftpts)/log(2.0))/log2_int(4)));
    cma_datawidths = new int[max_num_stages];
    double* prune = new double[max_num_stages];
    for (int i=0; i< max_num_stages; i++) {
      prune[i] = 0;
    }
    calc_all_cma_datawidths(prune);


    if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER) {
#ifdef DEBUG_FFT
      cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using natural-order inputs.\n";
#endif
      bit_reverse_core = false;
    } else {
#ifdef DEBUG_FFT
      cout << "fft: SVSfftmodel: Transform size: " << this_fftpts << " using bit-reversed inputs.\n";
#endif
      bit_reverse_core = true;
    }
#ifndef MEX_COMPILE
#ifndef LIB_COMPILE
    real_pts = NULL;
    imag_pts = NULL;
    real_pts_cpy = NULL;
    imag_pts_cpy = NULL;
    SC_THREAD(entry);//, CLK.pos());
#endif
#endif
    //dont_initialize();
  }

FFT_NAME::~FFT_NAME() {
    #ifndef MEX_COMPILE
#ifndef LIB_COMPILE
    delete [] real_pts;
    delete [] imag_pts;
    delete [] real_pts_cpy;
    delete [] imag_pts_cpy;
    delete [] cma_datawidths;
#endif
    #endif
  }

void FFT_NAME::setThisFftpts(int fftpts_){
 this_fftpts=fftpts_;  
 // set effective fftpts, and radix_2_lp
 if (((log2_int(this_fftpts)) % 2 ) == 1 ) {
   //effectively the same hardware as the transform of 2x size
   effective_fftpts=2*this_fftpts;
   radix_2_lp = true;
 }else {
   radix_2_lp = false;
   effective_fftpts = this_fftpts;
 }
   
}

void FFT_NAME::setThisInverse(int inverse_) {
 this_inverse = inverse_;   
}

int FFT_NAME::getThisFftpts(){
 return this_fftpts;   
}

int FFT_NAME::getThisInverse() {
 return this_inverse;   
}

void FFT_NAME::func_radix_2_fixedpt_bfI (double* real, double* imag, int delay, int dw){

  for (int i=0; i <= ((this_fftpts/(delay*2))-1); i++) {
    for (int k=0; k <=(delay-1); k++) {
      int j = (delay*2*i) + k;
      double real_tmp_l = real[j] + real[j+delay];
      double imag_tmp_1 = imag[j] + imag[j+delay];
      double real_tmp_h = real[j] - real[j+delay];
      double imag_tmp_h = imag[j] - imag[j+delay];
      real[j] = real_tmp_l;
      imag[j] = imag_tmp_1;
      real[j+delay] = real_tmp_h;
      imag[j+delay] =  imag_tmp_h;
    }
  }
  print_fixedpt_values(real, imag, dw, "func_compute_fft: in bfi", 0, 32);
  
}

void FFT_NAME::func_radix_2_floatpt_bfI (double* real, double* imag, int delay, int dw){

  fpCompiler real_out(0);
  fpCompiler imag_out(0);
  fpCompiler real_out_delay(0);
  fpCompiler imag_out_delay(0);
  for (int i=0; i <= ((this_fftpts/(delay*2))-1); i++) {
    for (int k=0; k <=(delay-1); k++) {
      int j = (delay*2*i) + k;
      float real_in_float = real[j];
      float imag_in_float = imag[j];
      float real_in_delay_float = real[j+delay];
      float imag_in_delay_float = imag[j+delay];
      fpCompiler real_in(real_in_float);
      fpCompiler imag_in(imag_in_float);
      fpCompiler real_in_delay(real_in_delay_float);
      fpCompiler imag_in_delay(imag_in_delay_float);
     
      real_out =  real_in + real_in_delay;
      imag_out =  imag_in + imag_in_delay;
    
      real_out_delay = real_in - real_in_delay;
      imag_out_delay = imag_in - imag_in_delay;

      real[j] = real_out;
      imag[j] = imag_out;
      real[j+delay] = real_out_delay;
      imag[j+delay] =  imag_out_delay;
    }
  }
  
}
void FFT_NAME::func_radix_2_fixedpt_bfII (double* real, double* imag, int delay, int dw){
   
  //perform the trivial multiplication
  int ctr=0;
  int triv=0;
  int triv_delay = 0;
  if (input_order == BIT_REVERSE) {
    triv_delay = delay/2;
  } else {
    triv_delay=delay;
  }
  triv = 3*triv_delay;
  if (delay == 0 ) {
    return;
  }
  for (int k = 0; k < this_fftpts; k++) {
    ctr=ctr%(triv_delay*4);
    if (ctr >= triv) {
      double real_tmp = imag[k];
      imag[k] = -real[k];
      real[k] = real_tmp;
    }
    ctr=ctr+1;
  }
  for (int m=0; m <=(this_fftpts/(delay*2)-1); m++) {
    for (int k=0; k <= delay-1; k++) {
      int j=(delay*2*m)+k ;
      double real_tmp_l = real[j] + real[j+delay];
      double imag_tmp_1 = imag[j] + imag[j+delay];
      double real_tmp_h = real[j] - real[j+delay];
      double imag_tmp_h = imag[j] - imag[j+delay];
      real[j] = real_tmp_l;
      imag[j] = imag_tmp_1;
      real[j+delay] = real_tmp_h;
      imag[j+delay] =  imag_tmp_h;
    }
  }
 
}
void FFT_NAME::func_radix_2_floatpt_bfII (double* real, double* imag, int delay, int dw){
   
  //perform the trivial multiplication
  int ctr=0;
  int triv=0;
  int triv_delay = 0;
  if (input_order == BIT_REVERSE) {
    triv_delay = delay/2;
  } else {
    triv_delay=delay;
  }
  triv = 3*triv_delay;
  if (delay == 0 ) {
    return;
  }
 
  fpCompiler real_out(0);
  fpCompiler imag_out(0);
  fpCompiler real_out_delay(0);
  fpCompiler imag_out_delay(0);
  for (int i=0; i <= ((this_fftpts/(delay*2))-1); i++) {
    for (int k=0; k <=(delay-1); k++) {
      int j = (delay*2*i) + k;
      float real_in_float = real[j];
      float imag_in_float = imag[j];
      float real_in_delay_float = real[j+delay];
      float imag_in_delay_float = imag[j+delay];
      fpCompiler real_in(real_in_float);
      fpCompiler imag_in(imag_in_float);
      fpCompiler real_in_delay(real_in_delay_float);
      fpCompiler imag_in_delay(imag_in_delay_float);
      if ((j+delay)%(triv_delay*4) >= triv) {
	real_out =  real_in + imag_in_delay;
	imag_out =  imag_in - real_in_delay;
    
	real_out_delay = real_in - imag_in_delay;
	imag_out_delay = imag_in + real_in_delay;
      }else{
	real_out =  real_in + real_in_delay;
	imag_out =  imag_in + imag_in_delay;
    
	real_out_delay = real_in - real_in_delay;
	imag_out_delay = imag_in - imag_in_delay;
      }
      real[j] = real_out;
      imag[j] = imag_out;
      real[j+delay] = real_out_delay;
      imag[j+delay] =  imag_out_delay;
    }
  }
 
}
int FFT_NAME::func_gen_fixedpt_twids(double* twid_real,double* twid_imag, int stage){
  //determine how many rom points in this stage

   int rom_pts=(int)(effective_fftpts/(pow(4.0,stage)));
   int ma[3] = {effective_fftpts/rom_pts*2,
		effective_fftpts/rom_pts*1,
		effective_fftpts/rom_pts*3};
  int addr = 0;
  int mag_twid=(int)pow(2.0,(twidw-1)) -1;
  //first n/4 points are 1
  for(int n=0; n < rom_pts/4; n++) {
    //double one_scaled=round(1*mag_twid);
    double one_scaled=floor(1*mag_twid + 0.5);
    twid_real[addr] = one_scaled;
    twid_imag[addr] = 0.0;
    addr++;
  }
  for (int m = 0; m <= 2; m++) {
    for (int n=0; n <= (rom_pts/4-1); n++) {
      double exp_real=cos(-1*TWO_PI*n*ma[m]/((double)effective_fftpts));
      double exp_imag=sin(-1*TWO_PI*n*ma[m]/((double)effective_fftpts));
      twid_real[addr] = floor(exp_real*mag_twid +0.5); 
      twid_imag[addr] = floor(exp_imag*mag_twid+0.5);
      addr++;
    }
  }
#ifdef DEBUG_FFT
     print_fixedpt_values(twid_real, twid_imag,twidw, "func_gen_fixedpt_twids", stage, addr) ;
#endif
   return rom_pts;
}

int FFT_NAME::func_gen_floatpt_twids(double* twid_real,double* twid_imag, int stage){
  //determine how many rom points in this stage

   int rom_pts=(int)(effective_fftpts/(pow(4.0,stage)));
   int ma[3] = {effective_fftpts/rom_pts*2,
		effective_fftpts/rom_pts*1,
		effective_fftpts/rom_pts*3};
  int addr = 0;
  //first n/4 points are 1
  const double TWO_PI_F = M_PI*2;
  for(int n=0; n < rom_pts/4; n++) {
    twid_real[addr] = 1.0;
    twid_imag[addr] = 0.0;
    addr++;
  }
  for (int m = 0; m <= 2; m++) {
    for (int n=0; n <= (rom_pts/4-1); n++) {
      double exp_real=cos(-1*TWO_PI_F*n*ma[m]/((double)effective_fftpts));
      double exp_imag=sin(-1*TWO_PI_F*n*ma[m]/((double)effective_fftpts));
      twid_real[addr] = (float)exp_real;
      twid_imag[addr] = (float)exp_imag;
      addr++;
    }
  }
#ifdef DEBUG_FFT
    print_floatpt_values(twid_real, twid_imag,32, "func_gen_floatpt_twids", stage, addr) ;
#endif
   return rom_pts;
}



void FFT_NAME::fft_floatpt_kernel(double* real, double* imag, double* real_twid, double* imag_twid, int delay, int dw, int num_twids) {

  for (int m=0; m < this_fftpts; m++) {
    int grp = m/delay; 
    int index = m%delay;

    float real_in_float = real[m];
    float imag_in_float = imag[m];

    float real_in_delay_float = 0;
    float imag_in_delay_float = 0;
    if ((m -delay) >= 0) {
       real_in_delay_float = real[m-delay];
       imag_in_delay_float = imag[m-delay];
    }
    float real_twid_in_float = real_twid[m%num_twids];
    float imag_twid_in_float = imag_twid[m%num_twids];
    // if this is a radix 2 size fft then we need to take only evey 2nd memory address in the twiddle memory
    if (radix_2_lp) {
      real_twid_in_float = real_twid[(2*m)%num_twids];
      imag_twid_in_float = imag_twid[(2*m)%num_twids];
    }
 
    //cout << "real_in is            ";
    fpCompiler real_in(real_in_float);
    //cout << "imag_in is            ";
    fpCompiler imag_in(imag_in_float);
    
    // cout << "real_in_delay is      ";
    fpCompiler real_in_delay(real_in_delay_float);
    //cout << "imag_in_delay is      ";
    fpCompiler imag_in_delay(imag_in_delay_float);

    //cout << "real_twid_in_float is ";
    fpCompiler real_twid_in(real_twid_in_float);
    //cout << "imag_twid_in_float is ";
    fpCompiler imag_twid_in(imag_twid_in_float);
  
    //cout << "real_out is           ";
    fpCompiler real_out(0);
    //cout << "imag_out is           ";
    fpCompiler imag_out(0);

    // cout << "real_out_delay is     ";
    fpCompiler real_out_delay(0);
    //cout << "imag_out_delay is     ";
    fpCompiler imag_out_delay(0);
 
    //cout << " real_in_float " << real_in_float << " imag_in_float " << imag_in_float ;
    
    // twiddles for this computation
    //cout << "real_mult is          ";
    fpCompiler real_mult(0);
    real_mult = real_in*real_twid_in - imag_in*imag_twid_in;
    //cout << "imag_mult is          ";
    fpCompiler imag_mult(0);
    imag_mult = imag_in*real_twid_in + real_in*imag_twid_in;
    //cout << "real_mult " << real_mult << " imag_mult " << imag_mult <<endl;
    
    //butterfly addtitions/subtractions
    real_out =  real_in_delay - real_mult;
    imag_out =  imag_in_delay - imag_mult;
    
    real_out_delay = real_mult + real_in_delay;
    imag_out_delay = imag_mult + imag_in_delay;
    //decide what to do with the computations
    if (grp%2 == 0) {
      //pass through
      real[m] = real_mult;
      imag[m] = imag_mult;
      float freal = (float)real[m];
      float fimag = (float)imag[m];
      sc_fixed<32,32> fpbinreal = floatToBin(&freal, sizeof(freal));
      sc_fixed<32,32> fpbinimag = floatToBin(&fimag, sizeof(fimag));
      //cout << "**************** Setting real["<<m<<"] to " << real[m] << "(" <<  fpbinreal.to_string(SC_HEX) <<")" << " imag["<<m<<"] to " << imag[m] << "(" <<  fpbinimag.to_string(SC_HEX) <<")"<< endl;
   } else {  
      real[m] = real_out;
      imag[m] = imag_out;
      real[m-delay]=real_out_delay;
      imag[m-delay]=imag_out_delay;
      float freal = (float)real[m];
      float fimag = (float)imag[m];
      sc_fixed<32,32> fpbinreal = floatToBin(&freal, sizeof(freal));
      sc_fixed<32,32> fpbinimag = floatToBin(&fimag, sizeof(fimag));
      //cout << "*************** Setting real["<<m<<"] to " << real[m] << "(" <<  fpbinreal.to_string(SC_HEX) <<")";
      //cout << " imag["<<m<<"] to " << imag[m] << "(" <<  fpbinimag.to_string(SC_HEX) <<")" << endl;
      float freald = (float)real[m-delay];
      float fimagd = (float)imag[m-delay];
      sc_fixed<32,32> fpbinreald = floatToBin(&freald, sizeof(freald));
      sc_fixed<32,32> fpbinimagd = floatToBin(&fimagd, sizeof(fimagd));
      // cout << "*************** Setting real["<<m-delay<<"] to " << real[m-delay] << "(" <<  fpbinreald.to_string(SC_HEX) <<")";
      // cout << " imag["<<m-delay<<"] to " << imag[m-delay] << "(" <<  fpbinimagd.to_string(SC_HEX) <<")"<<endl;
    }
    
  }
  
  print_floatpt_values((double*)real, (double*)imag, dw, "func_compute_fft: after fft kernel", 0,this_fftpts);
  

}



void FFT_NAME::fft_fixedpt_kernel(double* real, double* imag, double* real_twid, double* imag_twid, int delay, int dw, int num_twids) {
  // combine bfi, multiplication into single operation
  /*
    Complex multiplication (x+iy)*(a+ib)= xa -yb + i(ya +xb), followed by butterfly additions and subtractions
    
    Switch to sc_fix to perform the multiplication. The output is rounded down, which for the parameter 
    combinations possible, will always result in a number that can be represented as a double. 
    So only the complex multiplication  needs to be done in sc_fix format.
  */
  //dw=32;
  
  //twiddle fixed point type
  sc_fxtype_params param_twid_conv(twidw,twidw,SC_RND_CONV, SC_WRAP);
  sc_fxtype_context twid_conv_cxt(param_twid_conv, SC_LATER);
  twid_conv_cxt.begin();
  sc_fix real_twid_in;
  sc_fix imag_twid_in;
  //cout << "delay is " << delay << endl;
  for (int m=0; m < this_fftpts; m++) {
    int grp = m/delay; 
    int index = m%delay;
    //cout << "m is  "<< m <<" grp is " << grp  << " index is " << index; 

    //data fixed point type, multiplication size
    sc_fxtype_params param_data_mult_conv(dw,dw,SC_RND_CONV, SC_WRAP);
    sc_fxtype_params param_data_bfi_conv(dw+1,dw+1,SC_RND_CONV, SC_WRAP);
    sc_fxtype_context data_mult_cxt(param_data_mult_conv, SC_LATER);
    sc_fxtype_context data_bfi_cxt(param_data_bfi_conv, SC_LATER);
    //multiplication fixed point type
    sc_fxtype_params param_mult_conv(dw+twidw+1,dw+twidw+1,SC_RND_CONV, SC_WRAP);
    sc_fxtype_context mult_conv_cxt(param_mult_conv, SC_LATER);
    
    data_mult_cxt.begin();
    
    sc_fix real_in = real[m];
    sc_fix imag_in = imag[m];

    sc_fix real_in_delay = 0;
    sc_fix imag_in_delay = 0;
    if ((m -delay) >= 0) {
      real_in_delay = real[m-delay];
      imag_in_delay = imag[m-delay];
    }

    // if this is a radix 2 size fft then we need to take only evey 2nd memory address in the twiddle memory
    
    if (!radix_2_lp) {
      real_twid_in = real_twid[m%num_twids];
      imag_twid_in = imag_twid[m%num_twids];
      //cout << " twid index " << m ;
    } else {
      real_twid_in = real_twid[(2*m)%num_twids];
      imag_twid_in = imag_twid[(2*m)%num_twids];
      //cout << " twid index " << 2*m ;
    }
    mult_conv_cxt.begin();

    //cout << "   real_in " << real_in << " imag_in " << imag_in ;
    
    // twiddles for this computation
    sc_fix real_mult = (real_in*real_twid_in - imag_in*imag_twid_in);
    sc_fix imag_mult = (imag_in*real_twid_in + real_in*imag_twid_in);
    
    //cout << "  before rounding real_mult " << real_mult << " imag_mult " << imag_mult ;
    
    real_mult = real_mult>>(twidw-1);
    imag_mult = imag_mult>>(twidw-1);
    
    //cout << " real_mult " << real_mult << " imag_mult " << imag_mult ;
    
    data_bfi_cxt.begin();

    sc_fix real_out;
    sc_fix imag_out;

    sc_fix real_out_delay;
    sc_fix imag_out_delay;

 //butterfly addtitions/subtractions
    real_out =  real_in_delay - real_mult;
    imag_out =  imag_in_delay - imag_mult;
    
    real_out_delay = real_mult + real_in_delay;
    imag_out_delay = imag_mult + imag_in_delay;
    
    //decide what to do with the computations
    if (grp%2 == 0) {
      //pass through
      real[m] = real_mult;
      imag[m] = imag_mult ;
      //cout << " pass through setting real["<<m<<"] to " << real[m] << " imag["<<m<<"] to " << imag[m] << endl;
    } else {
      real[m] = real_out;
      imag[m]=imag_out;
      real[m-delay]=real_out_delay;
      imag[m-delay]=imag_out_delay;
      //cout << " perfoming multiplication setting real["<<m<<"] to " << real[m] << " imag["<<m<<"] to " << imag[m];
      //cout << " real["<<m-delay<<"] to " << real[m-delay] << " imag["<<m-delay<<"] to " << imag[m-delay] << endl;
    }
    
    
    
  }
  
  print_fixedpt_values(real, imag, dw+1, "func_compute_fft: after fft kernel", 0, this_fftpts);
  
  
}

void FFT_NAME::print_fixedpt_values(double* real, double* imag, int this_dw, string func_name, int stage, int size) {
#ifdef DEBUG_FFT
  cout << "fft: fixed pt" << func_name << ": stage: " << stage << ": dw: " << this_dw << endl;
  for (int s =0; s < size; s++) {
    sc_fix  real_tmp(this_dw,this_dw);
    sc_fix  imag_tmp(this_dw,this_dw);
    real_tmp = real[s] ;
    imag_tmp =imag[s];
    cout << "fft:" << func_name << ": " << s ;
    cout << " real " << real_tmp.to_string(COUT_FMT);
    cout << " imag " <<imag_tmp.to_string(COUT_FMT) << endl;
  }
  cout << "fft:" << func_name << ": End " << endl;
#endif
}
void FFT_NAME::print_floatpt_values(double* real, double* imag, int this_dw, string func_name, int stage, int size) {
#ifdef DEBUG_FFT
  cout << "fft:" << func_name << ": stage: " << stage << endl;
  for (int s =0; s < size; s++) {
    float freal = (float)real[s];
    float fimag = (float)imag[s];
    sc_fixed<32,32> fpbinreal = floatToBin(&freal, sizeof(freal));
    sc_fixed<32,32> fpbinimag = floatToBin(&fimag, sizeof(fimag));
    cout.precision(8);
    cout.width(15);
    //cout.fill('0');
    cout << "real\t" << real[s] << "   \t(" << fpbinreal.to_string(SC_HEX) <<")   \t";
    cout << "imag\t" << imag[s] << "   \t(" << fpbinimag.to_string(SC_HEX) <<")" << endl;
  }
  cout << "fft:" << func_name << ": End " << endl;
#endif
}


bool FFT_NAME::perform_mult(int num_stages, int this_stage) {
  //if bit reverse
  int max_num_stages = (int)ceil(log2_int(max_fftpts)/(double)log2_int(4)); 
#ifdef DEBUG_FFT
  cout << "perfom_mult: this_stage " << this_stage << "is_first_stage " << is_first_stage(num_stages,this_stage);
  cout <<" num_stages " << num_stages;
  cout << " max_num_stages " << max_num_stages << " radix_2_lp " << radix_2_lp;
  cout << " max_pwr_2 " << max_pwr_2 << endl;
#endif
  if (bit_reverse_core) {
    // No multiplicaiton in the first stage unless we have max_pwr_2 = 1 and 
    // fftpts which is a pwr of 4. in this case the first bf is bypassed and the
    // first operation is a multiplicaiton by 1.
    if  (
	 is_first_stage(num_stages,this_stage) && !(!radix_2_lp && max_pwr_2)
	 ) {
      return false;
    }
    return true;
  }else {
    //first stage has a multiplication by 1 if it is  not the absolute first stage. 
    //if it i sthe first stage, then only do the multiplication
    if (
	(!is_first_stage(num_stages,this_stage) &&
	((this_stage < num_stages) || (( this_stage == num_stages) && ( !radix_2_lp  && max_pwr_2)))) || 
	(is_first_stage(num_stages,this_stage) && ( num_stages != max_num_stages) && 
	 !(num_stages == max_num_stages - 1 && !radix_2_lp && max_pwr_2))
	)
	{
      return true;
    }
    return false;
  }

}

bool FFT_NAME::perform_bfii(int num_stages, int this_stage) {
  //if bit reverse
  int max_num_stages = (int)ceil(log2_int(max_fftpts)/(double)log2_int(4)); 
  if (bit_reverse_core) {
    //second stage bf unit. The bfii unit is not used if
    // 1. This is the first stage(absolute) and max_nps is a power of 4, and nps is a power of 2
    // 2. This is the first stage(absolute) and max_nps is a power of 2, and nps is a power of 2
    if ((is_first_stage(num_stages,this_stage) &&
	  ( (radix_2_lp && max_pwr_2 ) || (!max_pwr_2 && radix_2_lp)))){
      return false;
    }
    return true;
  }else {
    //second stage bf unit. If the last stage is radix 2 then no bfII
    if (! ( (this_stage == num_stages - 1) && radix_2_lp ))  {
      return true;
    }
    return false;
  }
}

void FFT_NAME::inverse_data(double* &real, double* &imag) {
    double* tmp_imag = imag;
    imag = real;
    real = tmp_imag;
}


int FFT_NAME::calc_delay(int this_stage_delay){
  if (bit_reverse_core) {
    return this_stage_delay*2;
  }else {
    return this_stage_delay/2;
  }
}
bool FFT_NAME::is_first_stage(int num_stages,int stage) {
  if (bit_reverse_core) {
    if (stage==num_stages){
      return true;
    }
    return false;
  }else {
    if (stage == 0){
      return true;
    }
    return false;
  }

}

void FFT_NAME::calc_all_cma_datawidths(double* prune){
  //this is for the maximum size.
  //start with input datawidth, contains the input datawidth to each stage
  int datawidth=in_dw;

  //the datawidht at the output of the complex multiplier is calcuated
  cma_datawidths[0] = in_dw;
  for (int i=0; i< max_num_stages; i++) {
    //odd number of stages, pwr 4
    if ((max_num_stages % 2 == 1) && ! max_pwr_2 ){
      //last stage always returns 3, otherwise alternate stages return 3.
      if (i == max_num_stages - 1) {
        cma_datawidths[i] = datawidth + 1 - (int)prune[i];
	datawidth = datawidth + 3 - (int)prune[i];
      }else {
	if (i % 2 == 1) {
	  cma_datawidths[i] = datawidth + 1 - (int)prune[i];
	  datawidth = datawidth + 3 - (int)prune[i];
	}else {
	  cma_datawidths[i] =datawidth - (int)prune[i];
	  datawidth=datawidth + 2 - (int)prune[i];
	}
      }
    }
    
    //odd number of stages, pwr 2
    else if ((max_num_stages % 2 == 1) &&  max_pwr_2 ){
     if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER){
	//alternate stages return 3, last stage (radix 2) returns 2.
	if (i % 2 == 1) {
	  cma_datawidths[i] = datawidth + 1 - (int)prune[i];
	  datawidth = datawidth + 3 - (int)prune[i];
	}else {
	  cma_datawidths[i] = datawidth + 1 -(int)prune[i];
	  datawidth = datawidth + 2 - (int)prune[i];
	}	  
      } else {
	//first stage returns 1, last stage returns 3, alternate stages, return 3
	if (i == 0) {
	  cma_datawidths[i] = datawidth - (int)prune[i];
	  datawidth = datawidth + 1  - (int)prune[i];
	}else if (i == max_num_stages - 1 ){
	  cma_datawidths[i] = datawidth + 1 - (int)prune[i];
	  datawidth = datawidth + 3 -(int)prune[i];
	}else {
	  if (i % 2 == 1) {
	    cma_datawidths[i] = datawidth + 1 - (int)prune[i];
	    datawidth = datawidth + 3 - (int)prune[i];
	  }else {
	    cma_datawidths[i] = datawidth - (int)prune[i];
	    datawidth = datawidth + 2 - (int)prune[i];
	  }	  
	}
      }
    }
    
    //even number of stages, pwr 4
    else if ((max_num_stages % 2 == 0) && ! max_pwr_2 ) {
     //alternate stages return 3
      if (i % 2 == 1) {
	cma_datawidths[i] =datawidth + 1 - (int)prune[i];
	datawidth = datawidth + 3 - (int)prune[i];
      }else {
	cma_datawidths[i] =datawidth - (int)prune[i];
	datawidth = datawidth + 2 - (int)prune[i];
      }	  
    }
    
    //even number of stages, pwr 2
    else if ((max_num_stages % 2 == 0) && max_pwr_2 ){
       if (input_order == NATURAL_ORDER || input_order == DC_CENTER_ORDER){
	//last stage (radix 2) returns 2, alternate stages return 3
	if (i == max_num_stages - 1){
	  cma_datawidths[i] =datawidth+1- (int)prune[i];
	  datawidth = datawidth + 2- (int)prune[i];
	} else {
	  if (i % 2 == 1) {
	    cma_datawidths[i] =datawidth+1- (int)prune[i];
	    datawidth = datawidth + 3 - (int)prune[i];
	  }else {
	    cma_datawidths[i] =datawidth + 1- (int)prune[i];
	    datawidth = datawidth + 2 - (int)prune[i];
	  }	 
	}
      }else {
	//first stage returns 1, alteranate stages retun 3
	if (i == 0) {
	  cma_datawidths[i] =datawidth - (int)prune[i];
	  datawidth=datawidth + 1 - (int)prune[i];
	} else {
	  if (i % 2 == 1) {
	    cma_datawidths[i] =datawidth+1- (int)prune[i];
	    datawidth=datawidth + 3- (int)prune[i];
	  }else {
	    cma_datawidths[i] =datawidth- (int)prune[i];
	    datawidth=datawidth + 2- (int)prune[i];
	  }	 
	}
      }
    }
    
  } 
 		
}


void FFT_NAME::calc_stage(double* real, double* imag, int& this_dw, int num_stages, int& this_stage_delay, int stage, int cma_datawidth) {
  //first stage butterfly unit, combined with multiplication, not for the first stage.
  //generate twiddles for this stage.
  double* twid_real = new double[MAX_FFTPTS];
  double* twid_imag = new double[MAX_FFTPTS];
  
   int num_twids=0;
  this_dw = cma_datawidth;
  if (perform_mult(num_stages, stage)) {
    if (representation == FIXEDPT) {
      num_twids=func_gen_fixedpt_twids(twid_real, twid_imag, stage-1);
    }else {
      num_twids=func_gen_floatpt_twids(twid_real, twid_imag, stage-1);
    }
  }

  if (!perform_mult(num_stages, stage)){//is_first_stage(num_stages,stage)) {
    if (representation == FIXEDPT) {
      this_dw ++;
      func_radix_2_fixedpt_bfI(real, imag, this_stage_delay, this_dw);
    }else {
      func_radix_2_floatpt_bfI(real, imag, this_stage_delay, this_dw);
    }
  }else {
    if (representation == FIXEDPT) {
      fft_fixedpt_kernel(real, imag, twid_real,twid_imag, this_stage_delay, cma_datawidth,num_twids);
    }else {
      fft_floatpt_kernel(real, imag, twid_real,twid_imag, this_stage_delay, cma_datawidth,num_twids);
    }
  }
  if (representation == FIXEDPT) {
    print_fixedpt_values(real, imag, this_dw, "func_compute_fft: BFI", stage, this_fftpts);
  }else {
    print_floatpt_values(real, imag, this_dw, "func_compute_fft: BFI", stage, this_fftpts);
  }
  
  //second stage bf unit. If the last stage is radix 2 then no bfII
  if (perform_bfii(num_stages, stage)) {
    this_stage_delay=calc_delay(this_stage_delay);
    //cout << "performing bfii" << endl;
    if (representation == FIXEDPT) {
      this_dw=cma_datawidth+2;
      func_radix_2_fixedpt_bfII(real, imag, this_stage_delay, this_dw);
    }else {
      func_radix_2_floatpt_bfII(real, imag, this_stage_delay, this_dw);
    }
    if (representation == FIXEDPT) {
      print_fixedpt_values(real, imag, this_dw, "func_compute_fft: BFII", stage, this_fftpts);
    }else {
      print_floatpt_values(real, imag, this_dw, "func_compute_fft: BFII", stage, this_fftpts);
    }
  }else {
    //cout << "not performing bfii" << endl;
  }
  
  this_stage_delay=calc_delay(this_stage_delay);
  delete [] twid_real;
  delete [] twid_imag;
}


void FFT_NAME::func_compute_fft(double* real, double* imag) {
  //number of stages in this transform (r22 stages, ie bfi and bfii = 1 stage)
  int num_stages=(int)ceil(log2_int(this_fftpts)/(double)log2_int(4)); 
  
  
  //determine if a radix 2 stage is needed at the last stage

  //if this is an inverse transform then we need to swap real and imag components
  if (this_inverse == 1) {
    inverse_data(real, imag);
  }
  
  int this_stage_delay=(bit_reverse_core ? 1 : this_fftpts/2);
  int this_dw = in_dw;
  
  //calc_all_cma_datawidths();

  // for each stage:  
  if (bit_reverse_core) {
    // bit reverse core
#ifdef DEBUG_FFT
      cout << "fft: func_compute_fft:Computing bit reverse" << endl;
#endif
     for (int i=num_stages - 1; i >= 0; i--) {
#ifdef DEBUG_FFT
       cout << "fft: func_compute_fft:Computing bit reverse: stage "<< i << endl;
#endif
     calc_stage( real,  imag,  this_dw, num_stages, this_stage_delay,  i+1, cma_datawidths[max_num_stages -i-1]);
    }   

  }else {
    // natural order core
#ifdef DEBUG_FFT
      cout << "fft: func_compute_fft:Computing natural" << endl;
#endif
    for (int i=0; i < num_stages; i++) {
#ifdef DEBUG_FFT
       cout << "fft: func_compute_fft:Computing nartural: stage "<< i << endl;
#endif
      calc_stage( real,  imag,  this_dw, num_stages, this_stage_delay,  i,cma_datawidths[i]);
    }   

  }

  //if this is an inverse transform then we need to swap real and imag components
  if (this_inverse == 1) {
    inverse_data(real, imag);
  }

}



void FFT_NAME::SVSfftmodel(double* real_in, double* imag_in)
{

   
    // rearrange input samples to be in natural order and use natural order FFT.
    if (input_order == DC_CENTER_ORDER) {
      //copy the top half of the array to the bottom half of the copy variables
      double* real_cpy = new double[this_fftpts];//THN: Made temporary arrays the same size as the FFT size.  Previously this was equal to MAX_FFTPTS - which means memory allocated far exceeded the requirement
      double* imag_cpy = new double[this_fftpts];//THN: See above
      memcpy( real_cpy, real_in + this_fftpts/2, (this_fftpts/2)*sizeof(double) );
      memcpy( imag_cpy, imag_in + this_fftpts/2, (this_fftpts/2)*sizeof(double) );
      //copy the bottom half of the array to the top half of the copy variables
      memcpy( real_cpy + this_fftpts/2, real_in, (this_fftpts/2)*sizeof(double) );
      memcpy( imag_cpy + this_fftpts/2, imag_in, (this_fftpts/2)*sizeof(double) );
      memcpy( real_in, real_cpy, this_fftpts*sizeof(double) );//THN: See above
      memcpy( imag_in, imag_cpy, this_fftpts*sizeof(double) );//THN: See above
      delete [] real_cpy;
      delete [] imag_cpy;      
    }
  

#ifdef DEBUG_FFT
      cout << "fft: SVSfftmodel: Computing FFT" << endl;
#endif
      func_compute_fft(real_in, imag_in);

    
    //if input order = NATURAL_ORDER then output of the FFT is bit reversed.
    //if input order = BIT_REVERSE then output of the FFT in natural order.
    //If the output order requires bit_reversing, do it here
    if ((output_order == NATURAL_ORDER && input_order == NATURAL_ORDER) ||
        (output_order == BIT_REVERSE && input_order == BIT_REVERSE) ||
	(output_order == NATURAL_ORDER && input_order == DC_CENTER_ORDER)
	) {
#ifdef DEBUG_FFT
      cout << "fft: SVSfftmodel: bit reversing the outputs" << endl;
#endif
      func_bit_reverse(real_in, imag_in, this_fftpts);

    }
return;
}

#ifndef MEX_COMPILE
#ifndef LIB_COMPILE
void FFT_NAME::entry()
{ 
 // Variable Declarations
  int index;

  std::vector<sc_fixed<64,64> > input_data;
  std::vector<sc_fixed<64,64> > output_data;
  sc_ufix fftpts_conv(fftpts_size,fftpts_size);

  real_pts = new double[MAX_FFTPTS];
  imag_pts = new double[MAX_FFTPTS];
  
  int sop = 0;
  int eop = 0;
 
  real_pts_cpy = new double[MAX_FFTPTS];
  imag_pts_cpy = new double[MAX_FFTPTS];


  int error_out = 0;
  
  while(true) { 
    index = 0; 
  
    // Read in the first sample along with the settings for inverse and fftpts
    //read in data
    input_data = in_data.read();

    // unpack this into the real/imag/sop/eop/error_in/fftpts/inverse
    if (representation == FIXEDPT) {
      real_pts[0] = double(input_data[AV_IN_REAL]);
      imag_pts[0] = double(input_data[AV_IN_IMAG]);
    }else {
      //convert the integer reprsentation into a floating point representation
      float f;
      char * floatAsChar = (char*)&f;
      itoa(input_data[AV_IN_REAL], floatAsChar, 16);
      real_pts[0] = convertHexStringToFloat(floatAsChar);
      itoa(input_data[AV_IN_IMAG], floatAsChar, 16);
      imag_pts[0] =convertHexStringToFloat(floatAsChar);
    }
#ifdef DEBUG_FFT
      if (representation == FLOATPT) {
	cout.precision(8);
      }
       cout << "fft:entry: read " << index << " real " << real_pts[0] << " imag " << imag_pts[0] << endl;
#endif
    sop = int(input_data[AV_IN_SOP]);
    eop = int(input_data[AV_IN_EOP]);
    error_out = int(input_data[AV_IN_ERROR]);
    fftpts_conv = input_data[AV_IN_FFTPTS];
    
    setThisFftpts(int(fftpts_conv));
    setThisInverse(int(input_data[AV_IN_INVERSE]));
  
    //check sop is high, otherwise flag an error
    if (sop == 0) {
      // missing sop
      error_out = 1;
    }
    if (eop == 1) {
      //unexpected eop
      error_out = 2;
    }

    index++;    
    #ifdef DEBUG_FFT
    cout << "fft:entry: Performing ";
    if (this_inverse == 0) {
      cout << " fft ";
    }else {
      cout << "ifft ";
    } 
    cout << "transform - transform size: " <<this_fftpts <<endl;
    #endif
    
    // read in the rest of the samples, ignore the sop, eop, fftpts and inverse
    while( index < this_fftpts  ) {
      input_data = in_data.read();
      if (representation == FIXEDPT) {
	real_pts[index] = double(input_data[AV_IN_REAL]);
	imag_pts[index] = double(input_data[AV_IN_IMAG]);
      }else {
	//convert the integer reprsentation into a floating point representation
	float f;
	char * floatAsChar = (char*)&f;
	itoa(input_data[AV_IN_REAL], floatAsChar, 16);
	real_pts[index] = convertHexStringToFloat(floatAsChar);
	itoa(input_data[AV_IN_IMAG], floatAsChar, 16);
	imag_pts[index] =convertHexStringToFloat(floatAsChar);
      }
      sop = int(input_data[AV_IN_SOP]);
      eop = int(input_data[AV_IN_EOP]);
      error_out = int(input_data[AV_IN_ERROR]);
      if (eop == 1 && index < this_fftpts - 1) {
        //unexpected eop
        error_out = 2;
      }else if (eop == 0 && index == this_fftpts - 1) {
        error_out = 3;
      }
#ifdef DEBUG_FFT
      if (representation == FLOATPT) {
	cout.precision(8);
      }
      cout << "fft:entry: read " << index << " real " << real_pts[index] << " imag " << imag_pts[index] << endl;
#endif
       index++;
    }
    memcpy( real_pts_cpy, real_pts, MAX_FFTPTS*sizeof(double) );
    memcpy( imag_pts_cpy, imag_pts, MAX_FFTPTS*sizeof(double) );
    
     
    SVSfftmodel(real_pts_cpy, imag_pts_cpy);

    
    //////////////////////////////////////////////////////////////////////////   
    //Writing out the normalized transform values in bit reversed order
    //////////////////////////////////////////////////////////////////////////
#ifdef DEBUG_FFT
    cout << "fft:entry: Writing the transform values..." << endl;
#endif
    index = 0;
    while( index < this_fftpts ) {
      output_data.resize(AV_OUT_SIZE); 
      //pack the data into the output vector
      output_data[AV_OUT_FFTPTS] = this_fftpts;
      if (index == this_fftpts - 1) {
        output_data[AV_OUT_EOP] = 1;
      }else {
        output_data[AV_OUT_EOP] = 0;
      }
      output_data[AV_OUT_IMAG] = imag_pts_cpy[index];
      output_data[AV_OUT_REAL] = real_pts_cpy[index];
      
      if (index == 0) {
        output_data[AV_OUT_SOP] = 1;
      }else {
        output_data[AV_OUT_SOP] = 0;
      }
      output_data[AV_OUT_ERROR] = error_out;
      out_data.write(output_data);

#ifdef DEBUG_FFT
      cout << "fft:entry: Wrote: real " <<real_pts_cpy[index] << " imag " << imag_pts_cpy[index] << endl;
#endif
      index++;
    }
#ifdef DEBUG_FFT
    cout << "fft:entry: Done..." << endl;
#endif
  }   
  
     
}// end entry() function
#endif
#endif

#ifdef MEX_COMPILE
extern "C" {
void mexFunction(int nlhs, mxArray *plhs[],
				 int nrhs, const mxArray *prhs[])
{
  double* real_in;
  double* imag_in;
  double* real_out;
  double* imag_out;
  double* real_tmp = new double[MAX_FFTPTS];
  double* imag_tmp = new double[MAX_FFTPTS];
  
  int inverse=0;
  int dw=0;
  int twidw=0;
  int nps=0;
  int max_nps=0;
  int output_order=0;
  int input_order =0;
  int representation =0;
  double* prune;
  int mrows,ncols ;
  if (nrhs != 11) {
    mexErrMsgTxt("SVSfftmodel requires eleven input arguments.");
  } else if (nlhs < 2) {
    mexErrMsgTxt("SVSfftmodel requires two output argument.");
  }
  mrows = mxGetM(prhs[0]);
  ncols = mxGetN(prhs[0]);
  
  plhs[0] = mxCreateDoubleMatrix(mrows,ncols, mxREAL);
  plhs[1] = mxCreateDoubleMatrix(mrows,ncols, mxREAL);
  
  //Inputs 
  real_in = mxGetPr(prhs[0]);
  imag_in = mxGetPr(prhs[1]);
  dw = (int)mxGetScalar(prhs[2]);
  twidw = (int)mxGetScalar(prhs[3]);
  max_nps  = (int)mxGetScalar(prhs[4]);
  nps = (int)mxGetScalar(prhs[5]);
  inverse = (int)mxGetScalar(prhs[6]);
  input_order = (int)mxGetScalar(prhs[7]);
  output_order = (int)mxGetScalar(prhs[8]);
  representation = (int)mxGetScalar(prhs[9]);
  prune = mxGetPr(prhs[10]);
  
  //Outputs 
  real_out = mxGetPr(plhs[0]);
  imag_out = mxGetPr(plhs[1]);
  
  int num_stages=(int)ceil(double(log2_int(max_nps)/log2_int(4)));
  int out_dw = dw + (int)ceil(2.5*num_stages);
  int fftpts_size=(int)ceil(double(log2_int(max_nps)))+1; 
  
  int rounding_type = RND_CONV;
  
  

  //declare an instance of the fft
  FFT_NAME this_fft("fft",dw, out_dw, fftpts_size, twidw,rounding_type,output_order, input_order,representation,
		    prune);
  
  this_fft.setThisFftpts(nps);
  this_fft.setThisInverse(inverse);
  
  memcpy( real_tmp, real_in, ncols*sizeof(double) );
  memcpy( imag_tmp, imag_in, ncols*sizeof(double) );
  
  this_fft.SVSfftmodel(real_tmp, imag_tmp);
  
  memcpy( real_out, real_tmp, ncols*sizeof(double) );
  memcpy( imag_out, imag_tmp, ncols*sizeof(double) );
  delete [] real_tmp;
  delete [] imag_tmp;
  
  return;
  
}
}
#endif
