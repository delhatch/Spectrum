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
-- $RCSfile: auk_dspip_r22sdf_bfii.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_bfii.vhd,v $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   : kmarks
--
-- Project      :  auk_dspip_r22sdf
--
-- Description : 
--
-- As with bfi,  except the multiplication by -j is performed by swapping real
-- and imaginary components and one of the add operations becomes a subtract.
--
-- $Log: auk_dspip_r22sdf_bfii.vhd,v $
-- Revision 1.7  2007/05/21 16:18:45  kmarks
-- bug fixes - works for N= 64 with bit reversed inputs
--
-- Revision 1.6  2007/05/11 10:10:02  kmarks
-- Added floating point, untested as yet.
--
-- Revision 1.5  2007/02/07 14:46:14  kmarks
-- added dynamic inverse testing and fixed the inverse fft bug.
--
-- Revision 1.4  2007/01/25 12:38:50  kmarks
-- added bit reversal optimisations
--
-- Revision 1.3  2006/12/05 10:54:43  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.2.2.1  2006/09/28 16:47:28  kmarks
-- fmax improvements SPR 219316
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

entity auk_dspip_r22sdf_bfii is

  generic (
    STAGE_g          : natural := 1;
    DATAWIDTH_g      : natural := 18+14;
    TWIDWIDTH_g      : natural := 18;
    DELAY_g          : natural := 1;
    INPUT_FORMAT_g   : string  := "BIT_REVERSED";
    REPRESENTATION_g : string  := "FIXEDPT";
    PIPELINE_g       : natural := 0;
    MAX_FFTPTS_g     : natural := 1024;
    NUM_STAGES_g     : natural := 5;
    GROW_g           : natural := 1     -- 1 grow datawidth 
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

end entity auk_dspip_r22sdf_bfii;


architecture rtl of auk_dspip_r22sdf_bfii is

  -- the number of radix 2 stages in the current configuration. This is
  -- needed to select the correct bits for the butterfly control signals s
  -- and t.
  constant NUM_R2_STAGES_c : natural := log2_ceil(MAX_FFTPTS_g);

  -- Signals through the butterfly are either sent through the addition/
  -- subtraction or they are sent through unaltered. Those signals
  -- after the add/sub have the suffix _comp. Note that the _comp signals
  -- are 1 bit larger 

  -- _comp signals
  signal del_in_real_comp : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal del_in_imag_comp : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal in_real_comp     : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal in_imag_comp     : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);

  -- commutator control signal
  signal cmm_control : std_logic;

  -- commutator output signals.
  signal in_real_cmm : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_cmm : std_logic_vector(DATAWIDTH_g - 1 downto 0);

  -- adder inputs
  signal adder_in_real_a : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal adder_in_real_b : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal adder_in_imag_a : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal adder_in_imag_b : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);

  -- control signals
  signal s_sel           : std_logic;
  signal t_sel           : std_logic;
  signal out_inverse_int : std_logic;
  signal out_valid_int   : std_logic;
  signal out_sop_int     : std_logic;
  signal out_eop_int     : std_logic;
  signal control         : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);

  -- delayed signals if pipelining is used.
  signal s_sel_d       : std_logic_vector(PIPELINE_g downto 0);
  signal t_sel_d       : std_logic;
  signal cmm_control_d : std_logic;
  signal out_valid_d   : std_logic_vector(PIPELINE_g downto 0);
  signal out_inverse_d : std_logic_vector(PIPELINE_g downto 0);
  signal out_sop_d     : std_logic_vector(PIPELINE_g downto 0);
  signal out_eop_d     : std_logic_vector(PIPELINE_g downto 0);

  
