//	Copyright (C) 1988-2007 Altera Corporation
//	Any megafunction design, and related net list (encrypted or decrypted),
//	support information, device programming or simulation file, and any other
//	associated documentation or information provided by Altera or a partner
//	under Altera's Megafunction Partnership Program may be used only to
//	program PLD devices (but not masked PLD devices) from Altera.  Any other
//	use of such megafunction design, net list, support information, device
//	programming or simulation file, or any other related documentation or
//	information is prohibited for any other purpose, including, but not
//	limited to modification, reverse engineering, de-compiling, or use with
//	any other silicon devices, unless such use is explicitly licensed under
//	a separate agreement with Altera or a megafunction partner.  Title to
//	the intellectual property, including patents, copyrights, trademarks,
//	trade secrets, or maskworks, embodied in any such megafunction design,
//	net list, support information, device programming or simulation file, or
//	any other related documentation or information provided by Altera or a
//	megafunction partner, remains with Altera, the megafunction partner, or
//	their respective licensors.  No other licenses, including any licenses
//	needed under any third party's intellectual property, are provided herein.
//
//  Altera FFT MegaCore ver 7.1 
//
//  04/06/2007 model.c : Example FFT testbench for Hauwei
//

#include "stdio.h"
#include "fft.h"
#include "util.h"
#include "math.h"
#include "stdlib.h"
#define FFT_NAME fft
#define RND_CONV 1
#include <iostream>
#include <fstream>
using namespace std;

int main(int argc, char** argv){


  /***************************************************************************
   * Set FFT Core Parameters 
   **************************************************************************/
  const int maxN=256;   // maxN :Largest Transform Length
  int N=256;            // N : Block Transform Length
  int dw = 16;          // Input Data Precision
  int twidw=16;         // Twiddle Factor Precision
  int direction=0;      // FFT Transform direction 0 : FFT, 1 : Inverse FFT
  int input_order=1;    // FFT input order 0 : Bit Reversed, 1 : Natural Order
  int output_order=1;   // FFT output order 0 : Bit Reversed, 1 : Natural Order
  int rep=0; // FFT data representation : 0 for fixed point, 1 for floating pt

  /***************************************************************************
   * These are derived parameters. Do not change these...
   **************************************************************************/
  int num_stages=(int)ceil(double(log2_int(maxN)/log2_int(4)));
  int out_dw = dw + (int)ceil(2.5*num_stages);
  int fftpts_size=(int)ceil(double(log2_int(maxN)))+1;  
  int rounding_type = RND_CONV;
  
 
  /***************************************************************************
   * Create input data arrays to model
   **************************************************************************/
  double* real_in = new double[maxN];
  double* imag_in = new double[maxN];
  double* real_out = new double[maxN];
  double* imag_out = new double[maxN];
  int* dr_in = new int[maxN];
  int* di_in = new int[maxN];

  FILE* fidr;
  FILE* fidi;

  fidr = fopen("real_input.txt","r");
  fidi = fopen("imag_input.txt","r");
  if(fidr > 0 && fidi > 0){ 
    for(int i=0;i<N;i++){
      fscanf(fidr,"%d",&dr_in[i]);
      real_in[i] = (double)dr_in[i];
      fscanf(fidi,"%d",&di_in[i]);
      imag_in[i] = (double)di_in[i];
    }
  }else{
    printf("Error: Cannot open input files: real_input.txt imag_input.txt \n");
    exit(-1);
  }
 
  fclose(fidr);
  fclose(fidi);

 
  /****************************************************************************
   * declare an instance of the fft
   ***************************************************************************/
  FFT_NAME this_fft("fft",dw, out_dw, fftpts_size, twidw,rounding_type,output_order, input_order,rep);
  
  this_fft.setThisFftpts(N);
  this_fft.setThisInverse(direction);
  
  /****************************************************************************
   * Call to FFT
   * Input : real_data : Real Component Input : Double Array of Length N
   *         imag_data : Imaginary Component Input : Double Array of Length N 
   * Outputs are stored in real_data, imag_data.
   ***************************************************************************/
  double* real_tmp = new double[maxN];
  double* imag_tmp = new double[maxN];
  memcpy( real_tmp, real_in, N*sizeof(double) );
  memcpy( imag_tmp, imag_in, N*sizeof(double) );
  
  this_fft.SVSfftmodel(real_tmp, imag_tmp);
 
  memcpy( real_out, real_tmp, N*sizeof(double) );
  memcpy( imag_out, imag_tmp, N*sizeof(double) );

 
  /*******************************************************************************
   * Write Results to Disk
   *******************************************************************************/
   FILE* fid;
  fid = fopen("fft_test.txt","wt");
  
  fprintf(fid,"\treal_data\timag_data\n");
  for(int i=0;i<N;i++){
    fprintf(fid,"\t%d\t%d\n",(int)real_out[i],(int)imag_out[i]);
  }
  fclose(fid);
 
  return 0;

}
