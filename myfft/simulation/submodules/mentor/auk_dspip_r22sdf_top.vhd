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
-- $RCSfile: auk_dspip_r22sdf_top.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_top.vhd,v $
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
-- <Brief description of the contents of the file>
-- 
--
-- $Log: auk_dspip_r22sdf_top.vhd,v $
-- Revision 1.20  2007/09/26 10:39:30  kmarks
-- *** empty log message ***
--
-- Revision 1.19  2007/09/26 10:24:45  kmarks
-- *** empty log message ***
--
-- Revision 1.18  2007/09/26 10:23:29  kmarks
-- added block based avalon streaming modules (was FFT avalon streaming)
--
-- Revision 1.17  2007/07/09 15:46:16  kmarks
-- SPR 246131
--
-- Revision 1.16  2007/07/03 19:16:01  kmarks
-- handle the data growth better
--
-- Revision 1.15  2007/06/28 16:44:52  kmarks
-- Changed prune to cma_out_datawidth - I think it is clearer what it means.
--
-- Revision 1.14  2007/06/28 13:48:22  kmarks
-- added pruning infrastructure
--
-- Revision 1.13  2007/05/11 10:10:03  kmarks
-- Added floating point, untested as yet.
--
-- Revision 1.12  2007/03/23 14:41:27  kmarks
-- *** empty log message ***
--
-- Revision 1.11.2.1  2007/02/26 17:22:09  kmarks
-- SPR234935 - Dynamic clk_ena control
--
-- Revision 1.11  2007/02/02 18:09:25  kmarks
-- added -N/2 to N/2 to the input orders
--
-- Revision 1.10  2007/01/31 17:59:10  kmarks
-- integrated bit reversal engine into fFt engine
--
-- Revision 1.9  2007/01/31 12:17:25  kmarks
-- removed some quartus warnings
--
-- Revision 1.8  2007/01/26 17:43:08  kmarks
-- added input and output order parameters. Added fftpts_out port.
--
-- Revision 1.7  2007/01/12 13:33:08  kmarks
-- add OPTIMIZE_MEM_g
--
-- Revision 1.6  2006/12/19 18:07:30  kmarks
-- Updated to make use of the rounding in the stratix III DSP block.
--
-- Revision 1.5  2006/12/05 10:54:44  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.4.2.2  2006/09/28 16:47:30  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.4.2.1  2006/09/22 17:19:49  kmarks
-- SPR 217764
--
-- Revision 1.4  2006/09/06 14:39:41  kmarks
-- added global clock enable and error ports to atlantic interfaces. Added checkbox on GUI for Global clock enable . Some bug fixed for the new architecture.
--
-- Revision 1.3  2006/08/24 12:49:28  kmarks
-- various bug fixes and added bit reversal.
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
use ieee.numeric_std.all;

library work;
use work.auk_dspip_math_pkg.all;
use work.auk_dspip_lib_pkg.all;

use work.auk_dspip_r22sdf_lib_pkg.all;

entity auk_dspip_r22sdf_top is
  generic (
    DEVICE_FAMILY_g  : string;
    MAX_FFTPTS_g     : natural := 256;
    NUM_STAGES_g     : natural := 5;
    DATAWIDTH_g      : natural := 16;
    TWIDWIDTH_g      : natural := 16;
    MAX_GROW_g       : natural := 12;
    DSP_ROUNDING_g   : natural := 1;
    OPTIMIZE_MEM_g   : natural := 1;
    -- "BIT_REVERSED", "-N/2_to_N/2", "NATURAL_ORDER"
    INPUT_FORMAT_g   : string  := "NATURAL_ORDER";
    OUTPUT_FORMAT_g  : string  := "NATURAL_ORDER";
    REPRESENTATION_g : string  := "FIXEDPT";
    DSP_ARCH_g       : natural := 0;
    PIPELINE_g       : natural := 1;
    DEBUG_g          : natural := 0;
    PRUNE_g          : string  := "";
    TWIDROM_BASE_g   : string  := "../../../../../test/data/in/"
    );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    clk_ena      : in  std_logic := '1';
    fftpts_in    : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    inverse      : in  std_logic;
    sink_ready   : out std_logic;
    sink_valid   : in  std_logic;
    sink_real    : in  std_logic_vector(DATAWIDTH_g -1 downto 0);
    sink_imag    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    sink_sop     : in  std_logic;
    sink_eop     : in  std_logic;
    sink_error   : in  std_logic_vector(1 downto 0);
    source_error : out std_logic_vector(1 downto 0);
    source_ready : in  std_logic;
    source_valid : out std_logic;
    source_real  : out std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
    source_imag  : out std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
    source_sop   : out std_logic;
    source_eop   : out std_logic;
    fftpts_out   : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0)
    );
