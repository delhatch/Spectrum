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


------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_dspip_r22sdf_stage.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_stage.vhd,v $
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
-- $Log: auk_dspip_r22sdf_stage.vhd,v $
-- Revision 1.23.2.3  2007/07/25 14:51:46  kmarks
-- SPR 248068 - previous commit had a bug...
--
-- Revision 1.23.2.2  2007/07/24 14:46:48  kmarks
-- SPR 248068
--
-- Revision 1.23.2.1  2007/07/24 08:21:00  kmarks
-- SPRs 247695 247901
--
-- Revision 1.23  2007/07/03 19:16:00  kmarks
-- handle the data growth better
--
-- Revision 1.22  2007/06/28 16:44:52  kmarks
-- Changed prune to cma_out_datawidth - I think it is clearer what it means.
--
-- Revision 1.21  2007/06/28 13:48:22  kmarks
-- added pruning infrastructure
--
-- Revision 1.20  2007/06/20 16:38:20  kmarks
-- Changed the way that processing is handled - it is more robust.
--
-- Revision 1.19  2007/06/04 08:54:00  kmarks
-- updated the verilog testbench and regression testbench for floating point. Fixed a few bugs in the floating point data path. Added -N/2 to N/2 support for floating pt. Fixed a bug in the fpadd
--
-- Revision 1.18  2007/05/21 16:18:45  kmarks
-- bug fixes - works for N= 64 with bit reversed inputs
--
-- Revision 1.17  2007/05/11 10:29:58  kmarks
-- *** empty log message ***
--
-- Revision 1.16  2007/05/11 10:10:03  kmarks
-- Added floating point, untested as yet.
--
-- Revision 1.15  2007/05/04 08:19:37  kmarks
-- working after rearranging stage to have multiplication first.
--
-- Revision 1.14  2007/03/29 08:36:04  kmarks
-- updated with fix for consecutive N=16 transforms
--
-- Revision 1.13.2.1  2007/03/28 14:44:06  kmarks
-- SPR239147 - consecutive N=16 transforms gives errors
--
-- Revision 1.13  2007/02/07 17:52:20  kmarks
-- bug with the inverse for max fft size pwr 2
--
-- Revision 1.12  2007/02/07 14:46:15  kmarks
-- added dynamic inverse testing and fixed the inverse fft bug.
--
-- Revision 1.11  2007/02/06 13:19:23  kmarks
-- bugs when DSP_ROUNDING_g = 0.
--
-- Revision 1.10  2007/02/02 18:09:25  kmarks
-- added -N/2 to N/2 to the input orders
--
-- Revision 1.9  2007/01/25 12:38:50  kmarks
-- added bit reversal optimisations
--
-- Revision 1.8  2007/01/12 13:32:28  kmarks
-- add OPTIMIZE_MEM_g
--
-- Revision 1.7  2006/12/19 18:07:30  kmarks
-- Updated to make use of the rounding in the stratix III DSP block.
--
-- Revision 1.6  2006/12/05 10:54:44  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.5.2.2  2006/09/28 16:47:30  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.5.2.1  2006/09/21 16:17:55  kmarks
-- SPR 217218 - improved memory utilisation
--
-- Revision 1.5  2006/09/06 14:39:40  kmarks
-- added global clock enable and error ports to atlantic interfaces. Added checkbox on GUI for Global clock enable . Some bug fixed for the new architecture.
--
-- Revision 1.4  2006/08/24 12:49:28  kmarks
-- various bug fixes and added bit reversal.
--
-- Revision 1.3  2006/08/14 12:08:36  kmarks
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

entity auk_dspip_r22sdf_stage is

  generic (
    DEVICE_FAMILY_g  : string; 
    STAGE_g          : natural := 1;    -- stage number
    NUM_STAGES_g     : natural := 5;    -- Maximum number of stages
    MAX_FFTPTS_g     : natural := 1024;
    MAX_DATAWIDTH_g  : natural := 18+14;
    INPUT_FORMAT_g   : string  := "NATURAL_ORDER";
    REPRESENTATION_g : string  := "FIXEDPT";
    DATAWIDTH_g      : natural := 18;   -- this stage true input datawidth
    TWIDWIDTH_g      : natural := 18;
    PIPELINE_g       : natural := 0;
    OPTIMIZE_MEM_g   : natural := 1;
    DSP_ROUNDING_g   : natural := 1;
    DSP_ARCH_g       : natural := 0;
    CMA_GROW_g : natural := 3;
    DEBUG_g          : natural := 0
    );

  port (
    clk         : in  std_logic;
    reset       : in  std_logic;
    enable      : in  std_logic;        -- start/stop processing
    in_valid    : in  std_logic;
    in_pwr_2    : in  std_logic;        -- 1 radix 2, 0 radix 2^2
    in_sel      : in  std_logic;
    in_sop      : in  std_logic;
    in_eop      : in  std_logic;
    in_inverse  : in  std_logic;
    in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_real     : in  std_logic_vector(MAX_DATAWIDTH_g - 1 downto 0);
    in_imag     : in  std_logic_vector(MAX_DATAWIDTH_g - 1 downto 0);
    realtwid    : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    imagtwid    : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    twid_rd_en  : out std_logic;
    twidaddr    : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    in_control  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    processing  : out std_logic;
    out_real    : out std_logic_vector(MAX_DATAWIDTH_g - 1 downto 0);
    out_imag    : out std_logic_vector(MAX_DATAWIDTH_g - 1 downto 0);
    out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    out_inverse : out std_logic;
    out_sop     : out std_logic;
    out_eop     : out std_logic;
    out_valid   : out std_logic

    );

end entity auk_dspip_r22sdf_stage;

