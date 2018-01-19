% (C) 2001-2017 Intel Corporation. All rights reserved.
% Your use of Intel Corporation's design tools, logic functions and other 
% software and tools, and its AMPP partner logic functions, and any output 
% files from any of the foregoing (including device programming or simulation 
% files), and any associated documentation or information are expressly subject 
% to the terms and conditions of the Intel Program License Subscription 
% Agreement, Intel FPGA IP License Agreement, or other applicable 
% license agreement, including, without limitation, that your use is for the 
% sole purpose of programming logic devices manufactured by Intel and sold by 
% Intel or its authorized distributors.  Please refer to the applicable 
% agreement for further details.


% function [y, exp_out] = fft_model(x,N,INVERSE, OUTPUT_ORDER)         
%                                                                                             
%   Calculates the complex fixed-point FFT/IFFT for variable transform
%   sizes (stored in vector N) of the complex input vector x.
%
%   Uses the fixed point model of the Variable Streaming architecture.
%                                                                                             
%   Inputs:   x          : Input complex vector of length B*N, where B is                     
%                          the number of blocks over which the length-N FFT is to             
%                          be applied. If the length of the vector is not                     
%                          an integral multiple of N, zeros are                               
%                          appended to the input sequence appropriately.                      
%             N          : Transform Length                                                   
%             INVERSE    : FFT direction                                                      
%                          0 => FFT                                                           
%                          1 => IFFT
%                                                                                             
%   Outputs   y          : The transform-domain complex vector output                         
%                                                     
%                                                                                             
%   2001-2007 Altera Corporation, All Rights Reserved
%                                                                                                  
%   Automatically Generated: FFT MegaCore Function 7.1 Build IB221-RC7 May, 2007                                                                                                   
%
function [y] = fft_model(x,nps)         
% Parameterization Space    
N=256;
DATA_PREC=16;
TWIDDLE_PREC=16;
% Input is in natural order                                                           
INPUT_ORDER=1;  
% Output is in bit-reversed order
OUTPUT_ORDER=1;      
% REPRESENTATION , 1 for floating point
REPRESENTATION=0;      
INVERSE = 0;
PRUNE=[0,0,0,0,0];
y=[];           
i=1;
%for each block in the vector N, perform the transform
for i=1:length(nps)                                                                      
    rin = real(x(1:nps(i)));                                                          
    iin = imag(x(1:nps(i)));                                                                       
    [roc,ioc] = SVSfftmodel(rin,iin,DATA_PREC,TWIDDLE_PREC,N,nps(i),INVERSE, INPUT_ORDER, OUTPUT_ORDER,REPRESENTATION,PRUNE);      
    y = [y, roc+j*ioc]   ;
    %remove block from input vector
    x=x(nps(i)+1:end);  
end                                                                                           

