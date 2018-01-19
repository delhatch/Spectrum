This is the bit accurate system C model of the FFT Variable streaming

To make the executable
1. make -f Makefile.osci

To run the executable
./SVSfft_model <dw> <tw> <nps> <output order> <input order> [<real input file> <imag_input file> <blksize file> <real output file> <imag output file> <inverse file> ]

where dw = data width
      tw = twiddle width
      nps = max FFT block size
      output order = 0 - bit reverse order, 1 - natural order
      input order = 0 - bit reverse order, 1 - natural order
      representation = 0 - fixed point, 1 - floating pt
      real input file = path to file containing the real input data, defaults to in_real
      imag input file = path to file containing the imag input data, defaults to in_imag
      blksize file = path to file containing nps for each frame, defaults to all frames of size nps
      inverse file = path to file containing fft(0)/ifft(1) for each frame, defaults to fft for all frames
      real output file = path to file where the real output data will be written, defaults to out_real
      imag output file = path to file where the imag output data will be written, defaults to out_imag

NOTE if  the input file contains real and imaginary data alternatively, then set real input file = imag input file. Similarly for the output
     files, i.e. if real output file = imag output file, then real and imaginary data will be written alternatively to the same file.

input files are always assumed to be in natural order.
(therefore if input file is in bit-reversed order, set input order to bit-reverse)

eg ./SVSfftmodel 8 8 64 1 1 0 real_input.txt imag_input.txt blksize_report.txt