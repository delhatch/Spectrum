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
-- $RCSfile: auk_dspip_r22sdf_addsub.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_addsub.vhd,v $
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
-- Adder/ Subtractor module for the r22SDF
--
-- This module adds/subtracts datab to/from dataa, producing result
--
-- Optionally this module can be made to pipeline the adder to improve timing.
--
--
-- $Log: auk_dspip_r22sdf_addsub.vhd,v $
-- Revision 1.2.8.1  2007/02/16 17:23:25  kmarks
-- SPR223891 - cast to bit vector and back to std_logic_vector to force to 0 when undefined
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

library lpm;
use lpm.lpm_components.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

use work.auk_dspip_r22sdf_lib_pkg.all;

entity auk_dspip_r22sdf_addsub is

  generic (
    DATAWIDTH_g      : natural := 18;
    REPRESENTATION_g : string := "FIXEDPT";
    PIPELINE_g       : natural := 0;
    GROW_g           : natural := 1
    );

  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    clken  : in  std_logic;
    add    : in  std_logic;             -- 1 for add, 0 for subtract
    dataa  : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    datab  : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    result : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0));

end entity auk_dspip_r22sdf_addsub;


architecture rtl of auk_dspip_r22sdf_addsub is

  COMPONENT twentynm_fp_mac
  generic (
  operation_mode  : string  :=  "SP_MULT_ADD";
  use_chainin : string  :=  "false";
  adder_subtract  : string  :=  "false";
  ax_clock  : string  :=  "none";
        ay_clock  : string  :=  "none";
        az_clock  : string  :=  "none";
  output_clock  : string  :=  "none";
  accumulate_clock  : string  :=  "none";
  accum_pipeline_clock  : string  :=  "none";
  accum_adder_clock : string  :=  "none";
  ax_chainin_pl_clock : string  :=  "none";
  mult_pipeline_clock : string  :=  "none";
  adder_input_clock : string  :=  "none";
  lpm_type  : string  :=  "twentynm_fp_mac"
    );
    port (
      ax  : in std_logic_vector(31 downto 0)  := (others => '0');
        ay  : in std_logic_vector(31 downto 0)  := (others => '0');
  az  : in std_logic_vector(31 downto 0)  := (others => '0');
  chainin : in std_logic_vector(31 downto 0)  := (others => '0');
  chainin_overflow  : in std_logic  := '0';
  chainin_underflow : in std_logic  := '0';
  chainin_inexact : in std_logic  := '0';
  chainin_invalid : in std_logic  := '0';
  accumulate  : in std_logic  := '0';
  clk : in std_logic_vector(2 downto 0) := (others => '0');
  ena : in std_logic_vector(2 downto 0) := (others => '1');
        aclr  : in std_logic_vector(1 downto 0) := (others => '0');
  resulta : out std_logic_vector(31 downto 0);
  overflow  : out std_logic;
  underflow : out std_logic;
  inexact : out std_logic;
  invalid : out std_logic;
  chainout  : out std_logic_vector(31 downto 0);
  chainout_overflow : out std_logic;
  chainout_underflow  : out std_logic;
  chainout_inexact  : out std_logic;
  chainout_invalid  : out std_logic;
  dftout  : out std_logic
    );
  END COMPONENT;

  signal result_s  : std_logic_vector (DATAWIDTH_g + GROW_g - 1 downto 0);
  signal dataa_ext : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal datab_ext : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal dataa_std : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal datab_std : std_logic_vector(DATAWIDTH_g - 1 downto 0);

  -- signal for S10 pipeline and the pipeline module
  signal result_w : std_logic_vector (DATAWIDTH_g + GROW_g - 1 downto 0);
  
