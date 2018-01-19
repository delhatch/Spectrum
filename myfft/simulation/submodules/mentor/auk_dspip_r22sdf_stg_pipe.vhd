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
-- $RCSfile: auk_dspip_r22sdf_stg_pipe.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_stg_pipe.vhd,v $
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
-- <Brief description of the contents of the file>
-- 
--
-- $Log: auk_dspip_r22sdf_stg_pipe.vhd,v $
-- Revision 1.4  2006/12/05 10:54:44  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.3.2.1  2006/09/28 16:47:30  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.3  2006/09/06 14:39:40  kmarks
-- added global clock enable and error ports to atlantic interfaces. Added checkbox on GUI for Global clock enable . Some bug fixed for the new architecture.
--
-- Revision 1.2  2006/08/14 12:08:36  kmarks
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

library work;
use work.auk_dspip_math_pkg.all;

entity auk_dspip_r22sdf_stg_pipe is

  generic (
    DATAWIDTH_g    : natural := 18;
    INPUT_FORMAT_g : string  := "NATURAL_ORDER";
    MAX_FFTPTS_g   : natural := 1024
    );

  port (
    clk               : in  std_logic;
    reset             : in  std_logic;
    enable            : in  std_logic;
    stg_input_sel     : in  std_logic;
    -- first
    stg_control_first : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    stg_sop_first     : in  std_logic;
    stg_eop_first     : in  std_logic;
    stg_valid_first   : in  std_logic;
    stg_inverse_first : in  std_logic;
    stg_real_first    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    stg_imag_first    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    -- prev
    stg_valid_prev    : in  std_logic;
    stg_sop_prev      : in  std_logic;
    stg_eop_prev      : in  std_logic;
    stg_inverse_prev  : in  std_logic;
    stg_control_prev  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    stg_real_prev     : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    stg_imag_prev     : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    -- next
    stg_real_next     : out std_logic_vector(DATAWIDTH_g - 1 downto 0);
    stg_imag_next     : out std_logic_vector(DATAWIDTH_g - 1 downto 0);
    stg_control_next  : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    stg_inverse_next  : out std_logic;
    stg_eop_next      : out std_logic;
    stg_sop_next      : out std_logic;
    stg_valid_next    : out std_logic

    );

end entity auk_dspip_r22sdf_stg_pipe;



architecture rtl of auk_dspip_r22sdf_stg_pipe is

begin

  gen_input_mux : if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" generate

    -- connect current stage to next stage.
    -- registered for timing
    reg_stage_output_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          stg_real_next    <= (others => '0');
          stg_imag_next    <= (others => '0');
          stg_control_next <= (others => '0');
          stg_valid_next   <= '0';
          stg_inverse_next <= '0';
          stg_sop_next     <= '0';
          stg_eop_next     <= '0';
        elsif enable = '1' then
          if stg_input_sel = '0' then
            stg_inverse_next <= stg_inverse_prev;
            stg_sop_next     <= stg_sop_prev;
            stg_eop_next     <= stg_eop_prev;
            stg_valid_next   <= stg_valid_prev;
            stg_real_next    <= stg_real_prev;
            stg_imag_next    <= stg_imag_prev;
            stg_control_next <= stg_control_prev;
          else
            stg_inverse_next <= stg_inverse_first;
            stg_sop_next     <= stg_sop_first;
            stg_eop_next     <= stg_eop_first;
            stg_valid_next   <= stg_valid_first;
            stg_control_next <= stg_control_first;
            stg_real_next    <= stg_real_first;
            stg_imag_next    <= stg_imag_first;
          end if;
        end if;
      end if;
    end process reg_stage_output_p;
  end generate gen_input_mux;

  --no input mux for bit reversed, all data starts at first stage.
  gen_no_input_mux : if INPUT_FORMAT_g = "BIT_REVERSED" generate

    -- connect current stage to next stage.
    -- registered for timing
    reg_stage_output_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          stg_real_next    <= (others => '0');
          stg_imag_next    <= (others => '0');
          stg_control_next <= (others => '0');
          stg_valid_next   <= '0';
          stg_inverse_next <= '0';
          stg_sop_next     <= '0';
          stg_eop_next     <= '0';
        elsif enable = '1' then
          stg_inverse_next <= stg_inverse_prev;
          stg_sop_next     <= stg_sop_prev;
          stg_eop_next     <= stg_eop_prev;
          stg_valid_next   <= stg_valid_prev;
          stg_real_next    <= stg_real_prev;
          stg_imag_next    <= stg_imag_prev;
          stg_control_next <= stg_control_prev;
        end if;
      end if;
    end process reg_stage_output_p;
  end generate gen_no_input_mux;

end architecture rtl;
