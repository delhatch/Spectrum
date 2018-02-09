# SpectrumAnalyzer

This design implements an audio real-time analyzer (RTA), or spectrum analyzer, that converts the audio time-domain signal into a frequency-domain signal. It then displays the spectrum as a series of bars, with the frequency axis in the log domain rather than linear. Log/log is the best mode for analyzing/viewing audio waveforms.

![Link_to_video](https://github.com/delhatch/Spectrum/blob/master/A_Example_video_music_short.mp4)

![Image](https://github.com/delhatch/Spectrum/blob/master/screenshot.JPG)

This project uses the Cyclone IV FPGA used in the DE2-115 evaluation board to:

a) configure and interface to the audio codec

b) buffer the audio samples into a FIFO

c) feed the samples into an FFT

d) collect the results into a dual-port RAM

e) instantiate a Nios soft-core processor

f) interface the RAM onto the Nios bus to read the resuslts

g) FPGA also has a VGA frame buffer and creates the VGA waveform

h) allows the Nios to draw pixels into the VGA frame buffer

The Nios processor reads the FFT data, groups high frequency bins together to display the spectrum in log fashion, and then draws bars into the VGA frame buffer.