end entity auk_dspip_r22sdf_top;

architecture str of auk_dspip_r22sdf_top is

  signal source_stall     : std_logic;
  signal source_stall_ena : std_logic;

  -- aligned with last data output (if source_stall occurs need to hold processing
  -- high until output accepted)
  signal processing             : std_logic;
  signal processing_to_end      : std_logic;
  signal sent_eop               : std_logic;
  signal bit_reverse_processing : std_logic;

  signal in_valid : std_logic;
  signal in_sop   : std_logic;
  signal in_eop   : std_logic;
  signal in_real  : std_logic_vector(DATAWIDTH_g -1 downto 0);
  signal in_imag  : std_logic_vector(DATAWIDTH_g - 1 downto 0);



  signal out_valid      : std_logic;
  signal out_real       : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  signal out_imag       : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  -- output from fft engine
  signal fft_out_valid  : std_logic;
  signal fft_out_real   : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  signal fft_out_imag   : std_logic_vector(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  signal curr_pwr_2     : std_logic;
  signal curr_inverse   : std_logic;
  signal curr_fftpts    : std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
  signal curr_input_sel : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal enable         : std_logic;
  signal source_valid_s : std_logic;
  signal source_sop_s   : std_logic;
  signal source_eop_s   : std_logic;
  signal reset          : std_logic;

  signal sink_in_data    : std_logic_vector(2*DATAWIDTH_g -1 downto 0);
  signal sink_out_data   : std_logic_vector(2*DATAWIDTH_g -1 downto 0);
  signal source_in_data  : std_logic_vector(2*(DATAWIDTH_g+ MAX_GROW_g) -1 downto 0);
  signal source_out_data : std_logic_vector(2*(DATAWIDTH_g+ MAX_GROW_g) -1 downto 0);

  -- Hyper pipeline signals
  constant HYPER_PIPELINE_STAGES        : natural := 6;
  constant HYPER_PIPELINE_RESET_STAGES  : natural := 5;
  constant HYPER_PIPELINE_SOURCE_STAGES : natural := 4;
  signal reset_s, reset_pipelined     : std_logic;
  signal reset_n_s                    : std_logic; -- this one is purely used for the not(reset) signal after hyper pipelining
  signal reset_pipe                   : std_logic_vector (HYPER_PIPELINE_RESET_STAGES-1 downto 0);
  signal in_valid_s, in_eop_s, in_sop_s, curr_inverse_s, curr_pwr_2_s : std_logic;
  signal curr_fftpts_s                : std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
  signal sink_out_data_s              : std_logic_vector(2*DATAWIDTH_g -1 downto 0);
  signal curr_input_sel_s             : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal source_in_data_pipelined     : std_logic_vector(2*(DATAWIDTH_g+ MAX_GROW_g)-1 downto 0);
  signal out_valid_pipelined          : std_logic;
  signal source_stall_s               : std_logic;
  
begin  -- architecture str

  reset_s      <= not reset_n;
  enable       <= in_valid;
  source_valid <= source_valid_s;
  source_eop   <= source_eop_s;
  source_sop   <= source_sop_s;
  fftpts_out   <= curr_fftpts;


  -- reset signal pipeline for Stratix 10
  gen_normal_reset : if HYPER_OPTIMIZATION /= 1 generate
  begin
    reset_pipelined <= reset_s;
    reset <= reset_s;
  end generate gen_normal_reset;
  gen_pipeline_reset : if HYPER_OPTIMIZATION = 1 generate
  begin
    reset_s_pipe : process (clk)
    begin
      if rising_edge(clk) then
        reset_pipe(0) <= reset_s;
        for i in 1 to HYPER_PIPELINE_RESET_STAGES-1 loop
          reset_pipe(i) <= reset_pipe(i-1);
        end loop;
      end if;
    end process;
    reset_pipelined <= reset_pipe(HYPER_PIPELINE_RESET_STAGES-1);
    -- reset <= '0' when unsigned(reset_pipe)=0 else '1'; -- if any bit of the reset_pipe is '1' then reset = '1'
    -- reset <= reset_pipe(HYPER_PIPELINE_RESET_STAGES-1) or reset_s;
    reset <= reset_s;
  end generate gen_pipeline_reset;
  reset_n_s <= not reset;




  -- flag if the final eop has been sent. 
  sent_eop_p : process (clk)
  begin  -- process sent_eop_p
    if rising_edge(clk) then
      if reset_pipelined = '1' then
        sent_eop <= '0';
      else
        if source_sop_s = '1'and source_valid_s = '1' and source_ready = '1' then
          sent_eop <= '1';
        end if;
        if source_eop_s = '1'and source_valid_s = '1' and source_ready = '1' then
          sent_eop <= '0';
        end if;
      end if;
    end if;
  end process sent_eop_p;

  --register processing for timing purposes.
  reg_processing_p : process (clk)
  begin  -- process sent_eop_p
    if rising_edge(clk) then
      if reset_pipelined = '1' then
        processing_to_end <= '0';
      else
        processing_to_end <= processing or bit_reverse_processing or sent_eop;
      end if;
    end if;
  end process reg_processing_p;

  sink_in_data <= sink_imag & sink_real;

  sink_ctrl_inst : auk_dspip_avalon_streaming_block_sink
    generic map (
      MAX_BLK_g    => MAX_FFTPTS_g,
      NUM_STAGES_g => NUM_STAGES_g,
      STALL_g      => 1,
      DATAWIDTH_g  => 2*DATAWIDTH_g,
      FFT_ARCH     => "R22",
      HYPER_OPTIMIZATION => HYPER_OPTIMIZATION)
    port map (
      clk            => clk,
      reset          => reset,
      in_blk         => fftpts_in,
      in_sop         => sink_sop,
      in_eop         => sink_eop,
      in_inverse     => inverse,
      sink_valid     => sink_valid,
      sink_ready     => sink_ready,
      source_stall   => source_stall_ena,
      in_data        => sink_in_data,
      in_error       => sink_error ,
      out_error      => source_error,
      processing     => processing_to_end,
      out_valid      => in_valid_s,
      out_sop        => in_sop_s,
      out_eop        => in_eop_s,
      out_data       => sink_out_data_s,
      curr_pwr_2     => curr_pwr_2_s,
      curr_inverse   => curr_inverse_s,
      curr_blk       => curr_fftpts_s,
      curr_input_sel => curr_input_sel_s);

  -- non-pipelined output, for non-S10 devices
  gen_normal_sink_output : if HYPER_OPTIMIZATION /= 1 generate
  begin
    in_valid       <= in_valid_s;
    curr_pwr_2     <= curr_pwr_2_s;
    curr_fftpts    <= curr_fftpts_s;
    curr_inverse   <= curr_inverse_s;
    curr_input_sel <= curr_input_sel_s;
    in_eop         <= in_eop_s;
    in_sop         <= in_sop_s;
    sink_out_data  <= sink_out_data_s;
  end generate gen_normal_sink_output;
  -- pipelined output, for optimization on Stratix 10
  gen_pipeline_S10_sink : if HYPER_OPTIMIZATION = 1 generate
  begin
    in_valid_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => in_valid_s,
              signal_pipelined(0) => in_valid);
    curr_pwr_2_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => curr_pwr_2_s,
              signal_pipelined(0) => curr_pwr_2);
    curr_fftpts_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => log2_ceil(MAX_FFTPTS_g)+1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w         => curr_fftpts_s,
              signal_pipelined => curr_fftpts);
    curr_inverse_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => curr_inverse_s,
              signal_pipelined(0) => curr_inverse);
    curr_input_sel_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => NUM_STAGES_g)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w         => curr_input_sel_s,
              signal_pipelined => curr_input_sel);
    in_eop_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => in_eop_s,
              signal_pipelined(0) => in_eop);
    in_sop_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => in_sop_s,
              signal_pipelined(0) => in_sop);
    sink_out_data_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_STAGES,
                 SIGNAL_WIDTH => 2*DATAWIDTH_g)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w         => sink_out_data_s,
              signal_pipelined => sink_out_data);
  end generate gen_pipeline_S10_sink;

  in_real <= sink_out_data(DATAWIDTH_g - 1 downto 0);
  in_imag <= sink_out_data(2*DATAWIDTH_g - 1 downto DATAWIDTH_g);

  source_stall_ena <= source_stall or(not clk_ena);

  r22sdf_core_inst : auk_dspip_r22sdf_core
    generic map (
      DEVICE_FAMILY_g  => DEVICE_FAMILY_g,
      MAX_FFTPTS_g     => MAX_FFTPTS_g,
      NUM_STAGES_g     => NUM_STAGES_g,
      DATAWIDTH_g      => DATAWIDTH_g,
      TWIDWIDTH_g      => TWIDWIDTH_g,
      MAX_GROW_g       => MAX_GROW_g,
      DEBUG_g          => DEBUG_g,
      DSP_ROUNDING_g   => DSP_ROUNDING_g,
      REPRESENTATION_g => REPRESENTATION_g,
      DSP_ARCH_g       => DSP_ARCH_g,
      OPTIMIZE_MEM_g   => OPTIMIZE_MEM_g,
      PIPELINE_g       => PIPELINE_g,
      PRUNE_g          => PRUNE_g,
      INPUT_FORMAT_g   => INPUT_FORMAT_g,
      TWIDROM_BASE_g   => TWIDROM_BASE_g
      )
    port map (
      clk           => clk,
      reset         => reset_pipelined,
      enable        => enable,
      in_sop        => in_sop,
      in_eop        => in_eop,
      in_fftpts     => curr_fftpts,
      in_pwr_2      => curr_pwr_2,
      in_valid      => in_valid,
      in_inverse    => curr_inverse,
      stg_input_sel => curr_input_sel,
      in_real       => in_real,
      in_imag       => in_imag,
      processing    => processing,
      out_stall     => source_stall_ena,
      out_real      => fft_out_real,
      out_imag      => fft_out_imag,
      out_sop       => open,
      out_eop       => open,
      out_valid     => fft_out_valid);

  generate_bit_reverse_module : if (OUTPUT_FORMAT_g = INPUT_FORMAT_g) or
                                  (OUTPUT_FORMAT_g = "NATURAL_ORDER" and INPUT_FORMAT_g = "-N/2_to_N/2") generate
    signal bit_reverse_enable : std_logic;
  begin

    bit_reverse_enable <= fft_out_valid;

    bit_reverse_inst : auk_dspip_bit_reverse_core
      generic map (
        DEVICE_FAMILY_g => DEVICE_FAMILY_g,
        MAX_BLKSIZE_g => MAX_FFTPTS_g,
        DATAWIDTH_g   => DATAWIDTH_g+MAX_GROW_g)
      port map (
        clk        => clk,
        reset      => reset_pipelined,
        enable     => bit_reverse_enable,
        blksize    => curr_fftpts,
        in_valid   => fft_out_valid,
        in_real    => fft_out_real,
        in_imag    => fft_out_imag,
        processing => bit_reverse_processing,
        out_valid  => out_valid,
        out_stall  => source_stall_ena,
        out_real   => out_real,
        out_imag   => out_imag
        );
  end generate generate_bit_reverse_module;


  generate_no_bit_reverse_module : if (OUTPUT_FORMAT_g /= INPUT_FORMAT_g)
                                     and not (OUTPUT_FORMAT_g = "NATURAL_ORDER" and INPUT_FORMAT_g = "-N/2_to_N/2") generate
    bit_reverse_processing <= '0';
    out_real               <= fft_out_real;
    out_imag               <= fft_out_imag;
    out_valid              <= fft_out_valid;
  end generate generate_no_bit_reverse_module;

  source_in_data <= out_imag & out_real;


  source_control_inst : auk_dspip_avalon_streaming_block_source
    generic map (
      MAX_BLK_g   => MAX_FFTPTS_g,
      DATAWIDTH_g => 2*(DATAWIDTH_g + MAX_GROW_g),
      HYPER_OPTIMIZATION => HYPER_OPTIMIZATION)
    port map (
      clk          => clk,
      reset        => reset,
      in_blk       => curr_fftpts,
      in_valid     => out_valid_pipelined,
      source_stall => source_stall_s,
      in_data      => source_in_data_pipelined,
      source_valid => source_valid_s,
      source_ready => source_ready,
      source_sop   => source_sop_s,
      source_eop   => source_eop_s,
      source_data  => source_out_data
      );     

  gen_normal_source_intput : if HYPER_OPTIMIZATION /= 1 generate
  begin
    out_valid_pipelined       <= out_valid;
    source_in_data_pipelined  <= source_in_data;
    source_stall              <= source_stall_s;
  end generate gen_normal_source_intput;
  -- pipelined output, for optimization on Stratix 10
  gen_pipeline_S10_source : if HYPER_OPTIMIZATION = 1 generate
  begin
    out_valid_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_SOURCE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => out_valid,
              signal_pipelined(0) => out_valid_pipelined);
    source_in_data_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_SOURCE_STAGES,
                 SIGNAL_WIDTH => 2*(DATAWIDTH_g+ MAX_GROW_g))
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w         => source_in_data,
              signal_pipelined => source_in_data_pipelined);
    source_stall_s_pipe : hyper_pipeline_interface
    generic map (PIPELINE_STAGES => HYPER_PIPELINE_SOURCE_STAGES,
                 SIGNAL_WIDTH => 1)
    port map (clk              => clk,
              clken            => '1',
              reset            => '0',
              signal_w(0)         => source_stall_s,
              signal_pipelined(0) => source_stall);
  end generate gen_pipeline_S10_source;

  source_real <= source_out_data(DATAWIDTH_g + MAX_GROW_g - 1 downto 0);
  source_imag <= source_out_data(2*(DATAWIDTH_g + MAX_GROW_g) - 1 downto DATAWIDTH_g + MAX_GROW_g);



  gen_debug : if DEBUG_g = 1 generate
    signal tmp_data_in  : std_logic_vector(DATAWIDTH_g*2-1 downto 0);
    signal tmp_data_out : std_logic_vector((DATAWIDTH_g+MAX_GROW_g)*2-1 downto 0);

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

    --synthesis translate off
    tmp_data_out <= out_real & out_imag;

    out_monitor_inst : auk_dspip_avalon_streaming_monitor
      generic map (
        FILENAME_g         => TWIDROM_BASE_g &"log_avs_out.txt",
        COMPARE_g          => false,
        COMPARE_TO_FILE_g  => "",
        IGNORE_PREFIX_g    => '#',
        SYMBOLS_PER_BEAT_g => 2,
        SYMBOL_DELIMETER_g => "\n",
        PRINT_CLK_REPORT_g => false,
        SYMBOL_DATAWIDTH_g => DATAWIDTH_g + MAX_GROW_g)
      port map (
        clk       => clk,
        reset_n   => reset_n_s,
        -- enables the model
        enable    => '1',
        -- atlantic signals
        avs_valid => out_valid,
        avs_ready => '1',
        avs_sop   => '1',
        avs_eop   => '1',
        -- data contains real and imaginary data, imaginary in LSW, real in MSW
        avs_data  => tmp_data_out);

    tmp_data_in <= in_real & in_imag;

    in_monitor : auk_dspip_avalon_streaming_monitor
      generic map (
        FILENAME_g         => TWIDROM_BASE_g & "_log_avs_in.txt",
        COMPARE_g          => false,
        COMPARE_TO_FILE_g  => "",
        IGNORE_PREFIX_g    => '#',
        SYMBOLS_PER_BEAT_g => 2,
        SYMBOL_DELIMETER_g => "\n",
        PRINT_CLK_REPORT_g => false,
        SYMBOL_DATAWIDTH_g => DATAWIDTH_g)
      port map (
        clk       => clk,
        reset_n   => reset_n_s,
        -- enables the model
        enable    => '1',
        -- atlantic signals
        avs_valid => in_valid,
        avs_ready => '1',
        avs_sop   => '1',
        avs_eop   => '1',
        -- data contains real and imaginary data, imaginary in LSW, real in MSW
        avs_data  => tmp_data_in);

    --synthesis translate on
  end generate gen_debug;



  



end architecture str;
