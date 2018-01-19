# (C) 2001-2017 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other 
# software and tools, and its AMPP partner logic functions, and any output 
# files from any of the foregoing (including device programming or simulation 
# files), and any associated documentation or information are expressly subject 
# to the terms and conditions of the Intel Program License Subscription 
# Agreement, Intel FPGA IP License Agreement, or other applicable 
# license agreement, including, without limitation, that your use is for the 
# sole purpose of programming logic devices manufactured by Intel and sold by 
# Intel or its authorized distributors.  Please refer to the applicable 
# agreement for further details.


#!/bin/sh
# Static library generation http://www.linux.com/howtos/Program-Library-HOWTO/more-examples.shtml

# Create static library's object file, libSfftmodel.o.
gcc -Wall -g -c -o libSfftmodel.o Sfftmodel.c

# Create static library.
ar rcs libSfftmodel.a libSfftmodel.o

# Compile to output file
gcc -Wall -g -c model.c -o model.o

#generate tjhe excuted file
gcc -g -o model model.o -L. libSfftmodel.a -lm 

#nps=128;
#mpr=16;
#twr=16;
#direction=0;
#arch=2;
#throughput=4;

# Execute the program.
./model


	