begin

  --control signals for bfii - these control the commuator
  gen_control_bit_reverse : if INPUT_FORMAT_g = "BIT_REVERSED" generate
    gen_constant_t_sel : if NUM_R2_STAGES_c < STAGE_g*2 generate
      -- this case will be selected for the first stage when max_pwr_2 = 1
      t_sel <= '1';
    end generate gen_constant_t_sel;
    gen_variable_t_sel : if NUM_R2_STAGES_c >= STAGE_g*2 generate
      t_sel <= not(control(NUM_R2_STAGES_c - (STAGE_g*2)));
    end generate gen_variable_t_sel;
    s_sel <= control(NUM_R2_STAGES_c - (STAGE_g*2) +1);
  end generate gen_control_bit_reverse;

  gen_control_in_order : if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" generate
    s_sel <= control(NUM_R2_STAGES_c - (STAGE_g*2));
    t_sel <= control(NUM_R2_STAGES_c - (STAGE_g*2) + 1);
  end generate gen_control_in_order;

  -- Commutator control
  cmm_control <= s_sel and not(t_sel);

  -- commuataor, part of the trivial multiplication
  in_real_cmm <= in_real when cmm_control = '0' else
                 in_imag;
  in_imag_cmm <= in_imag when cmm_control = '0' else
                 in_real;

  -- delay s_sel_d by pipeline, t_sel_d is delayed by 1 (input register)
  sel_d_pipeline : process (clk)
  begin  -- process sel_d_pipeline
    if rising_edge(clk) then
      if reset = '1' then
        s_sel_d       <= (others => '0');
        t_sel_d       <= '0';
        cmm_control_d <= '0';
      elsif enable = '1' then
        s_sel_d(0)    <= s_sel;
        t_sel_d       <= t_sel;
        cmm_control_d <= cmm_control;
        if PIPELINE_g > 0 then
          for i in PIPELINE_g downto 1 loop
            s_sel_d(i) <= s_sel_d(i-1);
          end loop;
        end if;
      end if;
    end if;
  end process sel_d_pipeline;

  -----------------------------------------------------------------------------
  -- PIPELINE DELAY IS GREATER THAN FEEDBACK DELAY (DELAY_g)
  ----------------------------------------------------------------------------- 
  generate_delay_less_pipeline : if DELAY_g/2 <= PIPELINE_g + 1 and PIPELINE_g > 0 generate
    type   delay_reg_t is array (DELAY_g - 1 downto 0) of std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
    signal del_in_real_pl_d  : delay_reg_t;
    signal del_in_imag_pl_d  : delay_reg_t;
    signal adder2_out_real_d : delay_reg_t;
    signal adder2_out_imag_d : delay_reg_t;
    signal in_real_cmm_d     : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_cmm_d     : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  begin