begin

  -- convert to bit_vector, then back to std_logic vector to force 'X' value to
  -- 0. This prevents warnings being printed out to modelsim
  datab_std <= to_stdLogicVector(to_bitVector(datab));
  dataa_std <= to_stdLogicVector(to_bitVector(dataa));

  -- grow data 
  dataa_ext <= std_logic_vector(resize(signed(dataa_std), DATAWIDTH_g + GROW_g));
  datab_ext <= std_logic_vector(resize(signed(datab_std), DATAWIDTH_g + GROW_g));

  -- Option 1:
  -- fixed point adder, on non-S10 device
  gen_fixed : if REPRESENTATION_g = "FIXEDPT" and HYPER_OPTIMIZATION = 0 generate
  begin
    lpm_add_sub_component : lpm_add_sub
      generic map (
        lpm_direction      => "UNUSED",
        lpm_representation => "SIGNED",
        lpm_hint           => "ONE_INPUT_IS_CONSTANT = NO, CIN_USED = YES",
        lpm_pipeline       => PIPELINE_g,
        lpm_type           => "LPM_ADD_SUB",
        lpm_width          => DATAWIDTH_g+ GROW_g
        )
      port map (
        dataa   => dataa_ext,
        add_sub => add,
        datab   => datab_ext,
        clken   => clken,
        clock   => clk,
        aclr    => reset,
        result  => result_s
        );
  end generate gen_fixed;

  -- Option 2:
  -- fxied point adder, on Stratix 10 device
  gen_fixed_S10 : if REPRESENTATION_g = "FIXEDPT" and HYPER_OPTIMIZATION = 1 generate
  begin
    lpm_add_sub_component : lpm_add_sub -- use the lpm_add_sub in non-pipelined mode
      generic map (
        lpm_direction      => "UNUSED",
        lpm_representation => "SIGNED",
        lpm_hint           => "ONE_INPUT_IS_CONSTANT = NO, CIN_USED = NO",
        lpm_pipeline       => 0,
        lpm_type           => "LPM_ADD_SUB",
        lpm_width          => DATAWIDTH_g + GROW_g
        )
      port map (
        dataa   => dataa_ext,
        add_sub => add,
        datab   => datab_ext,
        result  => result_w
        );
    -- and add pipeline stages after, if PIPELINE_g > 0
    gen_pipe_S10 : if PIPELINE_g > 0 generate
    begin
      result_s_pipe : hyper_pipeline_interface
      generic map (PIPELINE_STAGES => PIPELINE_g,
                   SIGNAL_WIDTH => DATAWIDTH_g + GROW_g)
      port map (clk              => clk,
                clken            => clken,
                reset            => reset,
                signal_w         => result_w,
                signal_pipelined => result_s);
    end generate gen_pipe_S10;
    gen_no_pipe_S10 : if PIPELINE_g = 0 generate
    begin
      result_s <= result_w;
    end generate gen_no_pipe_S10;
  end generate gen_fixed_S10;

  
  -- Option 3:
  -- floating point adder, on A10 and/or S10
  gen_fp : if REPRESENTATION_g = "FLOATPT" generate
    signal sign_changed_datab_ext : std_logic_vector (datab_ext'HIGH downto 0);
    signal clk_ext, ena_ext : std_logic_vector (2 downto 0);  -- in order to use the hard fp DSP block
    signal reset_ext : std_logic_vector (1 downto 0);         -- we need these control signals in 3-bit 
                                                              -- format, each bit is a seperate signal
    
  begin

    clk_ext <= "00" & clk;
    ena_ext <= "00" & clken;
    reset_ext <= '0' & reset;
     
    -- because the add/sub operation changes during the runtime, we manually correct the sign bit here
    sign_changed_datab_ext <= datab_ext when add = '1' else
                              not(datab_ext(datab_ext'HIGH)) & datab_ext(datab_ext'HIGH -1 downto 0); 

    -- instantiate the component for Arria 10 hard fp adder
    fp_adder : twentynm_fp_mac
    generic map (ax_clock => "0",
                 ay_clock => "0",
                 az_clock => "NONE",
                 output_clock => "0",
                 accumulate_clock => "NONE",
                 ax_chainin_pl_clock => "NONE",
                 accum_pipeline_clock => "NONE",
                 mult_pipeline_clock => "NONE",
                 adder_input_clock => "0",
                 accum_adder_clock => "NONE",
                 use_chainin => "false",
                 operation_mode => "sp_add",
                 adder_subtract => "false")
    port map (clk => clk_ext,
              ena => ena_ext,
              aclr => reset_ext,
              ax => dataa_ext,
              ay => sign_changed_datab_ext,
              chainin => (others=>'0'),
              resulta => result_s,
              chainout => open
              );

  end generate gen_fp;
  


  result <= result_s;

end architecture rtl;


