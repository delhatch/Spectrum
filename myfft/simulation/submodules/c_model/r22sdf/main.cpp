/*****************************************************************************

  The following code is derived, directly or indirectly, from the SystemC
  source code Copyright (c) 1996-2004 by all Contributors.
  All Rights reserved.

  The contents of this file are subject to the restrictions and limitations
  set forth in the SystemC Open Source License Version 2.4 (the "License");
  You may not use this file except in compliance with such restrictions and
  limitations. You may obtain instructions on how to receive a copy of the
  License at http://www.systemc.org/. Software distributed by Contributors
  under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
  ANY KIND, either express or implied. See the License for the specific
  language governing rights and limitations under the License.

 *****************************************************************************/

/*****************************************************************************

  main.cpp - This file instantiates all processes and ties them together
             with signals.

  Original Author: Rashmi Goswami, Synopsys, Inc.

 *****************************************************************************/

/*****************************************************************************

  MODIFICATION LOG - modifiers, enter your name, affiliation, date and
  changes you are making here.

      Name, Affiliation, Date:
  Description of Modification:

 *****************************************************************************/

#define SC_INCLUDE_FX

#include "systemc.h"
#include "fft.h"
#include "source.h"
#include "sink.h"
#include "system.h"

int sc_main(int ac, char* av[])
{
  //input parameters are twr = twiddle precision, mpr = data precision, max_nps
  int twidw = 18;
  int in_dw = 18;
  int max_nps = 1024;
  char* real_input_filename="in_real";
  char* imag_input_filename="in_imag";
  char* fftpts_input_filename="in_fftpts";
  char* inverse_input_filename="in_inverse";
  char* real_output_filename="out_real";
  char* imag_output_filename="out_imag";
  int rounding_type=0;
  int output_order=0;
  int input_order=0;
  int rep=0;
  for (int i=0;i<ac;i++) {
    switch (i) {
    case (1) :
      in_dw = atoi(av[i]);
      break;
    case 2:
      twidw = atoi(av[i]);
      break;
    case 3:
      max_nps = atoi(av[i]);
      break;
    case 4:
      output_order = atoi(av[i]);
      break;
    case 5:
      input_order = atoi(av[i]);
      break;
    case 6:
      rep = atoi(av[i]);
      break;
    case 7:
      real_input_filename = av[i];
      break;
    case 8:
      imag_input_filename = av[i];
      break;
    case 9:
      fftpts_input_filename = av[i];
      break;
    case 10:
      real_output_filename = av[i];
      break;
    case 11:
      imag_output_filename = av[i];
      break;
    case 12:
      inverse_input_filename = av[i];
      break;
    }
  }
    
  //derived from the above parameters
  int num_stages=(int)ceil(log2(max_nps)/log2(4));
  int out_dw = in_dw + (int)ceil(2.5*num_stages);
  int fftpts_size=(int)ceil(log2(max_nps))+1; 

  // used to have a choice of rounding, now just convergent rounding
  rounding_type = 1; 

  System* sys = new System("System", in_dw,out_dw, max_nps, fftpts_size, twidw, 
			   rounding_type, output_order,input_order, rep,
			   real_input_filename, imag_input_filename, 
			   fftpts_input_filename, inverse_input_filename,
			   real_output_filename, imag_output_filename
			   );
  sc_start();

  cout << "Done .." << endl;
  return 0;
}
