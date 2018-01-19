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
-- $RCSfile: auk_dspip_r22sdf_core.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_core.vhd,v $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   :  <Author name>
--
-- Project      :  <project name>
--
-- Description : 
--
-- Calculates the FFT of an "fftpts" size data stream 
--
-- To faciliate a top level that can be configured for any length FFT
-- without changing this file, all data inputs and outputs are resized at
-- the input and output ports of the stage to be the maximum datawidth (ie
-- DATAWIDTH_c + MAX_GROW_c). The synthesiser removes the extra logic very
-- efficiently (in fact the results are better using this method than
-- explicitly declaring each stage).
-- All constants used in this file are contained within r22sdf_pkg. This
-- means that this file can be used without change and the number of stages
-- can be increased or decreased by changing the values of the constnats
-- in the package.

--
-- $Log: auk_dspip_r22sdf_core.vhd,v $
-- Revision 1.17  2007/07/04 11:44:25  kmarks
-- syntax error. ops
--
-- Revision 1.16  2007/07/03 19:16:00  kmarks
-- handle the data growth better
--
-- Revision 1.15  2007/06/28 16:44:51  kmarks
-- Changed prune to cma_out_datawidth - I think it is clearer what it means.
--
-- Revision 1.14  2007/06/28 14:00:05  kmarks
-- prune should only be NUM_STAGES_g   -1 long (first stage doesnt have Complex multiplier)
--
-- Revision 1.13  2007/06/28 13:48:22  kmarks
-- added pruning infrastructure
--
-- Revision 1.12  2007/05/21 16:18:45  kmarks
-- bug fixes - works for N= 64 with bit reversed inputs
--
-- Revision 1.11  2007/05/11 10:10:03  kmarks
-- Added floating point, untested as yet.
--
-- Revision 1.10  2007/05/04 08:19:37  kmarks
-- working after rearranging stage to have multiplication first.
--
-- Revision 1.9  2007/02/07 14:46:15  kmarks
-- added dynamic inverse testing and fixed the inverse fft bug.
--
-- Revision 1.8  2007/01/25 12:38:50  kmarks
-- added bit reversal optimisations
--
-- Revision 1.7  2007/01/12 13:31:15  kmarks
-- add OPTIMIZE_MEM_g and optimized twiddle rom instantiation.
--
-- Revision 1.6  2006/12/19 18:07:30  kmarks
-- Updated to make use of the rounding in the stratix III DSP block.
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
-- Revision 1.3  2006/08/24 12:49:27  kmarks
-- various bug fixes and added bit reversal.
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
use ieee.math_real.all;

library work;
use work.auk_dspip_math_pkg.all;
use work.auk_dspip_text_pkg.all;

use work.auk_dspip_r22sdf_lib_pkg.all;


entity auk_dspip_r22sdf_core is

  generic (
    DEVICE_FAMILY_g   : string; 
    DATAWIDTH_g       : natural := 18;
    TWIDWIDTH_g       : natural := 18;
    MAX_FFTPTS_g      : natural := 1024;
    NUM_STAGES_g      : natural := 5;
    MAX_GROW_g        : natural := 14;
    PIPELINE_g        : natural := 0;
    DSP_ROUNDING_g    : natural := 1;
    OPTIMIZE_MEM_g    : natural := 1;
    DEBUG_g           : natural := 0;
    PRUNE_g        : string  := "3 2 1 0";
    INPUT_FORMAT_g    : string  := "NATURAL_ORDER";
    REPRESENTATION_g  : string  := "FIXEDPT";
    DSP_ARCH_g        : natural := 0;
    TWIDROM_BASE_g    : string  := "../tb/"
    );
  port (
    clk           : in  std_logic;
    reset         : in  std_logic;
    enable        : in  std_logic;
    in_sop        : in  std_logic;
    in_eop        : in  std_logic;
    in_fftpts     : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_pwr_2      : in  std_logic;
    in_valid      : in  std_logic;
    in_inverse    : in  std_logic;
    stg_input_sel : in  std_logic_vector(NUM_STAGES_g - 1 downto 0);
    in_real       : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    in_imag       : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    processing    : out std_logic;
    out_stall     : in  std_logic;
    out_real      : out std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
    out_imag      : out std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
    out_sop       : out std_logic;
    out_eop       : out std_logic;
    out_valid     : out std_logic
    );

