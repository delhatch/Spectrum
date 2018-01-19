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


#these variable will be parse into the model.c

N=256.0
data_prec=16.0;
twiddle_prec=16.0;
#direction=0 is fixed
arch=1.0;
throughput=4.0;
real_input_file="real_input.txt"
imag_input_file="imag_input.txt"

#this for new arch
maxN=256;
input_order=1;# 0 - bit reserved ; 1 - natural order
output_order=1;
rep=0;
maxN=256;

# Execute the program.
if [ $arch = 3.0 ]
then
	# using the NEW ARCH
	echo "INFO: Call the C-model for the NEW ARCH"
	#set the path
	export SYSTEMC=/data/thnguyen/systemc-2.1.v1
	echo "INFO: SystemC = $SYSTEMC"
	export PATH=`pwd`
	echo "INFO: the PATH = $PATH"
	
	# Compile demo program file.
	echo "INFO: Compiling demo program ................."
	g++  -I/usr/include -I$SYSTEMC/include -L$SYSTEMC/lib-linux -DLIB_COMPILE -c $PATH/model_c_wrapper.c -o model_c_wrapper.o
	if [ $? != 0 ] 
	then
	    echo "ERROR: Error compiling demo program model.cpp"
	    exit
	fi

	#g++ -o model model.o -L. -L$MATLAB_HOME/bin/glnx86 -L$SYSTEMC/lib-linux -lfft -lm -lsystemc 
	g++ -o c_model.exe model_c_wrapper.o -L. -L$SYSTEMC/lib-linux -lfft -lm -lsystemc 

	
	./c_model.exe  $N $data_prec $twiddle_prec $arch $throughput $real_input_file $imag_input_file $input_order $output_order $rep $maxN;
	exit
else
	echo "INFO: Call the C-model for the OLD ARCH"
	# using for OLD ARCH
	# Create static library's object file, libSfftmodel.o.
	#gcc -Wall -g -c -o libSfftmodel.o Sfftmodel.c

	# Create static library.
	#ar rcs libSfftmodel.a libSfftmodel.o

	# Compile to output file
	echo "INFO: Compile the .c file into .o file"
	gcc -Wall -g -c model_c_wrapper.c -o model_c_wrapper.o

	#generate the excuted file
	echo "INFO: Generate the .exe file and link to lib when it run"
	gcc -g -o c_model_old_arch model_c_wrapper.o -L. libSfftmodel.a -lm 
	
	./c_model_old_arch  $N $data_prec $twiddle_prec $arch $throughput;
	exit
fi

