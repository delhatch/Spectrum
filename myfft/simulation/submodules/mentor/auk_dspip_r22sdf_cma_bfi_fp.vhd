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
-- $RCSfile: auk_dspip_r22sdf_cma_bfi_fp.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_cma_bfi_fp.vhd,v $
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
-- <Brief description of the contents of the file>
-- 
--
-- $Log: auk_dspip_r22sdf_cma_bfi_fp.vhd,v $
-- Revision 1.6.2.1  2007/07/24 08:19:34  kmarks
-- spr 247901 inverse not correctly propagated
--
-- Revision 1.6  2007/07/02 12:23:55  kmarks
-- removed reference to fft_7_2
--
-- Revision 1.5  2007/06/20 16:38:20  kmarks
-- Changed the way that processing is handled - it is more robust.
--
-- Revision 1.4  2007/06/04 08:54:00  kmarks
-- updated the verilog testbench and regression testbench for floating point. Fixed a few bugs in the floating point data path. Added -N/2 to N/2 support for floating pt. Fixed a bug in the fpadd
--
-- Revision 1.3  2007/05/21 16:18:45  kmarks
-- bug fixes - works for N= 64 with bit reversed inputs
--
-- Revision 1.2  2007/05/11 13:29:39  kmarks
-- syntax error
--
-- Revision 1.1  2007/05/11 10:10:03  kmarks
-- Added floating point, untested as yet.
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

entity auk_dspip_r22sdf_cma_bfi_fp is

  generic (
    STAGE_g          : natural := 1;
    DATAWIDTH_g      : natural := 18 + 14;
    TWIDWIDTH_g      : natural := 18;
    DELAY_g          : natural := 1;
    INPUT_FORMAT_g   : string  := "BIT_REVERSED";
    REPRESENTATION_g : string  := "FIXEDPT";
    MAX_FFTPTS_g     : natural := 1024;
    PIPELINE_g       : natural := 0;    -- total pipeline delay
    CMA_PIPELINE_g   : natural := 0;    -- delay of the cma by iteself
    NUM_STAGES_g     : natural := 5;
    GROW_g           : natural := 1     -- 1 grow datawidth
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
    realtwid     : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    imagtwid     : in  std_logic_vector(TWIDWIDTH_g - 1 downto 0);
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
    out_valid    : out std_logic

    );

end entity auk_dspip_r22sdf_cma_bfi_fp;

architecture rtl of auk_dspip_r22sdf_cma_bfi_fp is

  constant NUM_R2_STAGES_c  : natural := log2_ceil(MAX_FFTPTS_g);  --NUM_STAGES_g*2 
  constant TOTAL_PIPELINE_c : natural := PIPELINE_g + CMA_PIPELINE_g;

  -- _comp signals
  signal del_in_real_comp : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal del_in_imag_comp : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal in_real_comp     : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal in_imag_comp     : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);

  -- adder inputs
  signal adder_in_real_a : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal adder_in_real_b : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal adder_in_imag_a : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal adder_in_imag_b : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);

  signal cma_real_comp : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal cma_imag_comp : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);

  -- control signals
  signal s_sel           : std_logic;
  signal out_valid_int   : std_logic;
  signal out_inverse_int : std_logic;
  signal out_sop_int     : std_logic;
  signal out_eop_int     : std_logic;
  signal control         : std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);

  -- delayed signals
  signal s_sel_d       : std_logic_vector(TOTAL_PIPELINE_c downto 0);
  signal out_valid_d   : std_logic_vector(TOTAL_PIPELINE_c downto 0);
  signal out_sop_d     : std_logic_vector(TOTAL_PIPELINE_c downto 0);
  signal out_inverse_d : std_logic_vector(TOTAL_PIPELINE_c downto 0);
  signal out_eop_d     : std_logic_vector(TOTAL_PIPELINE_c downto 0);

  -- input signals
  signal del_in_real_s : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal del_in_imag_s : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal in_real_s     : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_s     : std_logic_vector(DATAWIDTH_g - 1 downto 0);

  -- delay the control until the output of the CMA
  type control_t is array (CMA_PIPELINE_g downto 0) of std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);

  signal curr_control_d : control_t;
  signal in_control_tmp : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal in_sop_d       : std_logic_vector(CMA_PIPELINE_g downto 0);
  signal in_eop_d       : std_logic_vector(CMA_PIPELINE_g downto 0);
  signal in_valid_d     : std_logic_vector(CMA_PIPELINE_g downto 0);
  signal in_inverse_d     : std_logic_vector(CMA_PIPELINE_g downto 0);