end entity auk_dspip_r22sdf_core;


architecture rtl of auk_dspip_r22sdf_core is

  constant MAX_PWR_2_c : natural := log2_ceil(MAX_FFTPTS_g)rem 2;

  -- array types
  type data_array_t is array (NUM_STAGES_g - 1 downto 0) of
    std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);

  type twid_array_t is array (NUM_STAGES_g - 1 downto 0) of
    std_logic_vector(TWIDWIDTH_g - 1 downto 0);

  type control_array_t is array (NUM_STAGES_g - 1 downto 0) of
    std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);

  signal stg_in_real  : data_array_t;
  signal stg_in_imag  : data_array_t;
  signal stg_out_real : data_array_t;
  signal stg_out_imag : data_array_t;

  signal stg_in_control  : control_array_t;
  signal stg_out_control : control_array_t;
  signal stg_twidaddr    : control_array_t;

  signal stg_realtwid : twid_array_t;
  signal stg_imagtwid : twid_array_t;

  signal stg_in_valid    : std_logic_vector(NUM_STAGES_g- 1 downto 0);
  signal stg_in_inverse  : std_logic_vector(NUM_STAGES_g- 1 downto 0);
  signal stg_in_sop      : std_logic_vector(NUM_STAGES_g- 1 downto 0);
  signal stg_in_eop      : std_logic_vector(NUM_STAGES_g- 1 downto 0);
  signal stg_out_valid   : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal stg_out_inverse : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal stg_out_sop     : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal stg_out_eop     : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal stg_twid_rd_en  : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  -- indicates that a stage is processing incoming data
  signal stg_processing  : std_logic_vector(NUM_STAGES_g - 1 downto 0);

  signal in_enable         : std_logic;
  signal control_enable    : std_logic;
  signal stg_in_real_first : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  signal stg_in_imag_first : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  signal stg_control_first : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);

  -- inverse control
  signal in_real_inv : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_inv : std_logic_vector(DATAWIDTH_g - 1 downto 0);

  constant TWID_DELAY_c : natural := 3;
  type     twid_delay_t is array (NUM_STAGES_g - 1 downto 0) of
    std_logic_vector(TWID_DELAY_c -1 downto 0);
  signal twid_rd_en_d : twid_delay_t;


  signal difference  : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal out_inverse : std_logic;

  function get_prune_array return array_natural_t is
    variable prune_v : array_natural_t(0 to NUM_STAGES_g - 1);
  begin
    prune_v(0 to NUM_STAGES_g -1) := parse_string_array(PRUNE_g, NUM_STAGES_g);
    return prune_v;
  end function get_prune_array;

  constant prune_array : array_natural_t := get_prune_array;




  function getDatawidths (index : natural)
    return array_natural_t is
    variable stage_datawidths_v : array_natural_t(NUM_STAGES_g -1 downto 0);  -- actual stage datawidth
                                                    -- at input to stage
    variable grow_v             : array_natural_t(NUM_STAGES_g -1 downto 0);  -- how many bits the stage should grow
    variable cma_grow_v         : array_natural_t(NUM_STAGES_g -1 downto 0);  -- how many bits the cma should grow
    variable prune_array_v      : array_natural_t(NUM_STAGES_g -1 downto 0);
  begin  -- function getDatawidths
    

    for i in 0 to NUM_STAGES_g - 1 loop

      if REPRESENTATION_g = "FIXEDPT" then -- in the case of fixed point data, calculate the data width
      
        prune_array_v := get_prune_array;

        --------------------------------------
        -- Odd & Even number of stages, pwr 4
        --------------------------------------
        -- Second stage always grows 3, otherwise 2.
        if ((MAX_PWR_2_c = 0)) then
          if (i = 1) then
            grow_v(i)     := 3;
            cma_grow_v(i) := 1;
          else
            grow_v(i)     := 2;
            cma_grow_v(i) := 0;
          end if;

        --------------------------------------
        -- Odd & Even number of stages, pwr 2
        --------------------------------------
        else
          if (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") then
            -- Natural order : Second stage always grows 3, last stage (radix 2) grows 1, otherwise 2.
            if (i = 1) then
              grow_v(i)     := 3;
              cma_grow_v(i) := 1;
            else
              cma_grow_v(i) := 0;
              if (i = NUM_STAGES_g-1) then
                grow_v(i) := 1;
              else
                grow_v(i) := 2;
              end if;
            end if;
          else
            -- Bit reversed order: First stage grows 1, second stage grows 3, otherwise 2.
            if (i = 0) then
              grow_v(i)     := 1;
              cma_grow_v(i) := 0;
            elsif (i = 1) then
              grow_v(i)     := 3;
              cma_grow_v(i) := 1;
            else
              grow_v(i)     := 2;
              cma_grow_v(i) := 0;
            end if;
          end if;
        end if;


        
        -- prune the cma_grow array
        -- cma_grow_v(i) := cma_grow_v(i) - prune_array_v(i);

        if (i = 0) then
          stage_datawidths_v(0) := DATAWIDTH_g;
        else
          stage_datawidths_v(i) := stage_datawidths_v(i - 1) + grow_v(i - 1) - prune_array_v(i);
        end if;
        

      else -- in the case of floating point data, no need to change data width between stages
        grow_v(i)     := 0;
        cma_grow_v(i) := 0;
        stage_datawidths_v(i) := 32;

      end if;


      
      
    end loop;  -- i

    if index = 0 then
      return stage_datawidths_v;
    else
      return cma_grow_v;
    end if;

  end function getDatawidths;

  constant stage_datawidth_array : array_natural_t := getDatawidths(0);
  constant cma_grow_array : array_natural_t := getDatawidths(1);


begin  -- architecture r22sdf_rtl


  -- enable controller
  ena_ctrl : auk_dspip_r22sdf_enable_control
    generic map (
      NUM_STAGES_g => NUM_STAGES_g,
      MAX_FFTPTS_g => MAX_FFTPTS_g)
    port map (
      clk         => clk,
      reset       => reset,
      enable      => enable,
      stall       => out_stall,
      in_sop      => in_sop,
      in_eop      => in_eop,
      in_fftpts   => in_fftpts,
      in_pwr_2    => in_pwr_2,
      out_enable  => in_enable,
      out_control => open);

  control_enable <= in_enable;

  processing <= or_reduce(stg_processing);


  -- swap inputs on inverse
  in_real_inv <= in_real when in_inverse = '0' else
                 in_imag;
  in_imag_inv <= in_imag when in_inverse = '0' else
                 in_real;

  -- assign input to first stage
  stg_in_real_first <= std_logic_vector(resize(signed(in_real_inv), DATAWIDTH_g + MAX_GROW_g));
  stg_in_imag_first <= std_logic_vector(resize(signed(in_imag_inv), DATAWIDTH_g + MAX_GROW_g));

  stg_control_first <= (others => '0');
  -- assign twiddles to first stage (twiddles are 0)
  stg_realtwid(0)   <= (others => '0');
  stg_imagtwid(0)   <= (others => '0');


  -----------------------------------------------------------------------------
  -- NATURAL ORDER INPUTS
  -----------------------------------------------------------------------------

  gen_natural_order_core : if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" generate


  begin


    -- mux for stage 0 inputs
    stg_in_real(0) <= stg_in_real_first when stg_input_sel(0) = '1' else
                      (others => '0');
    stg_in_imag(0) <= stg_in_imag_first when stg_input_sel(0) = '1' else
                      (others => '0');
    stg_in_valid(0) <= in_valid when stg_input_sel(0) = '1' else
                       '0';
    stg_in_sop(0) <= in_sop when stg_input_sel(0) = '1' else
                     '0';
    stg_in_eop(0) <= in_eop when stg_input_sel(0) = '1' else
                     '0';
    stg_in_control(0) <= stg_control_first when stg_input_sel(0) = '1' else
                         (others => '0');

    stg_in_inverse(0) <= in_inverse when stg_input_sel(0) = '1' else
                         '0';

    -- assign outputs, output is always taken from the last stage when data input is in natural order
    out_inverse <= stg_out_inverse(NUM_STAGES_g - 1) and control_enable;
    out_valid   <= stg_out_valid(NUM_STAGES_g - 1) and control_enable;
    out_sop     <= stg_out_sop(NUM_STAGES_g - 1) and control_enable;
    out_eop     <= stg_out_eop(NUM_STAGES_g - 1) and control_enable;

    -- swap outputs on inverse
    out_real <= stg_out_real(NUM_STAGES_g - 1) when out_inverse = '0' else
                stg_out_imag(NUM_STAGES_g - 1);
    out_imag <= stg_out_imag(NUM_STAGES_g - 1) when out_inverse = '0' else
                stg_out_real(NUM_STAGES_g - 1);

    -- STAGEs
    gen_stages : for i in 0 to NUM_STAGES_g - 1 generate

    begin
      r22_stage : auk_dspip_r22sdf_stage
        generic map (
          DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
          STAGE_g          => i + 1,
          NUM_STAGES_g     => NUM_STAGES_g,
          DATAWIDTH_g      => stage_datawidth_array(i),
          TWIDWIDTH_g      => TWIDWIDTH_g,
          INPUT_FORMAT_g   => INPUT_FORMAT_g,
          MAX_FFTPTS_g     => MAX_FFTPTS_g,
          MAX_DATAWIDTH_g  => DATAWIDTH_g + MAX_GROW_g,
          PIPELINE_g       => PIPELINE_g,
          OPTIMIZE_MEM_g   => OPTIMIZE_MEM_g,
          DEBUG_g          => DEBUG_g,
          DSP_ROUNDING_g   => DSP_ROUNDING_g,
          REPRESENTATION_g => REPRESENTATION_g,
          DSP_ARCH_g       => DSP_ARCH_g,
          CMA_GROW_g       => cma_grow_array(i)
          )
        port map (
          clk         => clk,
          reset       => reset,
          enable      => control_enable,
          in_inverse  => stg_in_inverse(i),
          in_sop      => stg_in_sop(i),
          in_eop      => stg_in_eop(i),
          in_valid    => stg_in_valid(i),
          in_fftpts   => in_fftpts,
          in_pwr_2    => in_pwr_2,
          in_sel      => stg_input_sel(i),
          in_real     => stg_in_real(i),
          in_imag     => stg_in_imag(i),
          realtwid    => stg_realtwid(i),
          imagtwid    => stg_imagtwid(i),
          twid_rd_en  => stg_twid_rd_en(i),
          twidaddr    => stg_twidaddr(i),
          in_control  => stg_in_control(i),
          out_real    => stg_out_real(i),
          out_imag    => stg_out_imag(i),
          out_valid   => stg_out_valid(i),
          out_inverse => stg_out_inverse(i),
          out_sop     => stg_out_sop(i),
          out_eop     => stg_out_eop(i),
          processing  => stg_processing(i),
          out_control => stg_out_control(i)
          );

      ---------------------------------------------------------------------------
      -- twiddle generator and stage connection 
      gen_twiddles : if i > 0 generate
      begin

        stg_twidrom2 : auk_dspip_r22sdf_twrom
          generic map (
            DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
            MAX_FFTPTS_g     => MAX_FFTPTS_g,
            STAGE_g          => i,
            TWIDWIDTH_g      => TWIDWIDTH_g,
            REPRESENTATION_g => REPRESENTATION_g,
            INPUT_FORMAT_g   => INPUT_FORMAT_g,
            OPTIMIZE_MEM_g   => OPTIMIZE_MEM_g,
            REALFILE_g       => TWIDROM_BASE_g & "opt_twr" & integer'image(i) & ".hex",
            IMAGFILE_g       => TWIDROM_BASE_g & "opt_twi" & integer'image(i) & ".hex"
            )
          port map (
            clk      => clk,
            reset    => reset,
            enable   => control_enable,
            pwr_2    => in_pwr_2,
            rd_en    => stg_twid_rd_en(i),
            addr     => stg_twidaddr(i)(log2_ceil(MAX_FFTPTS_g)- (i)*2 + 1 downto 0),
            realtwid => stg_realtwid(i),
            imagtwid => stg_imagtwid(i));

      end generate gen_twiddles;

      gen_stg_connect : if i < NUM_STAGES_g - 1 generate
        -- mux connection between stages. the number of points
        -- will determine whether the input to the stage is either the
        -- incoming data or the data from the previous stage. Registered
        -- for timing purposes.
        stg_connect : auk_dspip_r22sdf_stg_pipe
          generic map (
            DATAWIDTH_g    => DATAWIDTH_g + MAX_GROW_g,
            INPUT_FORMAT_g => INPUT_FORMAT_g,
            MAX_FFTPTS_g   => MAX_FFTPTS_g)
          port map (
            clk               => clk,
            reset             => reset,
            enable            => control_enable,
            stg_input_sel     => stg_input_sel(i+1),
            stg_control_first => stg_control_first,
            stg_valid_first   => in_valid,
            stg_inverse_first => in_inverse,
            stg_sop_first     => in_sop,
            stg_eop_first     => in_eop,
            stg_real_first    => stg_in_real_first,
            stg_imag_first    => stg_in_imag_first,
            stg_control_prev  => stg_out_control(i),
            stg_inverse_prev  => stg_out_inverse(i),
            stg_valid_prev    => stg_out_valid(i),
            stg_sop_prev      => stg_out_sop(i),
            stg_eop_prev      => stg_out_eop(i),
            stg_real_prev     => stg_out_real(i),
            stg_imag_prev     => stg_out_imag(i),
            stg_real_next     => stg_in_real(i+1),
            stg_imag_next     => stg_in_imag(i+1),
            stg_control_next  => stg_in_control(i+1),
            stg_inverse_next  => stg_in_inverse(i+1),
            stg_sop_next      => stg_in_sop(i+1),
            stg_eop_next      => stg_in_eop(i+1),
            stg_valid_next    => stg_in_valid(i+1)
            );
      end generate gen_stg_connect;
    end generate gen_stages;
  end generate gen_natural_order_core;



  -----------------------------------------------------------------------------
  -- BIT REVERSED INPUTS
  -----------------------------------------------------------------------------

  gen_bit_reverse_core : if INPUT_FORMAT_g = "BIT_REVERSED" generate
    signal stg_out_real_last    : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
    signal stg_out_imag_last    : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
    signal stg_out_sop_last     : std_logic;
    signal stg_out_eop_last     : std_logic;
    signal stg_out_inverse_last : std_logic;
    signal stg_out_valid_last   : std_logic;

    signal valid_stages     : std_logic_vector(NUM_STAGES_g-1 downto 0);
    signal valid_stages_tmp : std_logic_vector(NUM_STAGES_g downto 0);

  begin

    -- data is always fed into the first stage when input is bit reversed.
    stg_in_real(0)    <= stg_in_real_first;
    stg_in_imag(0)    <= stg_in_imag_first;
    stg_in_valid(0)   <= in_valid;
    stg_in_sop(0)     <= in_sop;
    stg_in_eop(0)     <= in_eop;
    stg_in_inverse(0) <= in_inverse;
    stg_in_control(0) <= stg_control_first;

    -- output mux
    out_valid   <= stg_out_valid_last and control_enable;
    out_sop     <= stg_out_sop_last and control_enable;
    out_eop     <= stg_out_eop_last and control_enable;
    out_inverse <= stg_out_inverse_last and control_enable;

    -- swap outputs on inverse
    out_real <= stg_out_real_last when out_inverse = '0' else
                stg_out_imag_last;
    out_imag <= stg_out_imag_last when out_inverse = '0' else
                stg_out_real_last;
    
    valid_stages_tmp <= std_logic_vector(unsigned(('1' & to_unsigned(0, NUM_STAGES_g))) - unsigned('0' & stg_input_sel));
    valid_stages     <= valid_stages_tmp(NUM_STAGES_g-1 downto 0);

    -- generate gen_stages
    gen_stages : for i in 0 to NUM_STAGES_g - 1 generate

    begin
      r22_stage : auk_dspip_r22sdf_stage
        generic map (
          DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
          STAGE_g          => NUM_STAGES_g - i,
          NUM_STAGES_g     => NUM_STAGES_g,
          DATAWIDTH_g      => stage_datawidth_array(i),
          TWIDWIDTH_g      => TWIDWIDTH_g,
          INPUT_FORMAT_g   => INPUT_FORMAT_g,
          MAX_FFTPTS_g     => MAX_FFTPTS_g,
          MAX_DATAWIDTH_g  => DATAWIDTH_g + MAX_GROW_g,
          PIPELINE_g       => PIPELINE_g,
          OPTIMIZE_MEM_g   => 1,
          DEBUG_g          => DEBUG_g,
          DSP_ROUNDING_g   => DSP_ROUNDING_g,
          CMA_GROW_g       => cma_grow_array(i),
          REPRESENTATION_g => REPRESENTATION_g,
          DSP_ARCH_g       => DSP_ARCH_g
          )                                      
        port map (
          clk         => clk,
          reset       => reset,
          enable      => control_enable,
          in_inverse  => stg_in_inverse(i),
          in_sop      => stg_in_sop(i),
          in_eop      => stg_in_eop(i),
          in_valid    => stg_in_valid(i),
          in_fftpts   => in_fftpts,
          in_pwr_2    => in_pwr_2,
          in_sel      => stg_input_sel(i),
          in_real     => stg_in_real(i),
          in_imag     => stg_in_imag(i),
          realtwid    => stg_realtwid(i),
          imagtwid    => stg_imagtwid(i),
          twid_rd_en  => stg_twid_rd_en(i),
          twidaddr    => stg_twidaddr(i),
          in_control  => stg_in_control(i),
          out_real    => stg_out_real(i),
          out_imag    => stg_out_imag(i),
          out_valid   => stg_out_valid(i),
          out_inverse => stg_out_inverse(i),
          out_sop     => stg_out_sop(i),
          out_eop     => stg_out_eop(i),
          processing  => stg_processing(i),
          out_control => stg_out_control(i)
          );

      ---------------------------------------------------------------------------
      -- twiddle generator and stage connection 
      gen_twiddles : if i > 0 generate
        signal mem_enable   : std_logic;
        signal mem_enable_d : std_logic;
        signal mem_enable_dd : std_logic;
        
      begin
        mem_enable_delay : process (clk)
        begin  -- process out_mux
          if rising_edge(clk) then
            if reset = '1' then
              mem_enable_d  <= '0';
              mem_enable_dd <= '0';
            elsif control_enable = '1' then
              mem_enable_d  <= stg_twid_rd_en(i);
              mem_enable_dd <= mem_enable_d;
            end if;
          end if;
        end process mem_enable_delay;


        mem_enable <= control_enable and (mem_enable_dd or mem_enable_d) when MAX_PWR_2_c = 0 else
                      control_enable and (stg_twid_rd_en(i) or mem_enable_dd or mem_enable_d);
        
        stg_twidrom : auk_dspip_r22sdf_twrom
          generic map (
            DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
            MAX_FFTPTS_g     => MAX_FFTPTS_g,
            STAGE_g          => NUM_STAGES_g - (i),
            TWIDWIDTH_g      => TWIDWIDTH_g,
            OPTIMIZE_MEM_g   => 1,
            REPRESENTATION_g => REPRESENTATION_g,
            INPUT_FORMAT_g   => INPUT_FORMAT_g,
            REALFILE_g       => TWIDROM_BASE_g & "opt_twr" & integer'image(NUM_STAGES_g - (i)) & ".hex",
            IMAGFILE_g       => TWIDROM_BASE_g & "opt_twi" & integer'image(NUM_STAGES_g - (i)) & ".hex"
            )
          port map (
            clk      => clk,
            reset    => reset,
            pwr_2    => in_pwr_2,
            enable   => mem_enable,
            addr     => stg_twidaddr(i)(log2_ceil(MAX_FFTPTS_g)- (NUM_STAGES_g - (i))*2 + 1 downto 0),
            realtwid => stg_realtwid(i),
            imagtwid => stg_imagtwid(i));

      end generate gen_twiddles;

      gen_stg_connect : if i < NUM_STAGES_g - 1 generate
        -- mux connection between stages. the number of points
        -- will determine whether the input to the stage is either the
        -- incoming data or the data from the previous stage. Registered
        -- for timing purposes.
        stg_connect : auk_dspip_r22sdf_stg_out_pipe
          generic map (
            DATAWIDTH_g  => DATAWIDTH_g + MAX_GROW_g,
            MAX_FFTPTS_g => MAX_FFTPTS_g)
          port map (
            clk              => clk,
            reset            => reset,
            enable           => control_enable,
            stg_input_sel    => valid_stages(NUM_STAGES_g - (i+2)),
            stg_control_prev => stg_out_control(i),
            stg_valid_prev   => stg_out_valid(i),
            stg_inverse_prev => stg_out_inverse(i),
            stg_sop_prev     => stg_out_sop(i),
            stg_eop_prev     => stg_out_eop(i),
            stg_real_prev    => stg_out_real(i),
            stg_imag_prev    => stg_out_imag(i),
            stg_real_next    => stg_in_real(i+1),
            stg_imag_next    => stg_in_imag(i+1),
            stg_control_next => stg_in_control(i+1),
            stg_inverse_next => stg_in_inverse(i+1),
            stg_sop_next     => stg_in_sop(i+1),
            stg_eop_next     => stg_in_eop(i+1),
            stg_valid_next   => stg_in_valid(i+1)
            );

      end generate gen_stg_connect;


    end generate gen_stages;


    out_mux : process (clk)
    begin  -- process out_mux
      if rising_edge(clk) then
        if reset = '1' then
          stg_out_inverse_last <= '0';
          stg_out_valid_last   <= '0';
          stg_out_sop_last     <= '0';
          stg_out_eop_last     <= '0';
          stg_out_real_last    <= (others => '0');
          stg_out_imag_last    <= (others => '0');
        elsif control_enable = '1' then
          for i in 0 to NUM_STAGES_g - 1 loop
            if stg_input_sel(i) = '1' then
              stg_out_inverse_last <= stg_out_inverse(NUM_STAGES_g- (i+1));
              stg_out_valid_last   <= stg_out_valid(NUM_STAGES_g- (i+1));
              stg_out_sop_last     <= stg_out_sop(NUM_STAGES_g- (i+1));
              stg_out_eop_last     <= stg_out_eop(NUM_STAGES_g- (i+1));
              stg_out_real_last    <= stg_out_real(NUM_STAGES_g- (i+1));
              stg_out_imag_last    <= stg_out_imag(NUM_STAGES_g- (i+1));
            end if;
          end loop;  -- i
          
        end if;
      end if;
    end process out_mux;


    

  end generate gen_bit_reverse_core;



end architecture rtl;

