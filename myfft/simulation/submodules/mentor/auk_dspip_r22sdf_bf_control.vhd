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
-- $RCSfile: auk_dspip_r22sdf_bf_control.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_bf_control.vhd,v $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   :  kmarks
--
-- Project      : auk_dspip_r22sdf
--
-- Description : 
--
--  Controls the operations occuring the in the butterfly unit as well as
--  generating the counter for this stage. 
--
-- $Log: auk_dspip_r22sdf_bf_control.vhd,v $
-- Revision 1.5  2007/01/25 12:38:49  kmarks
-- added bit reversal optimisations
--
-- Revision 1.4  2006/12/05 10:54:43  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.3.2.1  2006/09/28 16:47:28  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.3  2006/09/06 14:39:38  kmarks
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
-------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.auk_dspip_math_pkg.all;
use work.auk_dspip_r22sdf_lib_pkg.all;

entity auk_dspip_r22sdf_bf_control is
  generic(
    MAX_FFTPTS_g   : natural := 1024;
    INPUT_FORMAT_g : string  := "BIT_REVERSED";
    DELAY_g        : natural := 8
    );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    enable       : in  std_logic;
    in_fftpts    : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_radix_2   : in  std_logic;
    s_s          : in  std_logic;
    in_valid     : in  std_logic;
    in_sop       : in  std_logic;
    in_eop       : in  std_logic;
    in_control   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
    in_inverse   : in  std_logic;
    curr_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    out_control  : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
    out_inverse  : out std_logic;
    out_sop      : out std_logic;
    out_eop      : out std_logic;
    out_valid    : out std_logic
    );

end entity auk_dspip_r22sdf_bf_control;


architecture rtl of auk_dspip_r22sdf_bf_control is
  signal shift           : std_logic;
  signal in_cnt          : natural range 0 to MAX_FFTPTS_g;
  signal out_cnt         : natural range 0 to MAX_FFTPTS_g;
  signal delay_value     : natural range 0 to DELAY_g;
  signal fftpts_less_one : std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);

begin  -- architecture rtl

  bf_counter_inst : auk_dspip_r22sdf_counter
    generic map (
      MAX_FFTPTS_g => MAX_FFTPTS_g)
    port map (
      clk         => clk,
      reset       => reset,
      -- start/stop processing
      enable      => enable,
      in_valid    => in_valid,
      --number of points in the fft
      in_sop      => in_sop,
      in_eop      => in_eop,
      in_fftpts   => in_fftpts,
      in_radix_2  => in_radix_2,
      in_control  => in_control,
      -- array of control signals to the stages.
      out_control => curr_control);

  gen_in_order_control : if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" generate
  begin
    out_control_p : process (clk, reset)
    begin  -- process out_control
      if reset = '1' then
        out_control <= (others => '0');
      elsif rising_edge(clk) then
        if enable = '1' then
          if in_radix_2 = '1' then
            out_control <= std_logic_vector(unsigned(in_control) + delay_value*2);
          else
            out_control <= std_logic_vector(unsigned(in_control) + delay_value);
          end if;
        end if;
      end if;
    end process out_control_p;
  end generate gen_in_order_control;

  gen_bit_reverse_control : if INPUT_FORMAT_g = "BIT_REVERSED" generate
    out_control <= (others => '0');
  end generate gen_bit_reverse_control;

  delay_value <= DELAY_g/2 when in_radix_2 = '1' else
                 DELAY_g;


  out_valid <= '1' when s_s = '1' or shift = '1' else
               '0';

  precalc_fftpts_less_one : process (clk, reset)
  begin  -- process precalc_fftpts_less_one
    if reset = '1' then
      fftpts_less_one <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' then
        --if in_valid = '1' then
        fftpts_less_one <= std_logic_vector(unsigned(in_fftpts) - 1);
        --end if;
      end if;
    end if;
  end process precalc_fftpts_less_one;

--   Generate a valid signal when data is valid
  in_cnt_p : process (clk, reset)
  begin
    if reset = '1' then
      in_cnt <= 0;
    elsif rising_edge(clk) then
      if enable = '1' and in_valid = '1' then
        --output valid for FFTPTS after the delay
        if in_valid = '1' then
          --      if (in_cnt = unsigned(in_fftpts) - 1) then
          if (in_cnt = unsigned(fftpts_less_one)) then
            in_cnt <= 0;
          else
            in_cnt <= in_cnt + 1;
          end if;
          
        end if;

      end if;
    end if;
  end process in_cnt_p;



  --Generate a valid signal when data is valid
  gen_out_cnt_p : process (clk, reset)
  begin
    if reset = '1' then
      out_cnt     <= 0;
      out_sop     <= '0';
      out_eop     <= '0';
      shift       <= '0';
      out_inverse <= '0';
    elsif rising_edge(clk) then
      if enable = '1' then
        --output valid for FFTPTS after the delay
        out_sop <= '0';
        out_eop <= '0';
        if in_cnt = delay_value and delay_value > 0 then
          out_cnt     <= out_cnt + 1;
          shift       <= '1';
          out_sop     <= '1';
          out_inverse <= in_inverse;
          --     elsif out_cnt = unsigned(in_fftpts) - 1 then
        elsif out_cnt = unsigned(fftpts_less_one) then
          shift   <= '0';
          out_eop <= '1';
          out_cnt <= 0;
        elsif out_cnt > 0 then
          out_cnt <= out_cnt + 1;
        end if;
      end if;
    end if;
  end process gen_out_cnt_p;

end architecture rtl;
