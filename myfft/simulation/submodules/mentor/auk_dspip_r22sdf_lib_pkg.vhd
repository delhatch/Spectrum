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


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.auk_dspip_math_pkg.all;
use work.hyper_opt_pkg.all;

package auk_dspip_r22sdf_lib_pkg is
--Component names: 
--auk_dspip_bit_reverse_addr_control
--auk_dspip_bit_reverse_core
--auk_dspip_bit_reverse_reverse_carry_adder
--auk_dspip_bit_reverse_top
--auk_dspip_r22sdf_addsub
--auk_dspip_r22sdf_bf_control
--auk_dspip_r22sdf_bfi
--auk_dspip_r22sdf_bfii
--auk_dspip_r22sdf_cma
--auk_dspip_r22sdf_cma_fp
--auk_dspip_r22sdf_core
--auk_dspip_r22sdf_counter
--auk_dspip_r22sdf_delay
--auk_dspip_r22sdf_enable_control
--auk_dspip_r22sdf_sink_control
--auk_dspip_r22sdf_source_control
--auk_dspip_r22sdf_stage
--auk_dspip_r22sdf_stg_pipe
--auk_dspip_r22sdf_top
--auk_dspip_r22sdf_twrom
--altera_fft_single_port_rom
--altera_fft_dual_port_rom
--altera_fft_dual_port_ram
--hyper_pipeline_interface
--counter_module

  constant HYPER_OPTIMIZATION : natural := HYPER_OPTIMIZATION; -- pass the HYPER_OPTIMIZATION parameter from the hyper_opt_pkg to this package

  component auk_dspip_bit_reverse_addr_control is
    generic (
      MAX_BLKSIZE_g : natural := 1024
      );
    port (
      clk     : in  std_logic;
      reset   : in  std_logic;
      enable  : in  std_logic;
      blksize : in  std_logic_vector(log2_ceil(MAX_BLKSIZE_g) downto 0);
      index   : in  std_logic;
      valid   : in  std_logic;
      addr    : out std_logic_vector(log2_ceil(MAX_BLKSIZE_g) - 1 downto 0)

      );
  end component auk_dspip_bit_reverse_addr_control;

  component auk_dspip_bit_reverse_core is
    generic (
      DEVICE_FAMILY_g : string;
      MAX_BLKSIZE_g : natural := 1024;
      DATAWIDTH_g   : natural := 28);
    port (
      clk        : in  std_logic;
      reset      : in  std_logic;
      enable     : in  std_logic;
      blksize    : in  std_logic_vector(log2_ceil(MAX_BLKSIZE_g) downto 0);
      in_valid   : in  std_logic;
      in_real    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      in_imag    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      processing : out std_logic;
      out_valid  : out std_logic;
      out_stall  : in  std_logic;
      out_real   : out std_logic_vector(DATAWIDTH_g - 1 downto 0);
      out_imag   : out std_logic_vector(DATAWIDTH_g - 1 downto 0)
      );
  end component auk_dspip_bit_reverse_core;

  component auk_dspip_bit_reverse_reverse_carry_adder is
    generic (
      MAX_SIZE_g : natural := 9);
    port (
      clk     : in  std_logic;
      reset   : in  std_logic;
      add_a   : in  std_logic_vector(MAX_SIZE_g - 1 downto 0);
      add_b   : in  std_logic_vector(MAX_SIZE_g - 1 downto 0);
      sum_out : out std_logic_vector(MAX_SIZE_g - 1 downto 0));
  end component auk_dspip_bit_reverse_reverse_carry_adder;

  component auk_dspip_r22sdf_addsub is

    generic (
      DATAWIDTH_g : natural := 18;
      REPRESENTATION_g : string := "FIXEDPT";
      PIPELINE_g  : natural := 0;
      GROW_g      : natural := 1
      );

    port (
      clk    : in  std_logic;
      reset  : in  std_logic;
      clken  : in  std_logic;
      add    : in  std_logic;           -- 1 for add, 0 for subtract
      dataa  : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      datab  : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      result : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0));

  end component auk_dspip_r22sdf_addsub;

  component auk_dspip_r22sdf_bf_control is
    generic(
      MAX_FFTPTS_g   : natural := 1024;
      INPUT_FORMAT_g : string  := "NATURAL_ORDER";
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
      in_inverse   : in  std_logic;
      in_sop       : in  std_logic;
      in_eop       : in  std_logic;
      in_control   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
      curr_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      out_control  : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
      out_inverse  : out std_logic;
      out_sop      : out std_logic;
      out_eop      : out std_logic;
      out_valid    : out std_logic
      );

  end component auk_dspip_r22sdf_bf_control;

  component auk_dspip_r22sdf_bfi is

    generic (
      STAGE_g        : natural := 1;
      DATAWIDTH_g    : natural := 18 + 14;
      TWIDWIDTH_g    : natural := 18;
      DELAY_g        : natural := 1;
      MAX_FFTPTS_g   : natural := 1024;
      PIPELINE_g     : natural := 0;
      NUM_STAGES_g   : natural := 5;
      INPUT_FORMAT_g : string  := "NATURAL_ORDER";
      REPRESENTATION_g : string := "FIXEDPT";
      GROW_g         : natural := 1     -- 1 grow datawidth
                                        -- 
      );

    port (
      clk          : in  std_logic;
      reset        : in  std_logic;
      -- start/stop processing
      enable       : in  std_logic;
      in_fftpts    : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
      in_radix_2   : in  std_logic;
      in_sel       : in  std_logic;
      -- control in and out.
      in_control   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      out_control  : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      -- From the previous stage
      in_inverse   : in  std_logic;
      in_sop       : in  std_logic;
      in_eop       : in  std_logic;
      in_valid     : in  std_logic;
      in_real      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      in_imag      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      -- From the delay block
      del_in_real  : in  std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      del_in_imag  : in  std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      -- To the next stage
      out_real     : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_imag     : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      -- To the delay block
      del_out_real : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      del_out_imag : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_inverse  : out std_logic;
      out_sop      : out std_logic;
      out_eop      : out std_logic;
      out_valid    : out std_logic

      );

  end component auk_dspip_r22sdf_bfi;

  component auk_dspip_r22sdf_bfii is

    generic (
      STAGE_g        : natural := 1;
      DATAWIDTH_g    : natural := 18+14;
      TWIDWIDTH_g    : natural := 18;
      DELAY_g        : natural := 1;
      PIPELINE_g     : natural := 0;
      MAX_FFTPTS_g   : natural := 1024;
      NUM_STAGES_g   : natural := 5;
      INPUT_FORMAT_g : string  := "NATURAL_ORDER";
      REPRESENTATION_g : string := "FIXEDPT";
      GROW_g         : natural := 1     -- 1 grow datawidth 
      );

    port (
      clk          : in  std_logic;
      reset        : in  std_logic;
      enable       : in  std_logic;
      in_radix_2   : in  std_logic;
      in_sel       : in  std_logic;
      in_fftpts    : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
      -- control signals
      in_control   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      out_control  : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      -- From the previous stage
      in_inverse   : in  std_logic;
      in_sop       : in  std_logic;
      in_eop       : in  std_logic;
      in_valid     : in  std_logic;
      in_real      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      in_imag      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      -- From the delay block
      del_in_real  : in  std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      del_in_imag  : in  std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      -- To the next stage
      out_real     : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_imag     : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      -- To the delay block
      del_out_real : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      del_out_imag : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_inverse  : out std_logic;
      out_sop      : out std_logic;
      out_eop      : out std_logic;
      out_valid    : out std_logic

      );

  end component auk_dspip_r22sdf_bfii;

  component auk_dspip_r22sdf_cma_adder_fp is
    generic (
      INPUT_MUX_CONTROL_g : natural);
    port (
      sysclk   : in std_logic;
      reset    : in std_logic;
      enable   : in std_logic;
      input_mux_ctrl : in std_logic:= '0';
      realin   : in std_logic_vector (32 downto 1);
      imagin   : in std_logic_vector (32 downto 1);
      realin_d : in std_logic_vector (32 downto 1);
      imagin_d : in std_logic_vector (32 downto 1);
      realtwid : in std_logic_vector (32 downto 1);
      imagtwid : in std_logic_vector (32 downto 1);

      realout      : out std_logic_vector (32 downto 1);
      imagout      : out std_logic_vector (32 downto 1);
      realout_d : out std_logic_vector (32 downto 1);
      imagout_d : out std_logic_vector (32 downto 1);
      cma_real_out : out std_logic_vector (32 downto 1);
      cma_imag_out : out std_logic_vector (32 downto 1));
  end component auk_dspip_r22sdf_cma_adder_fp;

  component auk_dspip_r22sdf_adder_fp is
    port (
      sysclk   : in std_logic;
      reset    : in std_logic;
      enable   : in std_logic;
      addsub_in : in std_logic := '0';
      realin   : in std_logic_vector (32 downto 1);
      imagin   : in std_logic_vector (32 downto 1);
      addsub_in_d : in std_logic := '1';
      realin_d : in std_logic_vector (32 downto 1);
      imagin_d : in std_logic_vector (32 downto 1);

      realout      : out std_logic_vector (32 downto 1);
      imagout      : out std_logic_vector (32 downto 1);
      realout_d : out std_logic_vector (32 downto 1);
      imagout_d : out std_logic_vector (32 downto 1));
  end component auk_dspip_r22sdf_adder_fp;
  
  component auk_dspip_r22sdf_cma_bfi_fp is
    generic (
      STAGE_g          : natural;
      DATAWIDTH_g      : natural;
      TWIDWIDTH_g      : natural;
      DELAY_g          : natural;
      INPUT_FORMAT_g   : string;
      REPRESENTATION_g : string;
      CMA_PIPELINE_g   : natural := 0;
      MAX_FFTPTS_g     : natural;
      PIPELINE_g       : natural;
      NUM_STAGES_g     : natural;
      GROW_g           : natural);
    port (
      clk          : in  std_logic;
      reset        : in  std_logic;
      -- start/stop processing
      enable       : in  std_logic;
      in_fftpts    : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
      in_radix_2   : in  std_logic;
      in_sel       : in  std_logic;
      -- control in and out.
      in_control   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      out_control  : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      -- From the previous stage
      in_inverse   : in  std_logic;
      in_sop       : in  std_logic;
      in_eop       : in  std_logic;
      in_valid     : in  std_logic;
      in_real      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      in_imag      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      realtwid      : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
      imagtwid      : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
      twidaddr     : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      -- From the delay block
      del_in_real  : in  std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      del_in_imag  : in  std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      -- To the next stage
      out_real     : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_imag     : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      -- To the delay block
      del_out_real : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      del_out_imag : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_inverse  : out std_logic;
      out_sop      : out std_logic;
      out_eop      : out std_logic;
      out_valid    : out std_logic);
  end component auk_dspip_r22sdf_cma_bfi_fp;

  
  component auk_dspip_r22sdf_cma is
    generic (
      DEVICE_FAMILY_g  : string; 
      DATAWIDTH_g      : natural := 18+14;
      TWIDWIDTH_g      : natural := 18;
      INPUT_FORMAT_g   : string  := "NATURAL_ORDER";
      PIPELINE_g       : natural := 4;  -- this should match the number of
                                        -- cyles latency through the block
      OPTIMIZE_SPEED_g : natural := 0;  -- adds extra pipeline stage
                                        -- through adder.
      OPTIMIZE_MEM_g   : natural := 1;
      MAX_FFTPTS_g     : natural := 1024;
      GROW_g           : natural := 1;
      DSP_ROUNDING_g   : natural := 1;
      DSP_ARCH_g       : natural := 0
      );
    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      enable      : in  std_logic;
      in_inverse  : in  std_logic;
      in_sop      : in  std_logic;
      in_eop      : in  std_logic;
      in_valid    : in  std_logic;
      in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
      in_radix_2  : in  std_logic;
      in_control  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g)-1 downto 0);
      in_real     : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      in_imag     : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      realtwid    : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
      imagtwid    : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
      twidaddr    : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      out_real    : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_imag    : out std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
      out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
      out_inverse : out std_logic;
      out_sop     : out std_logic;
      out_eop     : out std_logic;
      out_valid   : out std_logic
      );
  end component auk_dspip_r22sdf_cma;

  component auk_dspip_r22sdf_cma_fp is
  generic (
    DEVICE_FAMILY_g  : string  := "Arria 10";
    INPUT_FORMAT_g   : string  := "NATURAL_ORDER";
    PIPELINE_g       : natural := 4;    -- this should match the number of
                                        -- cyles latency through the mult block
                                        -- adds extra pipeline stage
                                        -- through adder block.
    MAX_FFTPTS_g     : natural := 1024
    );
  port (
    clk         : in  std_logic;
    reset       : in  std_logic;
    enable      : in  std_logic;
    in_sop      : in  std_logic;
    in_eop      : in  std_logic;
    in_inverse  : in  std_logic;
    in_valid    : in  std_logic;
    in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_radix_2  : in  std_logic;
    in_control  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g)-1 downto 0);
    in_real     : in  std_logic_vector(31 downto 0);
    in_imag     : in  std_logic_vector(31 downto 0);
    realtwid    : in  std_logic_vector(31 downto 0);
    imagtwid    : in  std_logic_vector(31 downto 0);
    twidaddr    : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    out_real    : out std_logic_vector(31 downto 0);
    out_imag    : out std_logic_vector(31 downto 0);
    out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
    out_inverse : out std_logic;
    out_sop     : out std_logic;
    out_eop     : out std_logic;
    out_valid   : out std_logic
    );
  end component auk_dspip_r22sdf_cma_fp;


  component auk_dspip_r22sdf_core is

    generic (
      DEVICE_FAMILY_g: string;
      DATAWIDTH_g    : natural := 18;
      TWIDWIDTH_g    : natural := 18;
      MAX_FFTPTS_g   : natural := 1024;
      NUM_STAGES_g   : natural := 5;
      MAX_GROW_g     : natural := 14;
      PIPELINE_g     : natural := 0;
      DSP_ROUNDING_g : natural := 1;
      OPTIMIZE_MEM_g : natural := 1;
      DEBUG_g        : natural := 0;
      PRUNE_g         : string   :="";
      INPUT_FORMAT_g : string  := "NATURAL_ORDER";
      REPRESENTATION_g : string := "FIXEDPT";
      DSP_ARCH_g     : natural := 0;
      TWIDROM_BASE_g : string  := "../tb/"
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

  end component auk_dspip_r22sdf_core;



  component auk_dspip_r22sdf_counter is

    generic (
      MAX_FFTPTS_g : natural := 1024;
      INPUT_FORMAT_g   : string  := "NATURAL_ORDER"
      );

    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      -- start/stop processing
      enable      : in  std_logic;
      in_valid    : in  std_logic;
      --number of points in the fft
      in_sop      : in  std_logic;
      in_eop      : in  std_logic;
      in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
      in_radix_2  : in  std_logic;
      in_control  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      -- array of control signals to the stages.
      out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0)
      );

  end component auk_dspip_r22sdf_counter;

  component auk_dspip_r22sdf_delay is

    generic (
      DEVICE_FAMILY_g  : string;
      DATAWIDTH_g  : natural := 18;
      MAX_FFTPTS_g : natural := 1024;
      PIPELINE_g   : natural := 1;
      DELAY_g      : integer := 256
      );

    port (
      clk     : in  std_logic;
      reset   : in  std_logic;
      enable  : in  std_logic;
      radix_2 : in  std_logic;
      datain  : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      dataout : out std_logic_vector(DATAWIDTH_g - 1 downto 0)
      );

  end component auk_dspip_r22sdf_delay;

  component auk_dspip_r22sdf_enable_control is

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

  end component auk_dspip_r22sdf_enable_control;


  component auk_dspip_r22sdf_stage is

    generic (
      DEVICE_FAMILY_g : string;
      STAGE_g         : natural := 1;   -- stage number
      NUM_STAGES_g    : natural := 5;   -- Maximum number of stages
      MAX_FFTPTS_g    : natural := 1024;
      MAX_DATAWIDTH_g : natural := 18+14;
      INPUT_FORMAT_g  : string  := "NATURAL_ORDER";
      REPRESENTATION_g : string := "FIXEDPT";
      OPTIMIZE_MEM_g  : natural := 1;
      DATAWIDTH_g     : natural := 18;  -- this stage true input datawidth
      TWIDWIDTH_g     : natural := 18;
      PIPELINE_g      : natural := 0;
      DSP_ROUNDING_g  : natural := 1;
      DSP_ARCH_g      : natural := 0;
      CMA_GROW_g      : natural := 3;
      DEBUG_g         : natural := 0
      );

    port (
      clk         : in  std_logic;
      reset       : in  std_logic;
      enable      : in  std_logic;      -- start/stop processing
      in_valid    : in  std_logic;
      in_pwr_2    : in  std_logic;      -- 1 radix 2, 0 radix 2^2
      in_sel      : in  std_logic;
      in_inverse  : in  std_logic;
      in_sop      : in  std_logic;
      in_eop      : in  std_logic;
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

  end component auk_dspip_r22sdf_stage;

  component auk_dspip_r22sdf_stg_pipe is

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
      stg_inverse_first : in  std_logic;
      stg_sop_first     : in  std_logic;
      stg_eop_first     : in  std_logic;
      stg_valid_first   : in  std_logic;
      stg_real_first    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      stg_imag_first    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      -- prev
      stg_valid_prev    : in  std_logic;
      stg_inverse_prev  : in  std_logic;
      stg_sop_prev      : in  std_logic;
      stg_eop_prev      : in  std_logic;
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

  end component auk_dspip_r22sdf_stg_pipe;

  component auk_dspip_r22sdf_top is
    generic (
      DEVICE_FAMILY_g : string;
      MAX_FFTPTS_g    : natural := 256;
      NUM_STAGES_g    : natural := 5;
      DATAWIDTH_g     : natural := 16;
      TWIDWIDTH_g     : natural := 16;
      MAX_GROW_g      : natural := 12;
      DSP_ROUNDING_g  : natural := 1;
      OPTIMIZE_MEM_g  : natural := 1;
      -- "BIT_REVERSED", "-N/2_to_N/2", "NATURAL_ORDER"
      INPUT_FORMAT_g  : string  := "NATURAL_ORDER";
      OUTPUT_FORMAT_g : string  := "NATURAL_ORDER";
      REPRESENTATION_g : string := "FIXEDPT";
      DSP_ARCH_g      : natural := 0;
      PIPELINE_g      : natural := 1;
      DEBUG_g         : natural := 0;
      PRUNE_g         : string   :="";
      TWIDROM_BASE_g  : string  := "../../../../../test/data/in/"
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
  end component auk_dspip_r22sdf_top;
  component auk_dspip_r22sdf_stg_out_pipe is
    generic (
      DATAWIDTH_g  : natural;
      MAX_FFTPTS_g : natural);
    port (
      clk              : in  std_logic;
      reset            : in  std_logic;
      enable           : in  std_logic;
      stg_input_sel    : in  std_logic;
      -- prev
      stg_valid_prev   : in  std_logic;
      stg_inverse_prev : in  std_logic;
      stg_sop_prev     : in  std_logic;
      stg_eop_prev     : in  std_logic;
      stg_control_prev : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      stg_real_prev    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      stg_imag_prev    : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
      -- next
      stg_real_next    : out std_logic_vector(DATAWIDTH_g - 1 downto 0);
      stg_imag_next    : out std_logic_vector(DATAWIDTH_g - 1 downto 0);
      stg_control_next : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
      stg_inverse_next : out std_logic;
      stg_eop_next     : out std_logic;
      stg_sop_next     : out std_logic;
      stg_valid_next   : out std_logic);
  end component auk_dspip_r22sdf_stg_out_pipe;

  component auk_dspip_r22sdf_twrom is
    generic (
      DEVICE_FAMILY_g   : string;
      MAX_FFTPTS_g   : natural  := 2048;
      STAGE_g        : natural  := 1;
      TWIDWIDTH_g    : positive := 18;
      REPRESENTATION_g : string := "FIXEDPT";
      INPUT_FORMAT_g : string   := "NATURAL";
      OPTIMIZE_MEM_g : natural  := 1;
      REALFILE_g     : string   := "twr.hex";
      IMAGFILE_g     : string   := "twi.hex"
      );
    port (
      clk      : in  std_logic;
      reset    : in  std_logic;
      enable   : in  std_logic;
      rd_en    : in  std_logic := '1';
      pwr_2    : in  std_logic;
      addr     : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 2*STAGE_g + 1 downto 0);
      realtwid : out std_logic_vector(TWIDWIDTH_g - 1 downto 0);
      imagtwid : out std_logic_vector(TWIDWIDTH_g - 1 downto 0)
      );
  end component auk_dspip_r22sdf_twrom; 

  component apn_fft_mult_cpx
    generic(
      mpr : integer :=27;
      twr : integer :=25
    );
  port(
      clk       : in std_logic;
      reset     : in std_logic;
      global_clock_enable : in std_logic;
      a       : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
      b       : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
      c       : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
      d       : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
      rout    : out std_logic_vector (twr+mpr downto 0);
      iout      : out std_logic_vector (twr+mpr downto 0) 
    );
  end component;

  component apn_fft_mult_cpx_1825
    generic(
      mpr : integer :=25;
      twr : integer :=18
    );
    port(
      clk       : in std_logic;
      reset     : in std_logic;
      global_clock_enable : in std_logic;
      a_r   : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
      a_i   : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
      b_r   : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
      b_i     : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
      p_r   : out std_logic_vector (twr+mpr downto 0);
      p_i       : out std_logic_vector (twr+mpr downto 0) 
    );
  end component;

  component apn_fft_mult_can
    generic(
      mpr : integer :=27;
      twr : integer :=25
    );
    port(
      clk       : in std_logic;
      reset     : in std_logic;
      global_clock_enable : in std_logic;
      a         : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
      b       : in std_logic_vector (mpr-1 downto 0) :=  (others => '0');
      c       : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
      d       : in std_logic_vector (twr-1 downto 0) :=  (others => '0');
      rout    : out std_logic_vector (twr+mpr downto 0);
      iout      : out std_logic_vector (twr+mpr downto 0) 
    );
  end component;

  component altera_fft_mult_add
    generic (
      selected_device_family  : STRING;
      multiplier1_direction   : STRING;
      number_of_multipliers   : NATURAL;
      width_a                 : NATURAL;
      width_b                 : NATURAL;
      width_result            : NATURAL
   );
   port (
      dataa  : IN  STD_LOGIC_VECTOR (number_of_multipliers * width_a - 1 DOWNTO 0);
      datab  : IN  STD_LOGIC_VECTOR (number_of_multipliers * width_b - 1 DOWNTO 0);
      clock0 : IN  STD_LOGIC;
      aclr0  : IN  STD_LOGIC;
      ena0   : IN  STD_LOGIC;
      result : OUT STD_LOGIC_VECTOR (width_result-1 DOWNTO 0)
   );
  end component;  
  
  component altera_fft_single_port_rom is
   generic (
      selected_device_family : string;
      ram_block_type         : string := "AUTO";
      init_file              : string;
      numwords               : natural;
      addr_width             : natural;
      data_width             : natural
           );
   port (
        clocken0  : in std_logic;
        clock0    : in std_logic;
        address_a : in std_logic_vector(addr_width-1 downto 0);
        q_a       : out std_logic_vector(data_width-1 downto 0)
     );
  end component;

  component altera_fft_dual_port_rom
   generic (
      selected_device_family : string;
      ram_block_type         : string := "AUTO";
      init_file              : string;
      numwords               : natural;
      addr_width             : natural;
      data_width             : natural
           );
   port (
        clocken0  : in std_logic;
        aclr0     : in std_logic;
        clock0    : in std_logic;
        address_a : in std_logic_vector(addr_width-1 downto 0);
        address_b : in std_logic_vector(addr_width-1 downto 0);
        q_a       : out std_logic_vector(data_width-1 downto 0);
        q_b       : out std_logic_vector(data_width-1 downto 0) 
     );
  end component;


  component altera_fft_dual_port_ram
   generic (
      selected_device_family : string;
      ram_block_type         : string := "AUTO";
      read_during_write_mode_mixed_ports : string := "DONT_CARE" ;
      numwords               : natural;
      addr_width             : natural;
      data_width             : natural
           );
   port (
        clocken0  : in std_logic;
        aclr0     : in std_logic;
        wren_a    : in std_logic;
        rden_b    : in std_logic := '1';
        clock0    : in std_logic;
        address_a : in std_logic_vector(addr_width-1 downto 0);
        address_b : in std_logic_vector(addr_width-1 downto 0);
        data_a    : in std_logic_vector(data_width-1 downto 0);
        q_b       : out std_logic_vector(data_width-1 downto 0) 
        );
  end component;

  
  -- the following are two modules used for hyper optimization of the core on Stratix 10

  component hyper_pipeline_interface
  generic (PIPELINE_STAGES : integer := 3;
           SIGNAL_WIDTH : integer := 1);
  port (clk              : IN std_logic;
        clken            : IN std_logic;
        reset            : IN std_logic;
        signal_w         : IN std_logic_vector (SIGNAL_WIDTH-1 downto 0);
        signal_pipelined : OUT std_logic_vector (SIGNAL_WIDTH-1 downto 0));
  end component;

  component counter_module
  generic (COUNTER_WIDTH : natural := 10;
           HYPER_OPTIMIZATION : natural := HYPER_OPTIMIZATION;
           COUNTER_STAGE_WIDTH : natural := 4;
           COUNT_STEP : natural := 1);
  port (clk         : IN std_logic;
        clken       : IN std_logic;
        reset       : IN std_logic;
        reset_c     : IN std_logic;
        reset_value : IN std_logic_vector(COUNTER_WIDTH-1 downto 0);
        counter_max : IN std_logic_vector(COUNTER_WIDTH-1 downto 0);
        counter_out : OUT std_logic_vector(COUNTER_WIDTH-1 downto 0));
  end component;


  

end package auk_dspip_r22sdf_lib_pkg;

