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


-- (C) 2001-2017 Intel Corporation. All rights reserved.
-- Your use of Intel Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Intel Program License Subscription 
-- Agreement, Intel MegaCore Function License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Intel and sold by 
-- Intel or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.


-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_dspip_r22sdf_counter.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_counter.vhd,v $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   :  kmarks
--
-- Project      :  auk_dspip_r22sdf
--
-- Description : 
--
-- counter
--
-- $Log: auk_dspip_r22sdf_counter.vhd,v $
-- Revision 1.5.2.1  2007/03/28 14:44:06  kmarks
-- SPR239147 - consecutive N=16 transforms gives errors
--
-- Revision 1.5  2007/01/15 18:14:44  kmarks
-- changes for optimisation of memory
--
-- Revision 1.4  2006/12/05 10:54:43  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.3.2.1  2006/09/28 16:47:29  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.3  2006/09/06 14:39:39  kmarks
-- added global clock enable and error ports to atlantic interfaces. Added checkbox on GUI for Global clock enable . Some bug fixed for the new architecture.
--
-- Revision 1.2  2006/08/14 12:08:35  kmarks
-- *** empty log message ***
--
-- ALTERA Confidential and Proprietary
-- Copyright 2006 (c) Altera Corporation
-- All rights reserved
--
-------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.auk_dspip_math_pkg.all;



entity auk_dspip_r22sdf_counter is

  generic (
    MAX_FFTPTS_g : natural := 1024;
    INPUT_FORMAT_g : string := "NATURAL_ORDER"
    );

  port (
    clk         : in  std_logic;
    reset       : in  std_logic;
    -- start/stop processing
    enable      : in  std_logic;
    in_valid    : in  std_logic;
    --number of points in the fft
    in_sop : in std_logic;
    in_eop : in std_logic;
    in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_radix_2  : in  std_logic;
    in_control  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    -- array of control signals to the stages.
    out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0)
    );

end entity auk_dspip_r22sdf_counter;

architecture rtl of auk_dspip_r22sdf_counter is

  signal control_s : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal radix_2   : std_logic;

  signal cnt : natural range 0 to MAX_FFTPTS_g;

  signal curr_fftpts_minus_1 : std_logic_vector(log2_ceil(MAX_FFTPTS_g)  downto 0);
  signal curr_fftpts_minus_2 : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal curr_fftpts_minus_2_tmp : std_logic_vector(2*log2_ceil(MAX_FFTPTS_g) +1 downto 0);
  
  
 -- signal sop : std_logic;
begin
  out_control <= control_s;

  -- simple counter controls the twiddle address, the sdf select and
  -- commutator controls (s and t).
  counter_p : process (clk, reset)
  begin
    if reset = '1' then
      control_s <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' and in_valid = '1' then
        if in_sop = '1' then
          -- start using the in_control
          if in_radix_2 = '1' then
            control_s <= std_logic_vector(unsigned(in_control) + 2);
          else
            control_s <= std_logic_vector(unsigned(in_control) + 1);
          end if;
        else
          -- continue counting
          if in_radix_2 = '1' then
            if in_eop = '1' and INPUT_FORMAT_g = "BIT_REVERSED" then
              control_s <= (others => '0');
            else
              control_s <= std_logic_vector(unsigned(control_s) + 2);
            end if;
          else
            if in_eop = '1' and INPUT_FORMAT_g = "BIT_REVERSED"  then
              control_s <= (others => '0');
            else
              control_s <= std_logic_vector(unsigned(control_s) + 1);
            end if;
          end if;
        end if;
      end if;
    end if;
  end process counter_p;

  
end architecture rtl;