begin

  -- During the butterfly computation the input from the delay block is added/
  -- subtracted from the input stream. The delay blcok input is simply a
  -- delayed version of the input, therefore the size of the data in the
  -- delay block is DATAWIDTH_g, despite the fact that the actual size of
  -- the delay input is DATAWIDTH_g + GROW_g. The MSb is ignored.
  gen_control_bit_reverse : if INPUT_FORMAT_g = "BIT_REVERSED" generate
    s_sel <= (control(NUM_R2_STAGES_c - (STAGE_g*2)));
  end generate gen_control_bit_reverse;

  --control signals for bfi
  gen_control_in_order : if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" generate
    s_sel <= control(NUM_R2_STAGES_c - (STAGE_g*2 - 1));
  end generate gen_control_in_order;



  -- delay s_sel_d by pipeline
  sel_d_pipeline : process (clk)
  begin  -- process sel_d_pipeline
    if rising_edge(clk) then
      if reset = '1' then
        s_sel_d <= (others => '0');
      elsif enable = '1' then
        s_sel_d(0) <= s_sel;
        if PIPELINE_g > 0 then
          for i in PIPELINE_g downto 1 loop
            s_sel_d(i) <= s_sel_d(i-1);
          end loop;
        end if;
      end if;
    end if;
  end process sel_d_pipeline;


  -- generate input mux if INPUT_FORMAT_g is -N/2_to_N/2,
  gen_input_mux : if INPUT_FORMAT_g = "-N/2_to_N/2" and REPRESENTATION_g = "FIXEDPT" generate
    del_in_real_s <= std_logic_vector(resize(signed(in_real), del_in_real_s'length)) when in_sel = '1' and s_sel = '1' else
                     del_in_real;
    del_in_imag_s <= std_logic_vector(resize(signed(in_imag), del_in_imag_s'length)) when in_sel = '1' and s_sel = '1' else
                     del_in_imag;
    in_real_s <= del_in_real(in_real_s'length - 1 downto 0) when in_sel = '1' and s_sel = '1' else
                 in_real;
    in_imag_s <= del_in_imag(in_imag_s'length - 1 downto 0) when in_sel = '1' and s_sel = '1' else
                 in_imag;
  end generate gen_input_mux;

  gen_no_input_mux : if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "BIT_REVERSED" or REPRESENTATION_g = "FLOATPT" generate
    -- mux for floating pt and -N/2_to_N/2 is internal to the cma_fpadder
    del_in_real_s <= del_in_real;
    del_in_imag_s <= del_in_imag;
    in_real_s     <= in_real;
    in_imag_s     <= in_imag;
  end generate gen_no_input_mux;

  -----------------------------------------------------------------------------
  -- PIPELINE DELAY IS GREATER THAN FEEDBACK DELAY (DELAY_g)
  ----------------------------------------------------------------------------- 
  generate_delay_less_pipeline : if DELAY_g/2 <= PIPELINE_g + 1 and PIPELINE_g > 0 generate
    type   delay_reg_t is array (DELAY_g - 1 downto 0) of std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
    signal del_in_real_pl_d     : delay_reg_t;
    signal del_in_imag_pl_d     : delay_reg_t;
    signal cma_adder_out_real_d : delay_reg_t;
    signal cma_adder_out_imag_d : delay_reg_t;
    signal in_real_d            : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_d            : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  begin

    -- register inputs for timing purposes.
    reg_in_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          in_real_d <= (others => '0');
          in_imag_d <= (others => '0');
        elsif enable = '1' then
          in_real_d <= in_real_s;
          in_imag_d <= in_imag_s;
        end if;
      end if;
    end process reg_in_p;

    -- delay inputs from feedback loop by DELAY_g (offset to in_real_d and in_imag_d)
    gen_reg_delay_1 : if DELAY_g <= 1 generate
      reg_del_in_p : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            del_in_imag_pl_d <= (others => (others => '0'));
            del_in_real_pl_d <= (others => (others => '0'));
          elsif enable = '1' then
            del_in_imag_pl_d(0) <= del_in_imag_s;
            del_in_real_pl_d(0) <= del_in_real_s;
          end if;  -- end enable
        end if;  -- clk
      end process reg_del_in_p;
    end generate gen_reg_delay_1;
    gen_delay_gt_1 : if DELAY_g > 1 generate
      
      reg_del_in_p : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            del_in_imag_pl_d <= (others => (others => '0'));
            del_in_real_pl_d <= (others => (others => '0'));
          elsif enable = '1' then
            del_in_imag_pl_d(0) <= del_in_imag_s;
            del_in_real_pl_d(0) <= del_in_real_s;
            if in_radix_2 = '1' then
              del_in_imag_pl_d(1) <= del_in_imag_s;
              del_in_real_pl_d(1) <= del_in_real_s;
              if DELAY_g > 2 then
                for i in DELAY_g - 1 downto 2 loop
                  if i mod 2 = 1 then
                    del_in_imag_pl_d(i) <= del_in_imag_pl_d(i - 2);
                    del_in_real_pl_d(i) <= del_in_real_pl_d(i - 2);
                  end if;
                end loop;  -- i          
              end if;
            else
              for i in DELAY_g - 1 downto 1 loop
                del_in_imag_pl_d(i) <= del_in_imag_pl_d(i - 1);
                del_in_real_pl_d(i) <= del_in_real_pl_d(i - 1);
              end loop;  -- i 
            end if;  -- end if radix_2= '1'
          end if;  -- end enable
        end if;  -- clk
      end process reg_del_in_p;
    end generate gen_delay_gt_1;

    -- delay outputs from adder 1
    reg_adder_in_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          cma_adder_out_real_d <= (others => (others => '0'));
          cma_adder_out_imag_d <= (others => (others => '0'));
        elsif enable = '1' then
          cma_adder_out_real_d(0) <= in_real_comp;
          cma_adder_out_imag_d(0) <= in_imag_comp;
          if DELAY_g > 1 then
            for i in DELAY_g - 1 downto 1 loop
              cma_adder_out_real_d(i) <= cma_adder_out_real_d(i - 1);
              cma_adder_out_imag_d(i) <= cma_adder_out_imag_d(i - 1);
            end loop;  -- i 
          end if;
        end if;
      end if;
    end process reg_adder_in_p;


    -- feedback loop  is supplied with the input always, no mux
    del_out_real <= std_logic_vector(resize(signed(cma_real_comp), DATAWIDTH_g + GROW_g));
    del_out_imag <= std_logic_vector(resize(signed(cma_imag_comp), DATAWIDTH_g + GROW_g));

    -- adder inputs
    adder_in_real_a <= std_logic_vector(resize(signed(del_in_real_pl_d(DELAY_g - 1)), DATAWIDTH_g + GROW_g));
    adder_in_imag_a <= std_logic_vector(resize(signed(del_in_imag_pl_d(DELAY_g - 1)), DATAWIDTH_g + GROW_g));

    adder_in_real_b <= std_logic_vector(resize(signed(in_real_d), DATAWIDTH_g + GROW_g));
    adder_in_imag_b <= std_logic_vector(resize(signed(in_imag_d), DATAWIDTH_g + GROW_g));



    -- outputs
    reg_out_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          out_real <= (others => '0');
          out_imag <= (others => '0');
        elsif enable = '1' then
          if s_sel_d(PIPELINE_g) = '1' then
            out_real <= std_logic_vector(resize(signed(del_in_real_comp), DATAWIDTH_g + GROW_g));
            out_imag <= std_logic_vector(resize(signed(del_in_imag_comp), DATAWIDTH_g + GROW_g));
          else
            if in_radix_2 = '0' or DELAY_g/2 = 0 then
              out_real <= std_logic_vector(resize(signed(cma_adder_out_real_d(DELAY_g-1)), DATAWIDTH_g + GROW_g));
              out_imag <= std_logic_vector(resize(signed(cma_adder_out_imag_d(DELAY_g-1)), DATAWIDTH_g + GROW_g));
            else
              out_real <= std_logic_vector(resize(signed(cma_adder_out_real_d(DELAY_g/2-1)), DATAWIDTH_g + GROW_g));
              out_imag <= std_logic_vector(resize(signed(cma_adder_out_imag_d(DELAY_g/2-1)), DATAWIDTH_g + GROW_g));
            end if;
          end if;
        end if;
      end if;
    end process reg_out_p;
    
  end generate generate_delay_less_pipeline;

-----------------------------------------------------------------------------
-- PIPELINE DELAY IS LESS THAN FEEDBACK DELAY (DELAY_g)
----------------------------------------------------------------------------- 
  generate_delay_gt_pipeline : if DELAY_g/2 > PIPELINE_g + 1 or PIPELINE_g = 0 generate
    type   delay_reg_grow_t is array (PIPELINE_g downto 0) of std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
    type   delay_reg_t is array (PIPELINE_g downto 0) of std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_real_pl_d : delay_reg_t;
    signal in_imag_pl_d : delay_reg_t;

    signal del_in_real_pl_d : delay_reg_grow_t;
    signal del_in_imag_pl_d : delay_reg_grow_t;
  begin


    -- delay inputs from feedback loop by
    reg_del_in_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          del_in_imag_pl_d <= (others => (others => '0'));
          del_in_real_pl_d <= (others => (others => '0'));
        elsif enable = '1' then
          del_in_imag_pl_d(0) <= del_in_imag_s;
          del_in_real_pl_d(0) <= del_in_real_s;
          if PIPELINE_g > 0 then
            for i in PIPELINE_g downto 1 loop
              del_in_imag_pl_d(i) <= del_in_imag_pl_d(i-1);
              del_in_real_pl_d(i) <= del_in_real_pl_d(i-1);
            end loop;  -- i 
          end if;
        end if;
      end if;
    end process reg_del_in_p;

    -- delay inputs from feedback loop by DELAY_g (offset to in_real_d and in_imag_d)
    reg_in_pl_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          in_imag_pl_d <= (others => (others => '0'));
          in_real_pl_d <= (others => (others => '0'));
        elsif enable = '1' then
          in_imag_pl_d(0) <= in_imag_s;
          in_real_pl_d(0) <= in_real_s;
          if PIPELINE_g > 0 then
            in_real_pl_d(1) <= cma_real_comp;
            in_imag_pl_d(1) <= cma_imag_comp;
            for i in PIPELINE_g downto 2 loop
              in_imag_pl_d(i) <= in_imag_pl_d(i - 1);
              in_real_pl_d(i) <= in_real_pl_d(i - 1);
            end loop;  -- i 
          end if;
        end if;
      end if;
    end process reg_in_pl_p;

    -- output multiplexor, data sent to delay block.
    del_out_real <= in_real_comp when s_sel_d(PIPELINE_g) = '1' else
                    std_logic_vector(resize(signed(in_real_pl_d(PIPELINE_g)),
                                            DATAWIDTH_g + GROW_g));

    del_out_imag <= in_imag_comp when s_sel_d(PIPELINE_g) = '1' else
                    std_logic_vector(resize(signed(in_imag_pl_d(PIPELINE_g)),
                                            DATAWIDTH_g + GROW_g));

    -- adder inputs
    adder_in_real_a <= std_logic_vector(resize(signed(del_in_real_pl_d(0)), DATAWIDTH_g + GROW_g));
    adder_in_imag_a <= std_logic_vector(resize(signed(del_in_imag_pl_d(0)), DATAWIDTH_g + GROW_g));

    adder_in_real_b <= std_logic_vector(resize(signed(in_real_pl_d(0)), DATAWIDTH_g + GROW_g));
    adder_in_imag_b <= std_logic_vector(resize(signed(in_imag_pl_d(0)), DATAWIDTH_g + GROW_g));

    -- outputs
    reg_out_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          out_real <= (others => '0');
          out_imag <= (others => '0');
        elsif enable = '1' then
          if s_sel_d(PIPELINE_g) = '1' then
            out_real <= std_logic_vector(resize(signed(del_in_real_comp), DATAWIDTH_g + GROW_g));
            out_imag <= std_logic_vector(resize(signed(del_in_imag_comp), DATAWIDTH_g + GROW_g));
          else
            out_real <= std_logic_vector(resize(signed(del_in_real_pl_d(PIPELINE_g)), DATAWIDTH_g + GROW_g));
            out_imag <= std_logic_vector(resize(signed(del_in_imag_pl_d(PIPELINE_g)), DATAWIDTH_g + GROW_g));
          end if;
        end if;
      end if;
    end process reg_out_p;
    
    
    
  end generate generate_delay_gt_pipeline;


  -----------------------------------------------------------------------------
  -- ADDERS
  -----------------------------------------------------------------------------
  gen_fixedpt_adders : if REPRESENTATION_g = "FIXEDPT" generate

    -- Add/Subtract operations, grow data initially
    del_in_real_comp_inst : auk_dspip_r22sdf_addsub
      generic map (
        DATAWIDTH_g => DATAWIDTH_g +GROW_g,
        PIPELINE_g  => PIPELINE_g,
        GROW_g      => 0)
      port map (
        clk    => clk,
        reset  => reset,
        clken  => enable,
        add    => '1',
        dataa  => adder_in_real_a,
        datab  => adder_in_real_b,
        result => del_in_real_comp);

    del_in_imag_comp_inst : auk_dspip_r22sdf_addsub
      generic map (
        DATAWIDTH_g => DATAWIDTH_g +GROW_g,
        PIPELINE_g  => PIPELINE_g,
        GROW_g      => 0)
      port map (
        clk    => clk,
        reset  => reset,
        clken  => enable,
        add    => '1',
        dataa  => adder_in_imag_a,
        datab  => adder_in_imag_b,
        result => del_in_imag_comp);


    in_real_comp_inst : auk_dspip_r22sdf_addsub
      generic map (
        DATAWIDTH_g => DATAWIDTH_g +GROW_g,
        PIPELINE_g  => PIPELINE_g,
        GROW_g      => 0)
      port map (
        clk    => clk,
        reset  => reset,
        clken  => enable,
        add    => '0',
        dataa  => adder_in_real_a,
        datab  => adder_in_real_b,
        result => in_real_comp);

    in_imag_comp_inst : auk_dspip_r22sdf_addsub
      generic map (
        DATAWIDTH_g => DATAWIDTH_g +GROW_g,
        PIPELINE_g  => PIPELINE_g,
        GROW_g      => 0)
      port map (
        clk    => clk,
        reset  => reset,
        clken  => enable,
        add    => '0',
        dataa  => adder_in_imag_a,
        datab  => adder_in_imag_b,
        result => in_imag_comp);
  end generate gen_fixedpt_adders;

  -- generate floating point adders
  gen_floatpt_adders : if REPRESENTATION_g = "FLOATPT" generate
    -- adder inputs
    signal adder_in_real_b_d : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
    signal adder_in_imag_b_d : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
    function use_input_mux return natural is
    begin
      if INPUT_FORMAT_g = "-N/2_to_N/2" then
        return 1;
      else
        return 0;
      end if;
    end function use_input_mux;

    signal input_mux_ctrl : std_logic;
  begin

    -- delay data to align with twiddles
    delay_data : process (clk)
    begin  -- process delay_data
      if rising_edge(clk) then
        if reset = '1' then
          adder_in_real_b_d <= (others => '0');
          adder_in_imag_b_d <= (others => '0');
        elsif enable = '1' then
          adder_in_real_b_d <= adder_in_real_b;
          adder_in_imag_b_d <= adder_in_imag_b;
        end if;
      end if;
    end process delay_data;
    input_mux_ctrl <= in_sel and s_sel when INPUT_FORMAT_g = "-N/2_to_N/2" else
                      '0';
    bfi_cma_fpadder_inst : auk_dspip_r22sdf_cma_adder_fp
      generic map (
        INPUT_MUX_CONTROL_g => use_input_mux)
      port map (
        sysclk         => clk,
        reset          => reset,
        enable         => enable,
        input_mux_ctrl => input_mux_ctrl,
        realin         => adder_in_real_b_d,
        imagin         => adder_in_imag_b_d,
        realin_d       => adder_in_real_a,
        imagin_d       => adder_in_imag_a,
        realtwid       => realtwid,
        imagtwid       => imagtwid,
        cma_real_out   => cma_real_comp,
        cma_imag_out   => cma_imag_comp,
        realout        => del_in_real_comp,  --in_real_comp,
        imagout        => del_in_imag_comp,  --in_imag_comp,
        realout_d      => in_real_comp,      --del_in_real_comp,
        imagout_d      => in_imag_comp       --del_in_imag_comp
        );

  end generate gen_floatpt_adders;


  -----------------------------------------------------------------------------
  -- OUTPUTS
  -----------------------------------------------------------------------------
  -- register the control signals to align with the data
  gen_outvalid_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_valid_d <= (others => '0');
        out_valid   <= '0';
      elsif enable = '1' then
        out_valid      <= out_valid_d(PIPELINE_g);
        out_valid_d(0) <= out_valid_int;
        if PIPELINE_g > 0 then
          for i in PIPELINE_g downto 1 loop
            out_valid_d(i) <= out_valid_d(i-1);
          end loop;
        end if;
      end if;
    end if;
  end process gen_outvalid_p;

  -- delay the  control by CMA_PIPELINE_g
  gen_delay_control : process (clk)
  begin  -- process gen_delay_control
    if rising_edge(clk) then
      if reset = '1' then
        curr_control_d <= (others => (others => '0'));
        in_sop_d       <= (others => '0');
        in_eop_d       <= (others => '0');
        in_valid_d     <= (others => '0');
        in_inverse_d     <= (others => '0');
      elsif enable = '1' then
        curr_control_d(0) <= in_control;
        in_valid_d(0)     <= in_valid;
        in_inverse_d(0)   <= in_inverse;
        in_sop_d(0)       <= in_sop;
        in_eop_d(0)       <= in_eop;
        for i in CMA_PIPELINE_g downto 1 loop
          curr_control_d(i) <= curr_control_d(i-1);
          in_valid_d(i)     <= in_valid_d(i-1);
          in_inverse_d(i)   <=  in_inverse_d(i-1);
          in_sop_d(i)       <= in_sop_d(i-1);
          in_eop_d(i)       <= in_eop_d(i-1);
        end loop;
      end if;
    end if;
  end process gen_delay_control;

-- register the control signals to align with the data
  gen_eopsop_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        if PIPELINE_g > 0 then
          out_inverse_d <= (others => '0');
          out_sop_d     <= (others => '0');
          out_eop_d     <= (others => '0');
        end if;
        out_inverse <= '0';
        out_sop     <= '0';
        out_eop     <= '0';
      elsif enable = '1' then
        if PIPELINE_g > 0 then
          out_sop_d(0)     <= out_sop_int;
          out_eop_d(0)     <= out_eop_int;
          out_inverse_d(0) <= out_inverse_int;
          for i in PIPELINE_g downto 1 loop
            out_inverse_d(i) <= out_inverse_d(i-1);
            out_sop_d(i)     <= out_sop_d(i-1);
            out_eop_d(i)     <= out_eop_d(i-1);
          end loop;
          out_inverse <= out_inverse_d(PIPELINE_g-1);
          out_sop     <= out_sop_d(PIPELINE_g-1);
          out_eop     <= out_eop_d(PIPELINE_g-1);
        else
          out_inverse <= out_inverse_int;
          out_sop     <= out_sop_int;
          out_eop     <= out_eop_int;
        end if;
      end if;
    end if;
  end process gen_eopsop_p;


  -----------------------------------------------------------------------------
  -- control
  -----------------------------------------------------------------------------

  in_control_tmp <= std_logic_vector(unsigned(in_control) + 1) when in_radix_2 = '0' else
                    std_logic_vector(unsigned(in_control) + 2);
  bf_counter_inst : auk_dspip_r22sdf_counter
    generic map (
      MAX_FFTPTS_g   => MAX_FFTPTS_g,
      INPUT_FORMAT_g => INPUT_FORMAT_g)
    port map (
      clk         => clk,
      reset       => reset,
      -- start/stop processing
      enable      => enable,
      in_sop      => in_sop,
      in_eop      => in_eop,
      in_valid    => in_valid,
      --number of points in the fft
      in_fftpts   => in_fftpts,
      in_radix_2  => in_radix_2,
      in_control  => in_control_tmp,
      -- array of control signals to the stages.
      out_control => twidaddr);     
  bf_control_inst : auk_dspip_r22sdf_bf_control
    generic map (
      MAX_FFTPTS_g   => MAX_FFTPTS_g,
      INPUT_FORMAT_g => INPUT_FORMAT_g,
      DELAY_g        => DELAY_g)
    port map (
      clk          => clk,
      reset        => reset,
      enable       => enable,
      in_fftpts    => in_fftpts,
      in_radix_2   => in_radix_2,
      s_s          => s_sel,
      in_valid     => in_valid_d(CMA_PIPELINE_g),
      in_inverse   => in_inverse_d(CMA_PIPELINE_g),
      in_sop       => in_sop_d(CMA_PIPELINE_g),
      in_eop       => in_eop_d(CMA_PIPELINE_g),
      in_control   => curr_control_d(CMA_PIPELINE_g),
      curr_control => control,
      out_control  => out_control,
      out_inverse  => out_inverse_int,
      out_sop      => out_sop_int,
      out_eop      => out_eop_int,
      out_valid    => out_valid_int);



end architecture rtl;
