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


-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_dspip_r22sdf_enable_control.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_enable_control.vhd,v $
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
-- controls the global enable, 
-- 
--
-- $Log: auk_dspip_r22sdf_enable_control.vhd,v $
-- Revision 1.5.2.1  2007/02/26 17:22:09  kmarks
-- SPR234935 - Dynamic clk_ena control
--
-- Revision 1.5  2006/12/05 10:54:43  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.4.2.1  2006/09/28 16:47:29  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.4  2006/09/06 14:39:39  kmarks
-- added global clock enable and error ports to atlantic interfaces. Added checkbox on GUI for Global clock enable . Some bug fixed for the new architecture.
--
-- Revision 1.3  2006/08/14 12:08:36  kmarks
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

use work.auk_dspip_r22sdf_lib_pkg.all;

entity auk_dspip_r22sdf_enable_control is

  generic (
    NUM_STAGES_g : natural := 5;
    MAX_FFTPTS_g : natural := 1024
    );

  port (
    clk         : in  std_logic;
    reset       : in  std_logic;
    -- start/stop processing
    enable      : in  std_logic;
    stall       : in  std_logic;
    --number of points in the fft
    in_sop      : in  std_logic;
    in_eop      : in  std_logic;
    in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_pwr_2    : in  std_logic;
    -- array of control signals to the stages.
    out_enable  : out std_logic;
    out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0)
    );

end entity auk_dspip_r22sdf_enable_control;

architecture rtl of auk_dspip_r22sdf_enable_control is
  constant NUM_R2_STAGES_c : natural := log2_ceil(MAX_FFTPTS_g);
  constant MAX_PWR_2_c     : natural := log2_ceil(MAX_FFTPTS_g) rem 2;

  signal control_s : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal radix_2   : std_logic;

  signal stall_d : std_logic;
  signal sop     : std_logic;

begin
  out_control <= control_s;

  radix_2 <= '1' when (in_pwr_2 = '1' and MAX_PWR_2_c = 0) or
             (in_pwr_2 = '0' and MAX_PWR_2_c = 1) else
             '0';

  -- simple counter controls the twiddle address, the sdf select and
  -- commutator controls (s and t).
  counter_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        control_s <= (others => '0');
        sop       <= '1';
        stall_d   <= '0';
      else
        stall_d <= stall;
        if enable = '1' then
          if radix_2 = '1' then
            if in_eop = '1' then
              control_s <= (others => '0');
              sop       <= '1';
            else
              control_s <= std_logic_vector(unsigned(control_s) + 2);
              sop       <= '0';
            end if;
          else
            if in_eop = '1' then
              control_s <= (others => '0');
              sop       <= '1';
            else
              control_s <= std_logic_vector(unsigned(control_s) + 1);
              sop       <= '0';
            end if;
          end if;
        end if;
      end if;
    end if;
  end process counter_p;

  -- if we are inbetween blocks then the enable is always 1
  out_enable <= enable  when sop = '0'  else
                not(stall_d);
    
  
end architecture rtl;
