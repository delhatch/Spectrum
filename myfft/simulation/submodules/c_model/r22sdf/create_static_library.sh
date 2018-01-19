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
if [-Z $SYSTEMC ]
then
    echo "ERROR: Enviroment variable \$SYSTEMC not set."
    exit
fi

if [-Z $MEGACORE_ROOT ]
then
    echo "ERROR: Enviroment variable \$MEGACORE_ROOT not set."
    exit
fi

echo "INFO: Compiling fft.cpp ................."
g++   -I/usr/include   -I$SYSTEMC/include -L$SYSTEMC/lib-linux -DLIB_COMPILE -c -o libfft.o $MEGACORE_ROOT/fft/lib/fft.cpp
if [ $? != 0 ] 
then
   echo "ERROR: Error compiling fft.cpp"
   exit
fi

echo "INFO: Compiling expression.cpp ................."
g++   -I/usr/include   -I$SYSTEMC/include -L$SYSTEMC/lib-linux -DLIB_COMPILE -c -o libexpression.o $MEGACORE_ROOT/fft/lib/expression.cpp
if [ $? != 0 ] 
then
   echo "ERROR: Error compiling fft.cpp"
   exit
fi

echo "INFO: Compiling fpCompiler.cpp ................."
g++   -I/usr/include   -I$SYSTEMC/include -L$SYSTEMC/lib-linux -DLIB_COMPILE -c -o libfpcompiler.o $MEGACORE_ROOT/fft/lib/fpCompiler.cpp
if [ $? != 0 ] 
then
   echo "ERROR: Error compiling fft.cpp"
   exit
fi

echo "INFO: Compiling util.cpp ................."
g++  -I/usr/include  -I$SYSTEMC/include -L$SYSTEMC/lib-linux -DLIB_COMPILE  -c -o libutil.o $MEGACORE_ROOT/fft/lib/util.cpp
if [ $? != 0 ] 
then
    echo "ERROR: Error compiling util.cpp"
    exit
fi
    
# Create static library.

echo "INFO: Creating static library  ................."
ar rcs libfft.a libfft.o libutil.o libexpression.o libfpcompiler.o
if [ $? != 0 ] 
then
    echo "ERROR: Unable to create library"
    exit
fi

rm *.o

# Compile demo program file.
echo "INFO: Compiling demo program ................."
g++  -I/usr/include -I$SYSTEMC/include -L$SYSTEMC/lib-linux -DLIB_COMPILE -c $MEGACORE_ROOT/fft/lib/model.cpp -o model.o
if [ $? != 0 ] 
then
    echo "ERROR: Error compiling demo program model.cpp"
    exit
fi

g++ -o model model.o -L. -L$MATLAB_HOME/bin/glnx86 -L$SYSTEMC/lib-linux -lfft -lm -lsystemc 

# Execute the program.
echo "INFO: Running demo program ................."
./model
echo "INFO: Done."
