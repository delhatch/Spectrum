-- (C) 2001-2017 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files from any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel FPGA IP License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.



LIBRARY ieee;
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
PACKAGE auk_fft_pkg IS

  function get_internal_data_width(dsp: integer; device_family : string) return integer;
  function get_fft_latency(dsp: integer; device_family : string)  return integer;

END PACKAGE auk_fft_pkg;



package body auk_fft_pkg is

  function get_internal_data_width(dsp: integer; device_family : string) 
    return integer is
  begin
    if (device_family = "Arria 10" and dsp = 3) THEN
      return 32;
    else 
      return 40;
    end if;
  end get_internal_data_width;

  function get_fft_latency(dsp: integer; device_family : string) 
    return integer is
  begin
    if (device_family = "Arria 10" and dsp = 3) THEN
      return 10;
    else 
      return 18;
    end if;
  end get_fft_latency;



end package body auk_fft_pkg;