architecture rtl of auk_dspip_r22sdf_stage is

  constant FP_ADDER_LATENCY : natural := 3;  -- the latency of the hard floating point adder block
  constant FP_MULT_LATENCY  : natural := 3;  -- the latency of the hard floating point multiplier block

  function calc_bfi_delay return natural is
  begin
    if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
      return MAX_FFTPTS_g/(2**(2*STAGE_g-1));
    else
      return MAX_FFTPTS_g/(2**(2*STAGE_g-1))/2;
    end if;
  end function calc_bfi_delay;

  function calc_bfii_delay return natural is
  begin
    if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
      return (MAX_FFTPTS_g/(2**(2*STAGE_g-1)))/2;
    else
      return (MAX_FFTPTS_g/(2**(2*STAGE_g-1)));
    end if;
  end function calc_bfii_delay;

  function is_last_stage return natural is
  begin
    if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
      if STAGE_g = NUM_STAGES_g then
        return 1;
      else
        return 0;
      end if;
    else
      if STAGE_g = 1 then
        return 1;
      else
        return 0;
      end if;
    end if;
  end function is_last_stage;

  function is_first_stage return natural is
  begin
    if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
      if STAGE_g = 1 then
        return 1;
      else
        return 0;
      end if;
    else
      if STAGE_g = NUM_STAGES_g then
        return 1;
      else
        return 0;
      end if;
    end if;
  end function is_first_stage;

  function is_mux_stage return natural is
  begin
    if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
      if STAGE_g = NUM_STAGES_g then
        return 1;
      else
        return 0;
      end if;
    else
      if STAGE_g = NUM_STAGES_g then
        return 1;
      else
        return 0;
      end if;
    end if;
  end function is_mux_stage;

  function calc_bfii_pipeline return natural is
  begin
    if REPRESENTATION_g = "FIXEDPT" then
      return PIPELINE_g;
    else
      return FP_ADDER_LATENCY;
    end if;
  end function calc_bfii_pipeline;

  constant DELAY_BFI_c     : natural := calc_bfi_delay;
  constant DELAY_BFII_c    : natural := calc_bfii_delay;

  function calc_grow_bfi return natural is
  begin
    if REPRESENTATION_g = "FIXEDPT" then
      if DELAY_BFI_c = 0 then
        return 0;
      else
        return 1;
      end if;
    else
      return 0;
    end if;
  end function calc_grow_bfi;

  function calc_grow_bfii return natural is
  begin
    if REPRESENTATION_g = "FIXEDPT" then
      return 1;
    else
      return 0;
    end if;
  end function calc_grow_bfii;

   function calc_bfi_pipeline return natural is
  begin
    if REPRESENTATION_g = "FIXEDPT" then
      return  PIPELINE_g;
    else
      return FP_ADDER_LATENCY;
    end if;
  end function calc_bfi_pipeline;


  
  constant GROW_BFI_c      : natural := calc_grow_bfi;
  constant GROW_BFII_c     : natural := calc_grow_bfii;
  constant NUM_R2_STAGES_c : natural := log2_ceil(MAX_FFTPTS_g);

  -- without optimise speed = 5;  --4;
  -- with optimise speed = 6
  -- with dsp rounding = 3
  constant MAX_PWR_2_c : natural := log2_ceil(MAX_FFTPTS_g)rem 2;

  constant LAST_STAGE_c        : natural := is_last_stage;
  constant FIRST_STAGE_c       : natural := is_first_stage;
  constant MUX_STAGE_c         : natural := is_mux_stage;
  constant BFII_ADD_PIPELINE_c : natural := calc_bfii_pipeline;
  constant BFI_ADD_PIPELINE_c  : natural := calc_bfi_pipeline;

  constant BFI_DEBUG_FILENAME_c  : string := "vhdlout" & integer'image(STAGE_g) & "a.txt";
  constant BFII_DEBUG_FILENAME_c : string := "vhdlout" & integer'image(STAGE_g) & "b.txt";

  constant CMA_IN_DATAWIDTH_c  : natural := DATAWIDTH_g;
  constant CMA_OUT_DATAWIDTH_c : natural := DATAWIDTH_g + CMA_GROW_g;

  constant BFI_IN_DATAWIDTH_c  : natural := CMA_OUT_DATAWIDTH_c;
  constant BFI_OUT_DATAWIDTH_c : natural := BFI_IN_DATAWIDTH_c + GROW_BFI_c;

  constant BFII_IN_DATAWIDTH_c  : natural := BFI_OUT_DATAWIDTH_c;
  constant BFII_OUT_DATAWIDTH_c : natural := BFII_IN_DATAWIDTH_c + GROW_BFII_c;
  constant ADDED_DELAY_c : natural := 0;

  


  function calc_cma_pipeline_delay return natural is
  begin
    if REPRESENTATION_g = "FIXEDPT" then
      if DEVICE_FAMILY_g = "Arria 10" then
        if CMA_IN_DATAWIDTH_c <= 18 and TWIDWIDTH_g <= 18 then
          return ADDED_DELAY_c + 7 + 3; -- 5 for the multiplies, 3 for the rounding
        elsif CMA_IN_DATAWIDTH_c < 27 and TWIDWIDTH_g < 27 then
          return ADDED_DELAY_c + 7 + 3 + 3; -- 5 for multiplies, PIPELINE for Addition then 3 for rounding
        else 
          return ADDED_DELAY_c + 7 + 3 + 3; -- 5 for multiplies, 0 for added latency in the multiplies PIPELINE for Addition then 3 for rounding
        end if;
      else 
        if DSP_ROUNDING_g = 1 then 
          if CMA_IN_DATAWIDTH_c > 18 then
            -- we are using the staged multiplier
            return (7 + OPTIMIZE_MEM_g + ADDED_DELAY_c);
          else
            -- we are using sign extended Stratix III rounding multiplier
            return (7 + OPTIMIZE_MEM_g + ADDED_DELAY_c - 2);
          end if;
        else
          if DSP_ARCH_g = 1 then
            if CMA_IN_DATAWIDTH_c >= 37 and CMA_IN_DATAWIDTH_c >= TWIDWIDTH_g then
              -- we are using the staged multiplier
              return (7 + OPTIMIZE_MEM_g + ADDED_DELAY_c);
            else
              -- we are using Stratix V 18x25 mac mode
              return (8+ OPTIMIZE_MEM_g + ADDED_DELAY_c);
            end if;
          elsif DSP_ARCH_g = 2 then
            if CMA_IN_DATAWIDTH_c > 26 and CMA_IN_DATAWIDTH_c <= 38 and TWIDWIDTH_g <= 18 then
              -- we are using the staged multiplier
              return (7 + OPTIMIZE_MEM_g + ADDED_DELAY_c);
            else
              -- we are using 3 mult implementation utilizing Arria V pre-adder mode
              return (8 + OPTIMIZE_MEM_g + ADDED_DELAY_c);
            end if;
          else
            if CMA_IN_DATAWIDTH_c > 18 or TWIDWIDTH_g > 18 then
              -- we are using the staged multiplier
              return (7 + OPTIMIZE_MEM_g + ADDED_DELAY_c);
            else
              -- we are using small multiplier
              return (8+ OPTIMIZE_MEM_g + ADDED_DELAY_c);
            end if;
          end if;
        end if;
      end if;
    else
      return FP_ADDER_LATENCY + FP_MULT_LATENCY + 5;
    end if;
  end function calc_cma_pipeline_delay;

  function resize2 (arg: signed; new_size: natural) return signed is
    alias invec : SIGNED (arg'length - 1 downto 0) is arg;
    variable result: signed (new_size - 1 downto 0);
    begin
      result:= (others => '0');
      if (arg'length > new_size) then
        result:= invec(arg'length - 1 downto arg'length - new_size);
      else
        result:= (others=>arg(arg'left));
        result(arg'length - 1 downto 0) := invec(arg'length - 1 downto 0) ;
      end if;
    return result;
  end resize2;

  

  -- resized inputs/outputs
  signal in_real_s : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_s : std_logic_vector(DATAWIDTH_g - 1 downto 0);

  -- cma inputs
  signal cma_in_real    : std_logic_vector(CMA_IN_DATAWIDTH_c - 1 downto 0);
  signal cma_in_imag    : std_logic_vector(CMA_IN_DATAWIDTH_c - 1 downto 0);
  signal cma_in_valid   : std_logic;
  signal cma_in_sop     : std_logic;
  signal cma_in_eop     : std_logic;
  signal cma_in_control : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal cma_in_inverse : std_logic;

  -- output from complex multiplier, connect to BFI
  signal cma_out_real    : std_logic_vector(CMA_OUT_DATAWIDTH_c - 1 downto 0);
  signal cma_out_imag    : std_logic_vector(CMA_OUT_DATAWIDTH_c - 1 downto 0);
  signal cma_out_valid   : std_logic;
  signal cma_out_sop     : std_logic;
  signal cma_out_eop     : std_logic;
  signal cma_out_control : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal cma_out_inverse : std_logic;

  -- bfi inputs
  signal bfi_in_real    : std_logic_vector(BFI_IN_DATAWIDTH_c - 1 downto 0);
  signal bfi_in_imag    : std_logic_vector(BFI_IN_DATAWIDTH_c - 1 downto 0);
  signal bfi_in_valid   : std_logic;
  signal bfi_in_sop     : std_logic;
  signal bfi_in_eop     : std_logic;
  signal bfi_in_radix_2 : std_logic;
  signal bfi_in_control : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal bfi_in_inverse : std_logic;

  -- signals from BFI to delay block
  signal bfi_del_in           : std_logic_vector(2*(BFI_OUT_DATAWIDTH_c) - 1 downto 0);
  signal bfi_del_in_real      : std_logic_vector(BFI_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfi_del_in_imag      : std_logic_vector(BFI_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfi_del_out          : std_logic_vector(2*(BFI_OUT_DATAWIDTH_c) - 1 downto 0);
  signal bfi_del_out_real     : std_logic_vector(BFI_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfi_del_out_imag     : std_logic_vector(BFI_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfi_delay_blk_enable : std_logic;
  -- BFI delay block control
  constant BFI_FRAME_OVERLAP_c :natural := 4;
  signal bfi_processing_cnt : natural range 0 to BFI_FRAME_OVERLAP_c;
  signal bfi_processing : std_logic;

  -- output from BFI, connect with BFII
  signal bfi_out_real    : std_logic_vector(BFI_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfi_out_imag    : std_logic_vector(BFI_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfi_out_valid   : std_logic;
  signal bfi_out_inverse : std_logic;
  signal bfi_out_control : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal bfi_out_sop     : std_logic;
  signal bfi_out_eop     : std_logic;

  -- bfii inputs
  signal bfii_in_real    : std_logic_vector(BFII_IN_DATAWIDTH_c- 1 downto 0);
  signal bfii_in_imag    : std_logic_vector(BFII_IN_DATAWIDTH_c - 1 downto 0);
  signal bfii_in_valid   : std_logic;
  signal bfii_in_sop     : std_logic;
  signal bfii_in_eop     : std_logic;
  signal bfii_in_control : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal bfii_in_inverse : std_logic;

  -- signals from BFII to delay block
  signal bfii_del_in           : std_logic_vector(2*(BFII_OUT_DATAWIDTH_c) - 1 downto 0);
  signal bfii_del_in_real      : std_logic_vector(BFII_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfii_del_in_imag      : std_logic_vector(BFII_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfii_del_out          : std_logic_vector(2*(BFII_OUT_DATAWIDTH_c) - 1 downto 0);
  signal bfii_del_out_real     : std_logic_vector(BFII_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfii_del_out_imag     : std_logic_vector(BFII_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfii_delay_blk_enable : std_logic;

  -- output from BFII
  signal bfii_out_real    : std_logic_vector(BFII_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfii_out_imag    : std_logic_vector(BFII_OUT_DATAWIDTH_c - 1 downto 0);
  signal bfii_out_valid   : std_logic;
  signal bfii_out_inverse : std_logic;
  signal bfii_out_control : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal bfii_out_sop     : std_logic;
  signal bfii_out_eop     : std_logic;

  signal in_radix_2      : std_logic;
  signal twidaddr_s      : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal out_eop_s : std_logic;
  signal out_valid_s : std_logic;
  -- number of frames that can be input before a single output frame
  constant FRAME_OVERLAP_c :natural := 7;
  signal processing_cnt : natural range 0 to FRAME_OVERLAP_c;

  -- hyper optimization parameters
  constant PIPELINE_STAGES : natural := 3;
  signal realtwid_s, imagtwid_s : std_logic_vector (TWIDWIDTH_g - 1 downto 0);
  signal twidaddr_tmp : std_logic_vector (log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal twid_rd_en_tmp : std_logic;


  -- latency increases when optimise memory = 1 and 
  constant MULT_PIPELINE_c : natural := calc_cma_pipeline_delay + HYPER_OPTIMIZATION*PIPELINE_STAGES*2 + 1;

begin

  in_radix_2 <= '1' when (in_pwr_2 = '1' and MAX_PWR_2_c = 0) or
                (in_pwr_2 = '0' and MAX_PWR_2_c = 1) else
                '0';

  -- resize the inputs
  in_real_s <= in_real(in_real_s'length - 1 downto 0);
  in_imag_s <= in_imag(in_imag_s'length - 1 downto 0);


  ---------------------------------------------------------------------------
  -- Complex multiplier
  -----------------------------------------------------------------------------
  -- when max pwr2 is 1 and natural order core, if nps is pwr of 4, then no complex mult
  -- is required, therefore do not enable it (the cma_out_valid was causing the bfi to start
  -- calculating and get into a weird state).
  cma_in_valid <= '0' when in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") else
                    in_valid;
  cma_in_sop     <= in_sop;
  cma_in_eop     <= in_eop;
  cma_in_inverse <= in_inverse;
  cma_in_control <= in_control;


  gen_normal_twrom_connect : if HYPER_OPTIMIZATION /= 1 generate
  begin
    realtwid_s       <= realtwid;
    imagtwid_s       <= imagtwid;
    twid_rd_en       <= twid_rd_en_tmp;
    twidaddr         <= twidaddr_tmp;
    cma_in_real      <= in_real_s;
    cma_in_imag      <= in_imag_s;
  end generate gen_normal_twrom_connect;
  -- pipelined output, for optimization on Stratix 10
  gen_S10_pipelined_twrom_connect : if HYPER_OPTIMIZATION = 1 generate
  begin
    realtwid_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => PIPELINE_STAGES,
                 SIGNAL_WIDTH => TWIDWIDTH_g)
    port map (clk              => clk,
              clken            => enable,
              reset            => '0',
              signal_w         => realtwid,
              signal_pipelined => realtwid_s);
    imagtwid_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => PIPELINE_STAGES,
                 SIGNAL_WIDTH => TWIDWIDTH_g)
    port map (clk              => clk,
              clken            => enable,
              reset            => '0',
              signal_w         => imagtwid,
              signal_pipelined => imagtwid_s);
    twid_rd_en_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => PIPELINE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => enable,
              reset            => '0',
              signal_w(0)         => twid_rd_en_tmp,
              signal_pipelined(0) => twid_rd_en);
    twidaddr_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => PIPELINE_STAGES,
                 SIGNAL_WIDTH => log2_ceil(MAX_FFTPTS_g))
    port map (clk              => clk,
              clken            => enable,
              reset            => '0',
              signal_w         => twidaddr_tmp,
              signal_pipelined => twidaddr);
    cma_in_real_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => 2*PIPELINE_STAGES,
                 SIGNAL_WIDTH => CMA_IN_DATAWIDTH_c)
    port map (clk              => clk,
              clken            => enable,
              reset            => '0',
              signal_w         => in_real_s,
              signal_pipelined => cma_in_real);
    cma_in_imag_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => 2*PIPELINE_STAGES,
                 SIGNAL_WIDTH => CMA_IN_DATAWIDTH_c)
    port map (clk              => clk,
              clken            => enable,
              reset            => '0',
              signal_w         => in_imag_s,
              signal_pipelined => cma_in_imag);
  end generate gen_S10_pipelined_twrom_connect;

  -- not instantiated in the first stage as there is no multiplication required
  gen_cma : if FIRST_STAGE_c = 0 generate
  begin

    cma_fixedpt : if REPRESENTATION_g = "FIXEDPT" generate
    begin
    cma_inst : auk_dspip_r22sdf_cma
      generic map (
        DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
        DATAWIDTH_g      => CMA_IN_DATAWIDTH_c,
        TWIDWIDTH_g      => TWIDWIDTH_g,
        INPUT_FORMAT_g   => INPUT_FORMAT_g,
        PIPELINE_g       => MULT_PIPELINE_c,
        OPTIMIZE_SPEED_g => 0,
        OPTIMIZE_MEM_g   => OPTIMIZE_MEM_g,
        MAX_FFTPTS_g     => MAX_FFTPTS_g,
        GROW_g           => CMA_GROW_g,
        DSP_ROUNDING_g   => DSP_ROUNDING_g,
        DSP_ARCH_g       => DSP_ARCH_g
        )
      port map (
        clk         => clk,
        reset       => reset,
        enable      => enable,
        in_sop      => cma_in_sop,
        in_eop      => cma_in_eop,
        in_inverse  => cma_in_inverse,
        in_fftpts   => in_fftpts,
        in_radix_2  => in_radix_2,
        in_valid    => cma_in_valid,
        in_control  => cma_in_control,
        in_real     => cma_in_real,
        in_imag     => cma_in_imag,
        realtwid    => realtwid_s,
        imagtwid    => imagtwid_s,
        twidaddr    => twidaddr_s,
        out_real    => cma_out_real,
        out_imag    => cma_out_imag,
        out_control => cma_out_control,
        out_inverse => cma_out_inverse,
        out_sop     => cma_out_sop,
        out_eop     => cma_out_eop,
        out_valid   => cma_out_valid);
    end generate cma_fixedpt;

    cma_fp : if REPRESENTATION_g = "FLOATPT" generate
    begin
    cma_inst : auk_dspip_r22sdf_cma_fp
      generic map (
        DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
        INPUT_FORMAT_g   => INPUT_FORMAT_g,
        PIPELINE_g       => MULT_PIPELINE_c,
        MAX_FFTPTS_g     => MAX_FFTPTS_g
        )
      port map (
        clk         => clk,
        reset       => reset,
        enable      => enable,
        in_sop      => cma_in_sop,
        in_eop      => cma_in_eop,
        in_inverse  => cma_in_inverse,
        in_fftpts   => in_fftpts,
        in_radix_2  => in_radix_2,
        in_valid    => cma_in_valid,
        in_control  => cma_in_control,
        in_real     => cma_in_real,
        in_imag     => cma_in_imag,
        realtwid    => realtwid_s,
        imagtwid    => imagtwid_s,
        twidaddr    => twidaddr_s,
        out_real    => cma_out_real,
        out_imag    => cma_out_imag,
        out_control => cma_out_control,
        out_inverse => cma_out_inverse,
        out_sop     => cma_out_sop,
        out_eop     => cma_out_eop,
        out_valid   => cma_out_valid);
      end generate cma_fp;

  end generate gen_cma;

  gen_twid_addr: if FIRST_STAGE_c = 0  generate
     signal cma_in_valid_d : std_logic;
  begin   
    cma_in_valid_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          cma_in_valid_d <= '0';
        elsif enable = '1' then
          cma_in_valid_d <= cma_in_valid;
        end if;
      end if;
    end process cma_in_valid_p;
    
    
    twidaddr_tmp <= (others => '0') when (INPUT_FORMAT_g = "BIT_REVERSED" and
                                         ((cma_in_valid_d = '0' and MAX_PWR_2_c = 1) or (cma_in_valid = '0' and MAX_PWR_2_c = 0)))
                   or ((INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") and in_sel = '1')
                   else
                   twidaddr_s;

    twid_rd_en_tmp <= enable when INPUT_FORMAT_g = "BIT_REVERSED" and MAX_PWR_2_c = 1 else
                  cma_in_valid and not in_sel when (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") else
                  cma_in_valid;
    
   end generate gen_twid_addr;

  no_gen_twid_addr: if FIRST_STAGE_c /= 0  generate
    twidaddr_tmp <= (others => '0');
    twid_rd_en_tmp <= '0';
  end generate no_gen_twid_addr;

  -- first stage, no multiplier
  gen_no_cma : if FIRST_STAGE_c = 1 generate
  begin
    cma_out_real    <= std_logic_vector(resize(signed(in_real_s), cma_out_real'length));
    cma_out_imag    <= std_logic_vector(resize(signed(in_imag_s), cma_out_imag'length));
    cma_out_control <= cma_in_control;
    cma_out_valid   <= cma_in_valid;
    cma_out_inverse <= cma_in_inverse;
    cma_out_sop     <= cma_in_sop;
    cma_out_eop     <= cma_in_eop;
  end generate gen_no_cma;

  ---------------------------------------------------------------------------

  ---------------------------------------------------------------------------
  -- BFI
  -----------------------------------------------------------------------------
  --bfi inputs, input are always taken directkly from the input to the block
  bfi_in_real    <= cma_out_real;
  bfi_in_imag    <= cma_out_imag;
  bfi_in_valid   <= cma_out_valid;
  bfi_in_sop     <= cma_out_sop;
  bfi_in_eop     <= cma_out_eop;
  --bfi_in_control <= cma_out_control;
  bfi_in_control <= in_control;
  bfi_in_inverse <= cma_out_inverse;
  bfi_in_radix_2 <= in_radix_2;

  gen_bfi : if DELAY_BFI_c > 0 generate
  begin
      bfi_inst : auk_dspip_r22sdf_bfi
        generic map (
          STAGE_g          => STAGE_g,
          DATAWIDTH_g      => BFI_IN_DATAWIDTH_c,
          TWIDWIDTH_g      => TWIDWIDTH_g,
          NUM_STAGES_g     => NUM_STAGES_g,
          GROW_g           => GROW_BFI_c,
          PIPELINE_g       => BFI_ADD_PIPELINE_c,
          INPUT_FORMAT_g   => INPUT_FORMAT_g,
          REPRESENTATION_g => REPRESENTATION_g,
          MAX_FFTPTS_g     => MAX_FFTPTS_g,
          DELAY_g          => DELAY_BFI_c)
        port map (
          clk          => clk,
          reset        => reset,
          enable       => enable,
          in_fftpts    => in_fftpts,
          in_radix_2   => bfi_in_radix_2,
          in_sel       => in_sel,
          in_control   => bfi_in_control,
          out_control  => bfi_out_control,
          in_inverse   => bfi_in_inverse,
          in_sop       => bfi_in_sop,
          in_eop       => bfi_in_eop,
          in_valid     => bfi_in_valid,
          in_real      => bfi_in_real,
          in_imag      => bfi_in_imag,
          del_in_real  => bfi_del_in_real,
          del_in_imag  => bfi_del_in_imag,
          out_real     => bfi_out_real,
          out_imag     => bfi_out_imag,
          del_out_real => bfi_del_out_real,
          del_out_imag => bfi_del_out_imag,
          out_inverse  => bfi_out_inverse,
          out_sop      => bfi_out_sop,
          out_eop      => bfi_out_eop,
          out_valid    => bfi_out_valid);

    -----------------------------------------------------------------------------
    -- DELAY BFI
    -----------------------------------------------------------------------------
    --enable the delay block shifting. Shift while bfi is processing. We need
    --to perform a calculation to determine when the bfi is processing becuase
    --for floating point the pipeline delay can be more than the smallest frame
    --size, so it is not enough to rely on bfi_in_valid and bfi_out_valid
    --becuase there will be a small gap where neither bfi_in_valid or
    --bfi_out_valid is asserted, but the data is being processed in the bfi.
    processing_bfi_cnt_p : process (clk)
    begin  
    if rising_edge(clk) then 
      if reset = '1' then  
        bfi_processing_cnt <= 0;
      elsif enable = '1' then  
        if bfi_in_sop = '1' and bfi_in_valid = '1' then
            if not( bfii_in_eop = '1' and bfii_in_valid = '1') then
            bfi_processing_cnt <= bfi_processing_cnt + 1;
          end if;
          elsif  bfii_in_eop = '1' and bfii_in_valid = '1'   then
          if not (bfi_in_sop = '1' and bfi_in_valid = '1') then
            bfi_processing_cnt <= bfi_processing_cnt - 1;
          end if;
        end if;
      end if;
    end if;
  end process processing_bfi_cnt_p;


  bfi_processing_p : process (clk)
  begin 
    if rising_edge(clk) then
      if reset = '1' then
        bfi_processing <= '0';
      elsif enable = '1' then
        bfi_processing <= or_reduce(to_unsigned(bfi_processing_cnt, log2_ceil(BFI_FRAME_OVERLAP_c)));
      end if;
    end if;
  end process bfi_processing_p;
  bfi_delay_blk_enable <= enable and (bfi_in_valid or bfi_processing);

    -- delay block 
    bfi_delblk_real : auk_dspip_r22sdf_delay
      generic map (
        DEVICE_FAMILY_g => DEVICE_FAMILY_g,
        DATAWIDTH_g  => bfi_del_out'length,
        MAX_FFTPTS_g => MAX_FFTPTS_g,
        PIPELINE_g   => BFI_ADD_PIPELINE_c + 1,
        DELAY_g      => DELAY_BFI_c)
      port map (
        clk     => clk,
        reset   => reset,
        radix_2 => bfi_in_radix_2,
        enable  => bfi_delay_blk_enable,
        datain  => bfi_del_out,
        dataout => bfi_del_in);

    bfi_del_in_real <= bfi_del_in(bfi_del_in'high downto bfi_del_in_imag'length);
    bfi_del_in_imag <= bfi_del_in(bfi_del_in_imag'length - 1 downto 0);
    bfi_del_out     <= bfi_del_out_real & bfi_del_out_imag;

  end generate gen_bfi;


  gen_no_bfi : if DELAY_BFI_c = 0 generate
  begin  -- generate gen_no_delay
    bfi_out_valid   <= bfi_in_valid;
    bfi_out_inverse <= bfi_in_inverse;
    bfi_out_sop     <= bfi_in_sop;
    bfi_out_eop     <= bfi_in_eop;
    bfi_out_real    <= std_logic_vector(resize(signed(bfi_in_real), bfi_out_real'length));
    bfi_out_imag    <= std_logic_vector(resize(signed(bfi_in_imag), bfi_out_imag'length));
    bfi_out_control <= bfi_in_control;
  end generate gen_no_bfi;
---------------------------------------------------------------------------


  -----------------------------------------------------------------------------
  -- BFII
  -----------------------------------------------------------------------------
  gen_bfii : if DELAY_BFII_c > 0 generate
  begin
    -- input mux when bit reversed inputs
    bfii_in_valid <= in_valid when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                     bfi_out_valid;
    bfii_in_sop <= in_sop when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                   bfi_out_sop;
    bfii_in_eop <= in_eop when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                   bfi_out_eop;
    bfii_in_inverse <= in_inverse when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                       bfi_out_inverse;
    bfii_in_control <= in_control when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                       bfi_out_control;
    bfii_in_real <= std_logic_vector(resize(signed(in_real_s), bfii_in_real'length)) when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                    bfi_out_real;
    bfii_in_imag <= std_logic_vector(resize(signed(in_imag_s), bfii_in_imag'length)) when in_radix_2 = '1' and INPUT_FORMAT_g = "BIT_REVERSED" and MUX_STAGE_c = 1 else
                    bfi_out_imag;

    bfii_inst : auk_dspip_r22sdf_bfii
      generic map (
        STAGE_g          => STAGE_g,
        DATAWIDTH_g      => BFII_IN_DATAWIDTH_c,
        TWIDWIDTH_g      => TWIDWIDTH_g,
        NUM_STAGES_g     => NUM_STAGES_g,
        MAX_FFTPTS_g     => MAX_FFTPTS_g,
        PIPELINE_g       => BFII_ADD_PIPELINE_c ,
        REPRESENTATION_g => REPRESENTATION_g,
        GROW_g           => GROW_BFII_c,
        INPUT_FORMAT_g   => INPUT_FORMAT_g,
        DELAY_g          => DELAY_BFII_c)
      port map (
        clk          => clk,
        reset        => reset,
        enable       => enable,
        in_valid     => bfii_in_valid,
        in_sop       => bfii_in_sop,
        in_inverse   => bfii_in_inverse,
        in_eop       => bfii_in_eop,
        in_fftpts    => in_fftpts,
        in_radix_2   => in_radix_2,
        in_sel       => '0',
        in_control   => bfii_in_control,
        -- curr_control => twidaddr,
        out_control  => bfii_out_control,
        in_real      => bfii_in_real,
        in_imag      => bfii_in_imag,
        del_in_real  => bfii_del_in_real,
        del_in_imag  => bfii_del_in_imag,
        out_real     => bfii_out_real,
        out_imag     => bfii_out_imag,
        del_out_real => bfii_del_out_real,
        del_out_imag => bfii_del_out_imag,
        out_inverse  => bfii_out_inverse,
        out_sop      => bfii_out_sop,
        out_eop      => bfii_out_eop,
        out_valid    => bfii_out_valid);

    ---------------------------------------------------------------------------
    -- BFII DELAY BLCOK
    ---------------------------------------------------------------------------
     --enable the delay block shifting. Shift while bfii is processing. This
     --can be deduced from the bfii_in_valid and bfii_out_valid because the
     --pipeline delay through the bfii is always < the smallest size frame (ie
     --for floating point this is 32)
    bfii_delay_blk_enable <= enable and (bfii_in_valid or bfii_out_valid);

    -- delay block 
    bfii_delblk_real : auk_dspip_r22sdf_delay
      generic map (
        DEVICE_FAMILY_g => DEVICE_FAMILY_g,
        DATAWIDTH_g  => bfii_del_out'length,
        MAX_FFTPTS_g => MAX_FFTPTS_g,
        PIPELINE_g   => BFII_ADD_PIPELINE_c + 1,
        DELAY_g      => DELAY_BFII_c)
      port map (
        clk     => clk,
        reset   => reset,
        radix_2 => in_radix_2,
        enable  => bfii_delay_blk_enable,
        datain  => bfii_del_out,
        dataout => bfii_del_in);

    bfii_del_in_real <= bfii_del_in(bfii_del_in'high downto bfii_del_in_imag'length);
    bfii_del_in_imag <= bfii_del_in(bfii_del_in_imag'length - 1 downto 0);
    bfii_del_out     <= bfii_del_out_real & bfii_del_out_imag;
    
  end generate gen_bfii;


  gen_no_bfii : if DELAY_BFII_c = 0 generate
  begin  -- generate gen_no_delay
    bfii_in_valid   <= bfi_in_valid;
    bfii_in_sop     <= bfi_in_sop;
    bfii_in_eop     <= bfi_in_eop;
    bfii_in_inverse <= bfi_in_inverse;
    bfii_in_real    <= std_logic_vector(resize(signed(bfi_in_real), bfii_in_real'length));
    bfii_in_imag    <= std_logic_vector(resize(signed(bfi_in_imag), bfii_in_imag'length));
    bfii_in_control <= bfi_in_control;
    bfii_out_valid   <= bfi_out_valid;
    bfii_out_sop     <= bfi_out_sop;
    bfii_out_eop     <= bfi_out_eop;
    bfii_out_inverse <= bfi_out_inverse;
    bfii_out_real    <= std_logic_vector(resize(signed(bfi_out_real), bfii_out_real'length));
    bfii_out_imag    <= std_logic_vector(resize(signed(bfi_out_imag), bfii_out_imag'length));
    bfii_out_control <= bfi_out_control;
  end generate gen_no_bfii;
  ---------------------------------------------------------------------------



  -- output select is based on whether this stage is radix 2 or radix 2^2.
  -- For radix 2, the output is taken after the first stage. The output is
  -- resized, which probably isnt a problem since the radix 2 stage can
  -- always be at the end. 
  out_real <= std_logic_vector(resize2(signed(bfi_out_real), out_real'length)) when (in_pwr_2 = '1' and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2")) else
              std_logic_vector(resize2(signed(in_real), out_real'length)) when (in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1) else
              std_logic_vector(resize2(signed(bfii_out_real), out_real'length));
  out_imag <= std_logic_vector(resize2(signed(bfi_out_imag), out_imag'length)) when (in_pwr_2 = '1' and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER"or INPUT_FORMAT_g = "-N/2_to_N/2")) else
              std_logic_vector(resize2(signed(in_imag), out_real'length)) when (in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1) else
              std_logic_vector(resize2(signed(bfii_out_imag), out_real'length));

  --
  out_valid <=  out_valid_s;
  out_valid_s <= bfi_out_valid when in_pwr_2 = '1' and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") else
               in_valid when in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1 else
               bfii_out_valid;

  out_sop <= bfi_out_sop when in_pwr_2 = '1' and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") else
             in_sop when in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1 else
             bfii_out_sop;
  out_eop <=  out_eop_s;
  out_eop_s <= bfi_out_eop when in_pwr_2 = '1' and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") else
             in_eop when in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1 else
             bfii_out_eop;

  out_inverse <= bfi_out_inverse when in_pwr_2 = '1' and MUX_STAGE_c = 1 and (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") else
                 in_inverse when in_pwr_2 = '0' and MAX_PWR_2_c = 1 and MUX_STAGE_c = 1 else
                 bfii_out_inverse;

  out_control <= bfii_out_control;


  processing_cnt_p : process (clk)
  begin  -- process processing_cnt_p
    if rising_edge(clk) then 
      if reset = '1' then  
        processing_cnt <= 0;
      elsif enable = '1' then  
        if in_sop = '1' and in_valid = '1' then
          if not( out_eop_s = '1' and out_valid_s = '1') then
            processing_cnt <= processing_cnt + 1;
          end if;
        elsif  out_eop_s = '1' and out_valid_s = '1'   then
          if not (in_sop = '1' and in_valid = '1') then
            processing_cnt <= processing_cnt - 1;
          end if;
        end if;
      end if;
    end if;
  end process processing_cnt_p;


  processing_p : process (clk)
  begin  -- process processing_p
    if rising_edge(clk) then
      if reset = '1' then
        processing <= '0';
      elsif enable = '1' then
        processing <= or_reduce(to_unsigned(processing_cnt, log2_ceil(FRAME_OVERLAP_c)));
      end if;
    end if;
  end process processing_p;


  --synthesis translate_off

  gen_debug : if DEBUG_g = 1 generate
    signal bfi_data  : std_logic_vector(2*(BFI_OUT_DATAWIDTH_c) - 1 downto 0);
    signal bfii_data : std_logic_vector(2*(BFII_OUT_DATAWIDTH_c) - 1 downto 0);
    signal cma_data  : std_logic_vector(2*(CMA_OUT_DATAWIDTH_c) -1 downto 0);
    signal reset_n   : std_logic;

    component auk_dspip_avalon_streaming_monitor is
      generic (
        FILENAME_g         : string;
        COMPARE_g          : boolean;
        COMPARE_TO_FILE_g  : string;
        IGNORE_PREFIX_g    : character;
        SYMBOLS_PER_BEAT_g : natural;
        SYMBOL_DELIMETER_g : string;
        PRINT_CLK_REPORT_g : boolean;
        SYMBOL_DATAWIDTH_g : natural);
      port (
        clk       : in std_logic;
        reset_n   : in std_logic;
        -- enables the model
        enable    : in std_logic;
        -- atlantic signals
        avs_valid : in std_logic;
        avs_ready : in std_logic;
        avs_sop   : in std_logic;
        avs_eop   : in std_logic;
        -- data contains real and imaginary data, imaginary in LSW, real in MSW
        avs_data  : in std_logic_vector(SYMBOLS_PER_BEAT_g*(SYMBOL_DATAWIDTH_g) - 1 downto 0));
    end component auk_dspip_avalon_streaming_monitor;
    
    
  begin
    bfi_data  <= bfi_out_real & bfi_out_imag;
    bfii_data <= bfii_out_real & bfii_out_imag;
    cma_data  <= cma_out_real & cma_out_imag;
    reset_n   <= not reset;
    bfi_monitor : auk_dspip_avalon_streaming_monitor
      generic map (
        FILENAME_g         => "sim_stage_" & integer'image(STAGE_g) & "_bfi.txt",
        COMPARE_g          => false,
        COMPARE_TO_FILE_g  => "",
        IGNORE_PREFIX_g    => '#',
        SYMBOLS_PER_BEAT_g => 2,
        SYMBOL_DELIMETER_g => " ",
        PRINT_CLK_REPORT_g => false,
        SYMBOL_DATAWIDTH_g => BFI_OUT_DATAWIDTH_c)
      port map (
        clk       => clk,
        reset_n   => reset_n,
        -- enables the model
        enable    => enable,
        -- atlantic signals
        avs_valid => bfi_out_valid,
        avs_ready => '1',
        avs_sop   => '1',
        avs_eop   => '1',
        -- data contains real and imaginary data, imaginary in LSW, real in MSW
        avs_data  => bfi_data);

    bfii_monitor : auk_dspip_avalon_streaming_monitor
      generic map (
        FILENAME_g         => "sim_stage_" & integer'image(STAGE_g) & "_bfii.txt",
        COMPARE_g          => false,
        COMPARE_TO_FILE_g  => "",
        IGNORE_PREFIX_g    => '#',
        SYMBOLS_PER_BEAT_g => 2,
        SYMBOL_DELIMETER_g => " ",
        PRINT_CLK_REPORT_g => false,
        SYMBOL_DATAWIDTH_g => BFII_OUT_DATAWIDTH_c)
      port map (
        clk       => clk,
        reset_n   => reset_n,
        -- enables the model
        enable    => enable,
        -- atlantic signals
        avs_valid => bfii_out_valid,
        avs_ready => '1',
        avs_sop   => '1',
        avs_eop   => '1',
        -- data contains real and imaginary data, imaginary in LSW, real in MSW
        avs_data  => bfii_data);
    cma_monitor : auk_dspip_avalon_streaming_monitor
      generic map (
        FILENAME_g         => "sim_stage_" & integer'image(STAGE_g) & "_cma.txt",
        COMPARE_g          => false,
        COMPARE_TO_FILE_g  => "",
        IGNORE_PREFIX_g    => '#',
        SYMBOLS_PER_BEAT_g => 2,
        SYMBOL_DELIMETER_g => " ",
        PRINT_CLK_REPORT_g => false,
        SYMBOL_DATAWIDTH_g => CMA_OUT_DATAWIDTH_c)
      port map (
        clk       => clk,
        reset_n   => reset_n,
        -- enables the model
        enable    => enable,
        -- atlantic signals
        avs_valid => cma_out_valid,
        avs_ready => '1',
        avs_sop   => '1',
        avs_eop   => '1',
        -- data contains real and imaginary data, imaginary in LSW, real in MSW
        avs_data  => cma_data);
  end generate gen_debug;
  --synthesis translate_on
end architecture rtl;