-- register signals after commuator for timing purposes.
    reg_in_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          in_real_cmm_d <= (others => '0');
          in_imag_cmm_d <= (others => '0');
        elsif enable = '1' then
          in_real_cmm_d <= in_real_cmm;
          in_imag_cmm_d <= in_imag_cmm;
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
            del_in_imag_pl_d(0) <= del_in_imag;
            del_in_real_pl_d(0) <= del_in_real;
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
            del_in_imag_pl_d(0) <= del_in_imag;
            del_in_real_pl_d(0) <= del_in_real;
            if in_radix_2 = '1' then
              del_in_imag_pl_d(1) <= del_in_imag;
              del_in_real_pl_d(1) <= del_in_real;
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
          adder2_out_real_d <= (others => (others => '0'));
          adder2_out_imag_d <= (others => (others => '0'));
        elsif enable = '1' then
          adder2_out_real_d(0) <= in_real_comp;
          adder2_out_imag_d(0) <= in_imag_comp;
          if DELAY_g > 1 then
            for i in DELAY_g - 1 downto 1 loop
              adder2_out_real_d(i) <= adder2_out_real_d(i - 1);
              adder2_out_imag_d(i) <= adder2_out_imag_d(i - 1);
            end loop;  -- i 
          end if;
        end if;
      end if;
    end process reg_adder_in_p;

    -- feedback loop  is supplied with the input always, no mux
    del_out_real <= std_logic_vector(resize(signed(in_real_cmm_d), DATAWIDTH_g + GROW_g));
    del_out_imag <= std_logic_vector(resize(signed(in_imag_cmm_d), DATAWIDTH_g + GROW_g));

    -- adder inputs
    adder_in_real_a <= std_logic_vector(resize(signed(del_in_real_pl_d(DELAY_g - 1)), DATAWIDTH_g + GROW_g));
    adder_in_imag_a <= std_logic_vector(resize(signed(del_in_imag_pl_d(DELAY_g - 1)), DATAWIDTH_g + GROW_g));

    adder_in_real_b <= std_logic_vector(resize(signed(in_real_cmm_d), DATAWIDTH_g + GROW_g));
    adder_in_imag_b <= std_logic_vector(resize(signed(in_imag_cmm_d), DATAWIDTH_g + GROW_g));

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
            -- DELAY_g/2 = 0 stops compiler error, actual data is muxed from
            -- output of
            if in_radix_2 = '0' or DELAY_g/2 = 0 then
              out_real <= std_logic_vector(resize(signed(adder2_out_real_d(DELAY_g-1)), DATAWIDTH_g + GROW_g));
              out_imag <= std_logic_vector(resize(signed(adder2_out_imag_d(DELAY_g-1)), DATAWIDTH_g + GROW_g));
            else
              out_real <= std_logic_vector(resize(signed(adder2_out_real_d(DELAY_g/2-1)), DATAWIDTH_g + GROW_g));
              out_imag <= std_logic_vector(resize(signed(adder2_out_imag_d(DELAY_g/2-1)), DATAWIDTH_g + GROW_g));
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
          del_in_imag_pl_d(0) <= del_in_imag;
          del_in_real_pl_d(0) <= del_in_real;
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
          in_imag_pl_d(0) <= in_imag_cmm;
          in_real_pl_d(0) <= in_real_cmm;
          if PIPELINE_g > 0 then
            for i in PIPELINE_g downto 1 loop
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

    -- Add/Subtract operations, grow data initially
    del_in_real_comp_inst : auk_dspip_r22sdf_addsub
      generic map (
        DATAWIDTH_g => DATAWIDTH_g +GROW_g,
        REPRESENTATION_g => REPRESENTATION_g,
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
        REPRESENTATION_g => REPRESENTATION_g,
        PIPELINE_g  => PIPELINE_g,
        GROW_g      => 0)
      port map (
        clk    => clk,
        reset  => reset,
        clken  => enable,
        add    => t_sel_d,
        dataa  => adder_in_imag_a,
        datab  => adder_in_imag_b,
        result => del_in_imag_comp);

    in_real_comp_inst : auk_dspip_r22sdf_addsub
      generic map (
        DATAWIDTH_g => DATAWIDTH_g +GROW_g,
        REPRESENTATION_g => REPRESENTATION_g,
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
        REPRESENTATION_g => REPRESENTATION_g,
        PIPELINE_g  => PIPELINE_g,
        GROW_g      => 0)
      port map (
        clk    => clk,
        reset  => reset,
        clken  => enable,
        add    => cmm_control_d,
        dataa  => adder_in_imag_a,
        datab  => adder_in_imag_b,
        result => in_imag_comp);



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
          out_inverse_d(0) <= out_inverse_int;
          out_sop_d(0)     <= out_sop_int;
          out_eop_d(0)     <= out_eop_int;
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




  bf_control_inst : auk_dspip_r22sdf_bf_control
    generic map (
      MAX_FFTPTS_g   => MAX_FFTPTS_g,
      INPUT_FORMAT_g => INPUT_FORMAT_g,
      DELAY_g        => DELAY_g)
    port map (
      clk          => clk,
      reset        => reset,
      enable       => enable,
      in_sop       => in_sop,
      in_eop       => in_eop,
      in_inverse   => in_inverse,
      in_fftpts    => in_fftpts,
      in_radix_2   => in_radix_2,
      s_s          => s_sel,
      in_valid     => in_valid,
      in_control   => in_control,
      curr_control => control,
      out_control  => out_control,
      out_inverse  => out_inverse_int,
      out_sop      => out_sop_int,
      out_eop      => out_eop_int,
      out_valid    => out_valid_int);


end architecture rtl;


