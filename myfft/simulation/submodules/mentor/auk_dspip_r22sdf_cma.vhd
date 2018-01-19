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
-- $RCSfile: auk_dspip_r22sdf_cma.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_cma.vhd,v $
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
-- complex multiplier
-- Performs the complex multiplication (X+iY)(A+iB) = (X.A - Y.B) + i(Y.A + X.B)
-- 
--
-- $Log: auk_dspip_r22sdf_cma.vhd,v $
-- Revision 1.14  2007/03/29 08:36:04  kmarks
-- updated with fix for consecutive N=16 transforms
--
-- Revision 1.12.2.2  2007/03/28 14:44:05  kmarks
-- SPR239147 - consecutive N=16 transforms gives errors
--
-- Revision 1.12.2.1  2007/02/16 17:23:25  kmarks
-- SPR223891 - cast to bit vector and back to std_logic_vector to force to 0 when undefined
--
-- Revision 1.12  2007/02/07 14:46:15  kmarks
-- added dynamic inverse testing and fixed the inverse fft bug.
--
-- Revision 1.11  2007/02/06 13:19:23  kmarks
-- bugs when DSP_ROUNDING_g = 0.
--
-- Revision 1.10  2007/01/31 12:18:17  kmarks
-- set saturation to NO. Moved rounding width one bit - different simulation model in 7.1... More investigation might be needed.
--
-- Revision 1.9  2007/01/12 13:26:51  kmarks
-- add OPTIMIZE_MEM_g - and added relevant pipeline stages to align data and twiddles when OPTIMIZE_MEM=1.
--
-- Revision 1.8  2007/01/04 10:47:49  kmarks
-- accidently removed end generate statement- added back in.
--
-- Revision 1.7  2007/01/04 10:46:02  kmarks
-- changed position of register - after multiplier, before rounding (was after rounding)
--
-- Revision 1.6  2006/12/19 18:07:30  kmarks
-- Updated to make use of the rounding in the stratix III DSP block.
--
-- Revision 1.5  2006/12/05 10:54:43  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.4.2.1  2006/09/28 16:47:28  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.4  2006/09/06 14:39:38  kmarks
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
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_lnsim;
use altera_lnsim.altera_lnsim_components.all;
library work;
use work.auk_dspip_math_pkg.all;
use work.auk_dspip_lib_pkg.all;
use work.auk_dspip_r22sdf_lib_pkg.all;


entity auk_dspip_r22sdf_cma is
  generic (
    DEVICE_FAMILY_g  : string  := "Arria 10";
    DATAWIDTH_g      : natural := 24;
    TWIDWIDTH_g      : natural := 24;
    INPUT_FORMAT_g   : string  := "NATURAL_ORDER";
    PIPELINE_g       : natural := 4;    -- this should match the number of
                                        -- cyles latency through the block
    OPTIMIZE_SPEED_g : natural := 0;    -- adds extra pipeline stage
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
    in_sop      : in  std_logic;
    in_eop      : in  std_logic;
    in_inverse  : in  std_logic;
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
end auk_dspip_r22sdf_cma;

--
-- This architecture makes better use of the adders in the DSP block.
--
architecture rtl of auk_dspip_r22sdf_cma is


  -- Performs the complex multiplication (X+iY)(A+iB) = (X.A - Y.B) + i(Y.A + X.B)
  constant TEST_c : natural := 0;
  constant MULT_18_X_18 : boolean := ((DATAWIDTH_g <= 18 and DSP_ARCH_g < 2) or (DATAWIDTH_g <=19 and DSP_ARCH_g = 2)) and TWIDWIDTH_g <= 18;
  constant MULT_D27_TO_D38_X_T18 : boolean := DATAWIDTH_g > 26 and DATAWIDTH_g <= 38 and TWIDWIDTH_g <= 18; -- I think there is a problem here, the boolean expression and the comments do not match up. 
  constant MULT_AV_D27_TO_D38_X_T18 : boolean := MULT_D27_TO_D38_X_T18 and DSP_ARCH_g = 2;
  constant MULT_SV_OPT_D37_AND_OVER : boolean := DSP_ARCH_g = 1 and DATAWIDTH_g >= 37 and DATAWIDTH_g >= TWIDWIDTH_g;

  signal roundrealff : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);
  signal roundimagff : std_logic_vector(DATAWIDTH_g + GROW_g - 1 downto 0);

  -- converted to bit vector and back to supress warnings
  signal in_real_del,in_real_del_2  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_del,in_imag_del_2  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_real_std  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_std  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal realtwid_std : std_logic_vector(TWIDWIDTH_g - 1 downto 0);
  signal imagtwid_std : std_logic_vector(TWIDWIDTH_g - 1 downto 0);

  -- shift register to delay the enable signal by the latency throuhg this block
  type control_t is array (PIPELINE_g - 1 downto 0) of
    std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal out_valid_d    : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_sop_d      : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_eop_d      : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_inverse_d  : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_control_d  : control_t;
  signal in_control_tmp : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
begin

  -- convert to bit vector and back to convert X to 0, and reduce number of
  -- warnings in modelsim

  delay_input_proc : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        in_real_std <= (others=>'0');
        in_imag_std <= (others=>'0');
      elsif enable = '1' then
        in_real_std <= to_stdLogicVector(to_bitVector(in_real));
        in_imag_std <= to_stdLogicVector(to_bitVector(in_imag));
      end if;
    end if;
  end process;

  realtwid_std <= to_stdLogicVector(to_bitVector(realtwid));
  imagtwid_std <= to_stdLogicVector(to_bitVector(imagtwid));



  bf_counter_inst : auk_dspip_r22sdf_counter
    generic map (
      MAX_FFTPTS_g => MAX_FFTPTS_g,
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

  --in_control_tmp <= std_logic_vector(unsigned(in_control) + 1) when in_radix_2 = '0' else
  --                  std_logic_vector(unsigned(in_control) + 2);
  in_control_reg_proc : process (clk)
  begin
    if rising_edge(clk) then
      if in_radix_2 = '0' then
        in_control_tmp <= std_logic_vector(unsigned(in_control) + 1);
      else
        in_control_tmp <= std_logic_vector(unsigned(in_control) + 2);
      end if;
    end if;
  end process;


  A10_C_Mult_Archs : if DEVICE_FAMILY_g = "Arria 10" generate
    signal in_real_sync, in_imag_sync : std_logic_vector(DATAWIDTH_g-1 downto 0);
    signal in_real_sync_1, in_imag_sync_1 : std_logic_vector(DATAWIDTH_g-1 downto 0);
  begin 

      twiddle_delay : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            in_real_sync <= (others => '0');
            in_imag_sync <= (others => '0');
            in_real_sync_1 <= (others => '0');
            in_imag_sync_1 <= (others => '0');
          elsif enable = '1' then
            in_real_sync_1 <= in_real_std;
            in_imag_sync_1 <= in_imag_std;
            in_real_sync <= in_real_sync_1;
            in_imag_sync <= in_imag_sync_1;

          end if;
        end if;
      end process twiddle_delay;
    smaller_mult : if DATAWIDTH_g <= 18 and TWIDWIDTH_g <= 18 generate -- Latency 5 for the Mult + Rounding
      constant REGS : integer := 4;

      signal tw_r_in_0, tw_r_in_1, tw_r_in_2 : std_logic_vector(17 downto 0);
      signal tw_i_in_0, tw_i_in_1, tw_i_in_2 : std_logic_vector(17 downto 0);
      signal d_r_in_0,  d_r_in_1, d_r_in_2 : std_logic_vector(17 downto 0);
      signal d_i_in_0,  d_i_in_1, d_i_in_2 : std_logic_vector(17 downto 0);


      signal real_res,real_res_r_0, real_res_r_1     : signed(36 downto 0);
      signal imag_res,imag_res_r_0, imag_res_r_1     : signed(36 downto 0);    

      signal real_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
      signal imag_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    begin

      real_res <= (
                    resize(signed(signed(signed(tw_r_in_2))*signed(signed(d_r_in_2))),37)
                    -
                    resize(signed(signed(signed(tw_i_in_2))*signed(signed(d_i_in_2))),37)
                 );
      imag_res <= (
                    resize(signed(signed(signed(tw_r_in_2))*signed(signed(d_i_in_2))),37)
                    +
                    resize(signed(signed(signed(tw_i_in_2))*signed(signed(d_r_in_2))),37)
                 );


      mult_proc : process( clk )
      begin
        if(rising_edge(clk)) then
        if enable = '1' then
          tw_r_in_0 <= std_logic_vector(resize(signed(realtwid_std),18));
          tw_i_in_0 <= std_logic_vector(resize(signed(imagtwid_std),18));
          d_r_in_0 <= std_logic_vector(resize(signed(in_real_sync),18));
          d_i_in_0 <= std_logic_vector(resize(signed(in_imag_sync),18));
          tw_r_in_1 <= tw_r_in_0;
          tw_i_in_1 <= tw_i_in_0;
          d_r_in_1 <= d_r_in_0;
          d_i_in_1 <= d_i_in_0;
          tw_r_in_2 <= tw_r_in_1;
          tw_i_in_2 <= tw_i_in_1;
          d_r_in_2 <= d_r_in_1;
          d_i_in_2 <= d_i_in_1;
          real_res_r_0 <= real_res;
          imag_res_r_0 <= imag_res;
          real_res_r_1 <= real_res_r_0;
          imag_res_r_1 <= imag_res_r_0;

        end if;
        end if; 
      end process ; -- mult_proc
  
    real_result <= std_logic_vector(real_res_r_1(DATAWIDTH_g+TWIDWIDTH_g downto 0));
    imag_result <= std_logic_vector(imag_res_r_1(DATAWIDTH_g+TWIDWIDTH_g downto 0));


    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => real_result(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundrealff
      );

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => imag_result(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimagff
      );

    end generate smaller_mult;

    medium_mult : if (DATAWIDTH_g > 18 or TWIDWIDTH_g > 18) and DATAWIDTH_g < 27 and TWIDWIDTH_g < 27 generate -- Latency 5 for the Mult + 2 for Addition + Rounding
      signal tw_r_in_0, tw_r_in_1, tw_r_in_2 : std_logic_vector(TWIDWIDTH_g-1 downto 0);
      signal tw_i_in_0, tw_i_in_1, tw_i_in_2 : std_logic_vector(TWIDWIDTH_g-1 downto 0);
      signal d_r_in_0,  d_r_in_1, d_r_in_2 : std_logic_vector(DATAWIDTH_g-1 downto 0);
      signal d_i_in_0,  d_i_in_1, d_i_in_2 : std_logic_vector(DATAWIDTH_g-1 downto 0);
     signal tw_r_p_tw_i,d_r_p_d_i,d_i_m_d_r : std_logic_vector(26 downto 0);
      signal dr_tw_tw_i_res,dr_tw_tw_i_r_0, dr_tw_tw_i_r_1      : signed(53 downto 0);
      signal tw_i_d_r_d_i_res,tw_i_d_r_d_i_r_0, tw_i_d_r_d_i_r_1      : signed(53 downto 0);
      signal tw_r_d_i_d_r_res,tw_r_d_i_d_r_r_0, tw_r_d_i_d_r_r_1      : signed(53 downto 0);

      signal dr_tw_tw_i_r_2 : std_logic_vector(DATAWIDTH_g+TWIDWIDTH_g downto 0);
      signal tw_i_d_r_d_i_r_2 : std_logic_vector(DATAWIDTH_g+TWIDWIDTH_g downto 0);
      signal tw_r_d_i_d_r_r_2 : std_logic_vector(DATAWIDTH_g+TWIDWIDTH_g downto 0);

      signal real_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
      signal imag_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    begin

      mult_proc : process( clk )
      begin
        if(rising_edge(clk)) then
          if enable = '1' then
            tw_r_in_0 <= realtwid_std;
            tw_i_in_0 <= imagtwid_std;
            d_r_in_0 <= in_real_sync;
            d_i_in_0 <= in_imag_sync;
            tw_r_in_1 <= tw_r_in_0;
            tw_i_in_1 <= tw_i_in_0;
            d_r_in_1 <= d_r_in_0;
            d_i_in_1 <= d_i_in_0;
            tw_r_in_2 <= tw_r_in_1;
            tw_i_in_2 <= tw_i_in_1;
            d_r_in_2 <= d_r_in_1;
            d_i_in_2 <= d_i_in_1;
            dr_tw_tw_i_r_0 <= dr_tw_tw_i_res;
            tw_i_d_r_d_i_r_0 <= tw_i_d_r_d_i_res;
            tw_r_d_i_d_r_r_0 <= tw_r_d_i_d_r_res;
            dr_tw_tw_i_r_1 <= dr_tw_tw_i_r_0;
            tw_i_d_r_d_i_r_1 <= tw_i_d_r_d_i_r_0;
            tw_r_d_i_d_r_r_1 <= tw_r_d_i_d_r_r_0;

          end if;
        end if; 
      end process ; -- mult_proc

      tw_r_p_tw_i <= std_logic_vector(resize(resize(signed(tw_r_in_2),27) + resize(signed(tw_i_in_2),26),27));
      d_r_p_d_i <= std_logic_vector(resize(resize(signed(d_r_in_2),27) + resize(signed(d_i_in_2),26),27));
      d_i_m_d_r <= std_logic_vector(resize(resize(signed(d_i_in_2),27) - resize(signed(d_r_in_2),26),27));

      dr_tw_tw_i_res <= resize(resize(signed(d_r_in_2),27) * signed(tw_r_p_tw_i),54);
      tw_i_d_r_d_i_res <= resize(resize(signed(tw_i_in_2),27) * signed(d_r_p_d_i),54);
      tw_r_d_i_d_r_res <= resize(resize(signed(tw_r_in_2),27) * signed(d_i_m_d_r),54);

      dr_tw_tw_i_r_2 <= std_logic_vector(dr_tw_tw_i_r_1(DATAWIDTH_g+TWIDWIDTH_g downto 0));
      tw_i_d_r_d_i_r_2 <= std_logic_vector(tw_i_d_r_d_i_r_1(DATAWIDTH_g+TWIDWIDTH_g downto 0));
      tw_r_d_i_d_r_r_2 <= std_logic_vector(tw_r_d_i_d_r_r_1(DATAWIDTH_g+TWIDWIDTH_g downto 0));

      real_sum : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 3,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '0',
          dataa  => dr_tw_tw_i_r_2,
          datab  => tw_i_d_r_d_i_r_2,
          result => real_result);


      imag_sum : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 3,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => dr_tw_tw_i_r_2,
          datab  => tw_r_d_i_d_r_r_2,
          result => imag_result);



    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => real_result(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundrealff
      );

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => imag_result(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimagff
      );




    end generate medium_mult;
    large_mult : if not(DATAWIDTH_g < 27 and TWIDWIDTH_g < 27) generate -- Latency 5 for the Mult + 2 for Addition + Rounding
    constant LATENCY_ADDED_c : integer := 0;
    signal dr_del_0 : std_logic_vector(DATAWIDTH_g-1 downto 0);
    signal di_del_0 : std_logic_vector(DATAWIDTH_g-1 downto 0);
    signal tr_del_0 : std_logic_vector(TWIDWIDTH_g-1 downto 0);
    signal ti_del_0 : std_logic_vector(TWIDWIDTH_g-1 downto 0);
    signal real_result,real_res     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal imag_result,imag_res     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal dr_tr, dr_ti, di_tr, di_ti     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g-1 downto 0);
    signal dr_tr_del, dr_ti_del, di_tr_del, di_ti_del     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g-1 downto 0);
    signal real_in_a, real_in_b, imag_in_a, imag_in_b : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);

    -- constant TW_L_W : integer := TWIDWIDTH_g/2;
    -- constant TW_H_W : integer := TWIDWIDTH_g - TW_L_W;
    -- constant D_L_W : integer := DATAWIDTH_g/2;
    -- constant D_H_W : integer := DATAWIDTH_g - D_L_W;

    -- signal trl  : std_logic_vector(TW_L_W downto 0);
    -- signal til  : std_logic_vector(TW_L_W downto 0);
    -- signal trh  : std_logic_vector(TW_H_W-1 downto 0);
    -- signal tih  : std_logic_vector(TW_H_W-1 downto 0);

    -- signal drl  : std_logic_vector(D_L_W downto 0);
    -- signal dil  : std_logic_vector(D_L_W downto 0);
    -- signal drh  : std_logic_vector(D_H_W-1 downto 0);
    -- signal dih  : std_logic_vector(D_H_W-1 downto 0);



    begin


      separate_proc : process( clk )
      begin
        if(rising_edge(clk)) then
          if enable = '1' then
            
            tr_del_0 <= realtwid_std;
            ti_del_0 <= imagtwid_std;
            dr_del_0 <= in_real_sync;
            di_del_0 <= in_imag_sync;

            dr_tr_del <= dr_tr;
            dr_ti_del <= dr_ti;
            di_tr_del <= di_tr;
            di_ti_del <= di_ti;

            real_result <= real_res;
            imag_result <= imag_res;

          end if;
        end if; 
      end process ; -- separate_proc






      first_ma : component altera_mult_add
      generic map (
         number_of_multipliers             => 1,
         width_a                           => DATAWIDTH_g,
         width_b                           => TWIDWIDTH_g,
         width_result                      => DATAWIDTH_g+TWIDWIDTH_g,
         output_register                   => "CLOCK0",
         output_aclr                       => "ACLR0",
         multiplier1_direction             => "ADD",
         port_addnsub1                     => "PORT_UNUSED",
         addnsub_multiplier_register1      => "UNREGISTERED",
         addnsub_multiplier_aclr1          => "NONE",
         multiplier3_direction             => "ADD",
         port_addnsub3                     => "PORT_UNUSED",
         addnsub_multiplier_register3      => "UNREGISTERED",
         addnsub_multiplier_aclr3          => "NONE",
         representation_a                  => "SIGNED",
         port_signa                        => "PORT_UNUSED",
         signed_register_a                 => "UNREGISTERED",
         signed_aclr_a                     => "NONE",
         port_signb                        => "PORT_UNUSED",
         representation_b                  => "SIGNED",
         signed_register_b                 => "UNREGISTERED",
         signed_aclr_b                     => "NONE",
         input_register_a0                 => "CLOCK0",
         input_register_a1                 => "CLOCK0",
         input_register_a2                 => "UNREGISTERED",
         input_register_a3                 => "UNREGISTERED",
         input_aclr_a0                     => "ACLR0",
         input_aclr_a1                     => "ACLR0",
         input_aclr_a2                     => "NONE",
         input_aclr_a3                     => "NONE",
         input_register_b0                 => "CLOCK0",
         input_register_b1                 => "CLOCK0",
         input_register_b2                 => "UNREGISTERED",
         input_register_b3                 => "UNREGISTERED",
         input_aclr_b0                     => "ACLR0",
         input_aclr_b1                     => "ACLR0",
         input_aclr_b2                     => "NONE",
         input_aclr_b3                     => "NONE",
         scanouta_register                 => "UNREGISTERED",
         scanouta_aclr                     => "NONE",
         input_source_a0                   => "DATAA",
         input_source_a1                   => "DATAA",
         input_source_a2                   => "DATAA",
         input_source_a3                   => "DATAA",
         input_source_b0                   => "DATAB",
         input_source_b1                   => "DATAB",
         input_source_b2                   => "DATAB",
         input_source_b3                   => "DATAB",
         multiplier_register0              => "UNREGISTERED",
         multiplier_register1              => "UNREGISTERED",
         multiplier_register2              => "UNREGISTERED",
         multiplier_register3              => "UNREGISTERED",
         multiplier_aclr0                  => "NONE",
         multiplier_aclr1                  => "NONE",
         multiplier_aclr2                  => "NONE",
         multiplier_aclr3                  => "NONE",
         preadder_mode                     => "SIMPLE",
         preadder_direction_0              => "ADD",
         preadder_direction_1              => "ADD",
         preadder_direction_2              => "ADD",
         preadder_direction_3              => "ADD",
         width_c                           => 16,
         input_register_c0                 => "UNREGISTERED",
         input_register_c1                 => "UNREGISTERED",
         input_register_c2                 => "UNREGISTERED",
         input_register_c3                 => "UNREGISTERED",
         input_aclr_c0                     => "NONE",
         input_aclr_c1                     => "NONE",
         input_aclr_c2                     => "NONE",
         input_aclr_c3                     => "NONE",
         accumulator                       => "NO",
         accum_direction                   => "ADD",
         use_sload_accum_port              => "NO",
         loadconst_value                   => 64,
         accum_sload_register              => "UNREGISTERED",
         accum_sload_aclr                  => "NONE",
         double_accum                      => "NO",
         width_chainin                     => 1,
         chainout_adder                    => "NO",
         systolic_delay1                   => "UNREGISTERED",
         systolic_aclr1                    => "NONE",
         systolic_delay3                   => "UNREGISTERED",
         systolic_aclr3                    => "NONE",
         latency                           => LATENCY_ADDED_c,
         input_a0_latency_clock            => "CLOCK0",
         input_a1_latency_clock            => "CLOCK0",
         input_a2_latency_clock            => "UNREGISTERED",
         input_a3_latency_clock            => "UNREGISTERED",
         input_a0_latency_aclr             => "ACLR0",
         input_a1_latency_aclr             => "ACLR0",
         input_a2_latency_aclr             => "NONE",
         input_a3_latency_aclr             => "NONE",
         input_b0_latency_clock            => "CLOCK0",
         input_b1_latency_clock            => "CLOCK0",
         input_b2_latency_clock            => "UNREGISTERED",
         input_b3_latency_clock            => "UNREGISTERED",
         input_b0_latency_aclr             => "ACLR0",
         input_b1_latency_aclr             => "ACLR0",
         input_b2_latency_aclr             => "NONE",
         input_b3_latency_aclr             => "NONE",
         input_c0_latency_clock            => "UNREGISTERED",
         input_c1_latency_clock            => "UNREGISTERED",
         input_c2_latency_clock            => "UNREGISTERED",
         input_c3_latency_clock            => "UNREGISTERED",
         input_c0_latency_aclr             => "NONE",
         input_c1_latency_aclr             => "NONE",
         input_c2_latency_aclr             => "NONE",
         input_c3_latency_aclr             => "NONE",
         coefsel0_latency_clock            => "UNREGISTERED",
         coefsel1_latency_clock            => "UNREGISTERED",
         coefsel2_latency_clock            => "UNREGISTERED",
         coefsel3_latency_clock            => "UNREGISTERED",
         coefsel0_latency_aclr             => "NONE",
         coefsel1_latency_aclr             => "NONE",
         coefsel2_latency_aclr             => "NONE",
         coefsel3_latency_aclr             => "NONE",
         signed_latency_clock_a            => "UNREGISTERED",
         signed_latency_aclr_a             => "NONE",
         signed_latency_clock_b            => "UNREGISTERED",
         signed_latency_aclr_b             => "NONE",
         addnsub_multiplier_latency_clock1 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr1  => "NONE",
         addnsub_multiplier_latency_clock3 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr3  => "NONE",
         accum_sload_latency_clock         => "UNREGISTERED",
         accum_sload_latency_aclr          => "NONE",
         selected_device_family            => DEVICE_FAMILY_g
      )
      port map (
         result                => dr_tr,                             --  result.result
         dataa                 => dr_del_0,
         datab                 => tr_del_0,
         clock0                => clk,                             --  clock0.clk
         aclr0                 => reset,                              --  aclr0.aclr0
         scaninb               => (others => '0'),                    -- (terminated)
         sourcea               => (others => '0'),                    -- (terminated)
         sourceb               => (others => '0'),                    -- (terminated)
         scanoutb              => open,                               -- (terminated)
         mult01_round          => '0',                                -- (terminated)
         mult23_round          => '0',                                -- (terminated)
         mult01_saturation     => '0',                                -- (terminated)
         mult23_saturation     => '0',                                -- (terminated)
         addnsub1_round        => '0',                                -- (terminated)
         addnsub3_round        => '0',                                -- (terminated)
         mult0_is_saturated    => open,                               -- (terminated)
         mult1_is_saturated    => open,                               -- (terminated)
         mult2_is_saturated    => open,                               -- (terminated)
         mult3_is_saturated    => open,                               -- (terminated)
         output_round          => '0',                                -- (terminated)
         chainout_round        => '0',                                -- (terminated)
         output_saturate       => '0',                                -- (terminated)
         chainout_saturate     => '0',                                -- (terminated)
         chainout_sat_overflow => open,                               -- (terminated)
         zero_chainout         => '0',                                -- (terminated)
         rotate                => '0',                                -- (terminated)
         shift_right           => '0',                                -- (terminated)
         zero_loopback         => '0',                                -- (terminated)
         signa                 => '0',                                -- (terminated)
         signb                 => '0',                                -- (terminated)
         addnsub1              => '1',                                -- (terminated)
         addnsub3              => '1',                                -- (terminated)
         clock1                => '1',                                -- (terminated)
         clock2                => '1',                                -- (terminated)
         clock3                => '1',                                -- (terminated)
         ena0                  =>  enable,
         ena1                  => '1',                                -- (terminated)
         ena2                  => '1',                                -- (terminated)
         ena3                  => '1',                                -- (terminated)
         aclr1                 => '0',                                -- (terminated)
         aclr2                 => '0',                                -- (terminated)
         aclr3                 => '0',                                -- (terminated)
         scanina               => (others => '0'),                    -- (terminated)
         scanouta              => open,                               -- (terminated)
         coefsel0              => (others => '0'),                    -- (terminated)
         coefsel1              => (others => '0'),                    -- (terminated)
         coefsel2              => (others => '0'),                    -- (terminated)
         coefsel3              => (others => '0'),                    -- (terminated)
         datac                 => (others => '0'),                    -- (terminated)
         accum_sload           => '0',                                -- (terminated)
         sload_accum           => '0',                                -- (terminated)
         chainin               => open                                -- (terminated)
      );
      second_ma : component altera_mult_add
      generic map (
         number_of_multipliers             => 1,
         width_a                           => DATAWIDTH_g,
         width_b                           => TWIDWIDTH_g,
         width_result                      => DATAWIDTH_g+TWIDWIDTH_g,
         output_register                   => "CLOCK0",
         output_aclr                       => "ACLR0",
         multiplier1_direction             => "ADD",
         port_addnsub1                     => "PORT_UNUSED",
         addnsub_multiplier_register1      => "UNREGISTERED",
         addnsub_multiplier_aclr1          => "NONE",
         multiplier3_direction             => "ADD",
         port_addnsub3                     => "PORT_UNUSED",
         addnsub_multiplier_register3      => "UNREGISTERED",
         addnsub_multiplier_aclr3          => "NONE",
         representation_a                  => "SIGNED",
         port_signa                        => "PORT_UNUSED",
         signed_register_a                 => "UNREGISTERED",
         signed_aclr_a                     => "NONE",
         port_signb                        => "PORT_UNUSED",
         representation_b                  => "SIGNED",
         signed_register_b                 => "UNREGISTERED",
         signed_aclr_b                     => "NONE",
         input_register_a0                 => "CLOCK0",
         input_register_a1                 => "CLOCK0",
         input_register_a2                 => "UNREGISTERED",
         input_register_a3                 => "UNREGISTERED",
         input_aclr_a0                     => "ACLR0",
         input_aclr_a1                     => "ACLR0",
         input_aclr_a2                     => "NONE",
         input_aclr_a3                     => "NONE",
         input_register_b0                 => "CLOCK0",
         input_register_b1                 => "CLOCK0",
         input_register_b2                 => "UNREGISTERED",
         input_register_b3                 => "UNREGISTERED",
         input_aclr_b0                     => "ACLR0",
         input_aclr_b1                     => "ACLR0",
         input_aclr_b2                     => "NONE",
         input_aclr_b3                     => "NONE",
         scanouta_register                 => "UNREGISTERED",
         scanouta_aclr                     => "NONE",
         input_source_a0                   => "DATAA",
         input_source_a1                   => "DATAA",
         input_source_a2                   => "DATAA",
         input_source_a3                   => "DATAA",
         input_source_b0                   => "DATAB",
         input_source_b1                   => "DATAB",
         input_source_b2                   => "DATAB",
         input_source_b3                   => "DATAB",
         multiplier_register0              => "UNREGISTERED",
         multiplier_register1              => "UNREGISTERED",
         multiplier_register2              => "UNREGISTERED",
         multiplier_register3              => "UNREGISTERED",
         multiplier_aclr0                  => "NONE",
         multiplier_aclr1                  => "NONE",
         multiplier_aclr2                  => "NONE",
         multiplier_aclr3                  => "NONE",
         preadder_mode                     => "SIMPLE",
         preadder_direction_0              => "ADD",
         preadder_direction_1              => "ADD",
         preadder_direction_2              => "ADD",
         preadder_direction_3              => "ADD",
         width_c                           => 16,
         input_register_c0                 => "UNREGISTERED",
         input_register_c1                 => "UNREGISTERED",
         input_register_c2                 => "UNREGISTERED",
         input_register_c3                 => "UNREGISTERED",
         input_aclr_c0                     => "NONE",
         input_aclr_c1                     => "NONE",
         input_aclr_c2                     => "NONE",
         input_aclr_c3                     => "NONE",
         accumulator                       => "NO",
         accum_direction                   => "ADD",
         use_sload_accum_port              => "NO",
         loadconst_value                   => 64,
         accum_sload_register              => "UNREGISTERED",
         accum_sload_aclr                  => "NONE",
         double_accum                      => "NO",
         width_chainin                     => 1,
         chainout_adder                    => "NO",
         systolic_delay1                   => "UNREGISTERED",
         systolic_aclr1                    => "NONE",
         systolic_delay3                   => "UNREGISTERED",
         systolic_aclr3                    => "NONE",
         latency                           => LATENCY_ADDED_c,
         input_a0_latency_clock            => "CLOCK0",
         input_a1_latency_clock            => "CLOCK0",
         input_a2_latency_clock            => "UNREGISTERED",
         input_a3_latency_clock            => "UNREGISTERED",
         input_a0_latency_aclr             => "ACLR0",
         input_a1_latency_aclr             => "ACLR0",
         input_a2_latency_aclr             => "NONE",
         input_a3_latency_aclr             => "NONE",
         input_b0_latency_clock            => "CLOCK0",
         input_b1_latency_clock            => "CLOCK0",
         input_b2_latency_clock            => "UNREGISTERED",
         input_b3_latency_clock            => "UNREGISTERED",
         input_b0_latency_aclr             => "ACLR0",
         input_b1_latency_aclr             => "ACLR0",
         input_b2_latency_aclr             => "NONE",
         input_b3_latency_aclr             => "NONE",
         input_c0_latency_clock            => "UNREGISTERED",
         input_c1_latency_clock            => "UNREGISTERED",
         input_c2_latency_clock            => "UNREGISTERED",
         input_c3_latency_clock            => "UNREGISTERED",
         input_c0_latency_aclr             => "NONE",
         input_c1_latency_aclr             => "NONE",
         input_c2_latency_aclr             => "NONE",
         input_c3_latency_aclr             => "NONE",
         coefsel0_latency_clock            => "UNREGISTERED",
         coefsel1_latency_clock            => "UNREGISTERED",
         coefsel2_latency_clock            => "UNREGISTERED",
         coefsel3_latency_clock            => "UNREGISTERED",
         coefsel0_latency_aclr             => "NONE",
         coefsel1_latency_aclr             => "NONE",
         coefsel2_latency_aclr             => "NONE",
         coefsel3_latency_aclr             => "NONE",
         signed_latency_clock_a            => "UNREGISTERED",
         signed_latency_aclr_a             => "NONE",
         signed_latency_clock_b            => "UNREGISTERED",
         signed_latency_aclr_b             => "NONE",
         addnsub_multiplier_latency_clock1 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr1  => "NONE",
         addnsub_multiplier_latency_clock3 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr3  => "NONE",
         accum_sload_latency_clock         => "UNREGISTERED",
         accum_sload_latency_aclr          => "NONE",
         selected_device_family            => DEVICE_FAMILY_g
      )
      port map (
         result                => di_ti,                             --  result.result
         dataa                 => di_del_0,
         datab                 => ti_del_0,
         clock0                => clk,                             --  clock0.clk
         aclr0                 => reset,                              --  aclr0.aclr0
         scaninb               => (others => '0'),                    -- (terminated)
         sourcea               => (others => '0'),                    -- (terminated)
         sourceb               => (others => '0'),                    -- (terminated)
         scanoutb              => open,                               -- (terminated)
         mult01_round          => '0',                                -- (terminated)
         mult23_round          => '0',                                -- (terminated)
         mult01_saturation     => '0',                                -- (terminated)
         mult23_saturation     => '0',                                -- (terminated)
         addnsub1_round        => '0',                                -- (terminated)
         addnsub3_round        => '0',                                -- (terminated)
         mult0_is_saturated    => open,                               -- (terminated)
         mult1_is_saturated    => open,                               -- (terminated)
         mult2_is_saturated    => open,                               -- (terminated)
         mult3_is_saturated    => open,                               -- (terminated)
         output_round          => '0',                                -- (terminated)
         chainout_round        => '0',                                -- (terminated)
         output_saturate       => '0',                                -- (terminated)
         chainout_saturate     => '0',                                -- (terminated)
         chainout_sat_overflow => open,                               -- (terminated)
         zero_chainout         => '0',                                -- (terminated)
         rotate                => '0',                                -- (terminated)
         shift_right           => '0',                                -- (terminated)
         zero_loopback         => '0',                                -- (terminated)
         signa                 => '0',                                -- (terminated)
         signb                 => '0',                                -- (terminated)
         addnsub1              => '1',                                -- (terminated)
         addnsub3              => '1',                                -- (terminated)
         clock1                => '1',                                -- (terminated)
         clock2                => '1',                                -- (terminated)
         clock3                => '1',                                -- (terminated)
         ena0                  =>  enable,
         ena1                  => '1',                                -- (terminated)
         ena2                  => '1',                                -- (terminated)
         ena3                  => '1',                                -- (terminated)
         aclr1                 => '0',                                -- (terminated)
         aclr2                 => '0',                                -- (terminated)
         aclr3                 => '0',                                -- (terminated)
         scanina               => (others => '0'),                    -- (terminated)
         scanouta              => open,                               -- (terminated)
         coefsel0              => (others => '0'),                    -- (terminated)
         coefsel1              => (others => '0'),                    -- (terminated)
         coefsel2              => (others => '0'),                    -- (terminated)
         coefsel3              => (others => '0'),                    -- (terminated)
         datac                 => (others => '0'),                    -- (terminated)
         accum_sload           => '0',                                -- (terminated)
         sload_accum           => '0',                                -- (terminated)
         chainin               => open                                -- (terminated)
      );

      third_ma : component altera_mult_add
      generic map (
         number_of_multipliers             => 1,
         width_a                           => DATAWIDTH_g,
         width_b                           => TWIDWIDTH_g,
         width_result                      => DATAWIDTH_g+TWIDWIDTH_g,
         output_register                   => "CLOCK0",
         output_aclr                       => "ACLR0",
         multiplier1_direction             => "ADD",
         port_addnsub1                     => "PORT_UNUSED",
         addnsub_multiplier_register1      => "UNREGISTERED",
         addnsub_multiplier_aclr1          => "NONE",
         multiplier3_direction             => "ADD",
         port_addnsub3                     => "PORT_UNUSED",
         addnsub_multiplier_register3      => "UNREGISTERED",
         addnsub_multiplier_aclr3          => "NONE",
         representation_a                  => "SIGNED",
         port_signa                        => "PORT_UNUSED",
         signed_register_a                 => "UNREGISTERED",
         signed_aclr_a                     => "NONE",
         port_signb                        => "PORT_UNUSED",
         representation_b                  => "SIGNED",
         signed_register_b                 => "UNREGISTERED",
         signed_aclr_b                     => "NONE",
         input_register_a0                 => "CLOCK0",
         input_register_a1                 => "CLOCK0",
         input_register_a2                 => "UNREGISTERED",
         input_register_a3                 => "UNREGISTERED",
         input_aclr_a0                     => "ACLR0",
         input_aclr_a1                     => "ACLR0",
         input_aclr_a2                     => "NONE",
         input_aclr_a3                     => "NONE",
         input_register_b0                 => "CLOCK0",
         input_register_b1                 => "CLOCK0",
         input_register_b2                 => "UNREGISTERED",
         input_register_b3                 => "UNREGISTERED",
         input_aclr_b0                     => "ACLR0",
         input_aclr_b1                     => "ACLR0",
         input_aclr_b2                     => "NONE",
         input_aclr_b3                     => "NONE",
         scanouta_register                 => "UNREGISTERED",
         scanouta_aclr                     => "NONE",
         input_source_a0                   => "DATAA",
         input_source_a1                   => "DATAA",
         input_source_a2                   => "DATAA",
         input_source_a3                   => "DATAA",
         input_source_b0                   => "DATAB",
         input_source_b1                   => "DATAB",
         input_source_b2                   => "DATAB",
         input_source_b3                   => "DATAB",
         multiplier_register0              => "UNREGISTERED",
         multiplier_register1              => "UNREGISTERED",
         multiplier_register2              => "UNREGISTERED",
         multiplier_register3              => "UNREGISTERED",
         multiplier_aclr0                  => "NONE",
         multiplier_aclr1                  => "NONE",
         multiplier_aclr2                  => "NONE",
         multiplier_aclr3                  => "NONE",
         preadder_mode                     => "SIMPLE",
         preadder_direction_0              => "ADD",
         preadder_direction_1              => "ADD",
         preadder_direction_2              => "ADD",
         preadder_direction_3              => "ADD",
         width_c                           => 16,
         input_register_c0                 => "UNREGISTERED",
         input_register_c1                 => "UNREGISTERED",
         input_register_c2                 => "UNREGISTERED",
         input_register_c3                 => "UNREGISTERED",
         input_aclr_c0                     => "NONE",
         input_aclr_c1                     => "NONE",
         input_aclr_c2                     => "NONE",
         input_aclr_c3                     => "NONE",
         accumulator                       => "NO",
         accum_direction                   => "ADD",
         use_sload_accum_port              => "NO",
         loadconst_value                   => 64,
         accum_sload_register              => "UNREGISTERED",
         accum_sload_aclr                  => "NONE",
         double_accum                      => "NO",
         width_chainin                     => 1,
         chainout_adder                    => "NO",
         systolic_delay1                   => "UNREGISTERED",
         systolic_aclr1                    => "NONE",
         systolic_delay3                   => "UNREGISTERED",
         systolic_aclr3                    => "NONE",
         latency                           => LATENCY_ADDED_c,
         input_a0_latency_clock            => "CLOCK0",
         input_a1_latency_clock            => "CLOCK0",
         input_a2_latency_clock            => "UNREGISTERED",
         input_a3_latency_clock            => "UNREGISTERED",
         input_a0_latency_aclr             => "ACLR0",
         input_a1_latency_aclr             => "ACLR0",
         input_a2_latency_aclr             => "NONE",
         input_a3_latency_aclr             => "NONE",
         input_b0_latency_clock            => "CLOCK0",
         input_b1_latency_clock            => "CLOCK0",
         input_b2_latency_clock            => "UNREGISTERED",
         input_b3_latency_clock            => "UNREGISTERED",
         input_b0_latency_aclr             => "ACLR0",
         input_b1_latency_aclr             => "ACLR0",
         input_b2_latency_aclr             => "NONE",
         input_b3_latency_aclr             => "NONE",
         input_c0_latency_clock            => "UNREGISTERED",
         input_c1_latency_clock            => "UNREGISTERED",
         input_c2_latency_clock            => "UNREGISTERED",
         input_c3_latency_clock            => "UNREGISTERED",
         input_c0_latency_aclr             => "NONE",
         input_c1_latency_aclr             => "NONE",
         input_c2_latency_aclr             => "NONE",
         input_c3_latency_aclr             => "NONE",
         coefsel0_latency_clock            => "UNREGISTERED",
         coefsel1_latency_clock            => "UNREGISTERED",
         coefsel2_latency_clock            => "UNREGISTERED",
         coefsel3_latency_clock            => "UNREGISTERED",
         coefsel0_latency_aclr             => "NONE",
         coefsel1_latency_aclr             => "NONE",
         coefsel2_latency_aclr             => "NONE",
         coefsel3_latency_aclr             => "NONE",
         signed_latency_clock_a            => "UNREGISTERED",
         signed_latency_aclr_a             => "NONE",
         signed_latency_clock_b            => "UNREGISTERED",
         signed_latency_aclr_b             => "NONE",
         addnsub_multiplier_latency_clock1 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr1  => "NONE",
         addnsub_multiplier_latency_clock3 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr3  => "NONE",
         accum_sload_latency_clock         => "UNREGISTERED",
         accum_sload_latency_aclr          => "NONE",
         selected_device_family            => DEVICE_FAMILY_g
      )
      port map (
         result                => dr_ti,                             --  result.result
         dataa                 => dr_del_0,
         datab                 => ti_del_0,
         clock0                => clk,                             --  clock0.clk
         aclr0                 => reset,                              --  aclr0.aclr0
         scaninb               => (others => '0'),                    -- (terminated)
         sourcea               => (others => '0'),                    -- (terminated)
         sourceb               => (others => '0'),                    -- (terminated)
         scanoutb              => open,                               -- (terminated)
         mult01_round          => '0',                                -- (terminated)
         mult23_round          => '0',                                -- (terminated)
         mult01_saturation     => '0',                                -- (terminated)
         mult23_saturation     => '0',                                -- (terminated)
         addnsub1_round        => '0',                                -- (terminated)
         addnsub3_round        => '0',                                -- (terminated)
         mult0_is_saturated    => open,                               -- (terminated)
         mult1_is_saturated    => open,                               -- (terminated)
         mult2_is_saturated    => open,                               -- (terminated)
         mult3_is_saturated    => open,                               -- (terminated)
         output_round          => '0',                                -- (terminated)
         chainout_round        => '0',                                -- (terminated)
         output_saturate       => '0',                                -- (terminated)
         chainout_saturate     => '0',                                -- (terminated)
         chainout_sat_overflow => open,                               -- (terminated)
         zero_chainout         => '0',                                -- (terminated)
         rotate                => '0',                                -- (terminated)
         shift_right           => '0',                                -- (terminated)
         zero_loopback         => '0',                                -- (terminated)
         signa                 => '0',                                -- (terminated)
         signb                 => '0',                                -- (terminated)
         addnsub1              => '1',                                -- (terminated)
         addnsub3              => '1',                                -- (terminated)
         clock1                => '1',                                -- (terminated)
         clock2                => '1',                                -- (terminated)
         clock3                => '1',                                -- (terminated)
         ena0                  =>  enable,
         ena1                  => '1',                                -- (terminated)
         ena2                  => '1',                                -- (terminated)
         ena3                  => '1',                                -- (terminated)
         aclr1                 => '0',                                -- (terminated)
         aclr2                 => '0',                                -- (terminated)
         aclr3                 => '0',                                -- (terminated)
         scanina               => (others => '0'),                    -- (terminated)
         scanouta              => open,                               -- (terminated)
         coefsel0              => (others => '0'),                    -- (terminated)
         coefsel1              => (others => '0'),                    -- (terminated)
         coefsel2              => (others => '0'),                    -- (terminated)
         coefsel3              => (others => '0'),                    -- (terminated)
         datac                 => (others => '0'),                    -- (terminated)
         accum_sload           => '0',                                -- (terminated)
         sload_accum           => '0',                                -- (terminated)
         chainin               => open                                -- (terminated)
      );

      fourth_ma : component altera_mult_add
      generic map (
         number_of_multipliers             => 1,
         width_a                           => DATAWIDTH_g,
         width_b                           => TWIDWIDTH_g,
         width_result                      => DATAWIDTH_g+TWIDWIDTH_g,
         output_register                   => "CLOCK0",
         output_aclr                       => "ACLR0",
         multiplier1_direction             => "ADD",
         port_addnsub1                     => "PORT_UNUSED",
         addnsub_multiplier_register1      => "UNREGISTERED",
         addnsub_multiplier_aclr1          => "NONE",
         multiplier3_direction             => "ADD",
         port_addnsub3                     => "PORT_UNUSED",
         addnsub_multiplier_register3      => "UNREGISTERED",
         addnsub_multiplier_aclr3          => "NONE",
         representation_a                  => "SIGNED",
         port_signa                        => "PORT_UNUSED",
         signed_register_a                 => "UNREGISTERED",
         signed_aclr_a                     => "NONE",
         port_signb                        => "PORT_UNUSED",
         representation_b                  => "SIGNED",
         signed_register_b                 => "UNREGISTERED",
         signed_aclr_b                     => "NONE",
         input_register_a0                 => "CLOCK0",
         input_register_a1                 => "CLOCK0",
         input_register_a2                 => "UNREGISTERED",
         input_register_a3                 => "UNREGISTERED",
         input_aclr_a0                     => "ACLR0",
         input_aclr_a1                     => "ACLR0",
         input_aclr_a2                     => "NONE",
         input_aclr_a3                     => "NONE",
         input_register_b0                 => "CLOCK0",
         input_register_b1                 => "CLOCK0",
         input_register_b2                 => "UNREGISTERED",
         input_register_b3                 => "UNREGISTERED",
         input_aclr_b0                     => "ACLR0",
         input_aclr_b1                     => "ACLR0",
         input_aclr_b2                     => "NONE",
         input_aclr_b3                     => "NONE",
         scanouta_register                 => "UNREGISTERED",
         scanouta_aclr                     => "NONE",
         input_source_a0                   => "DATAA",
         input_source_a1                   => "DATAA",
         input_source_a2                   => "DATAA",
         input_source_a3                   => "DATAA",
         input_source_b0                   => "DATAB",
         input_source_b1                   => "DATAB",
         input_source_b2                   => "DATAB",
         input_source_b3                   => "DATAB",
         multiplier_register0              => "UNREGISTERED",
         multiplier_register1              => "UNREGISTERED",
         multiplier_register2              => "UNREGISTERED",
         multiplier_register3              => "UNREGISTERED",
         multiplier_aclr0                  => "NONE",
         multiplier_aclr1                  => "NONE",
         multiplier_aclr2                  => "NONE",
         multiplier_aclr3                  => "NONE",
         preadder_mode                     => "SIMPLE",
         preadder_direction_0              => "ADD",
         preadder_direction_1              => "ADD",
         preadder_direction_2              => "ADD",
         preadder_direction_3              => "ADD",
         width_c                           => 16,
         input_register_c0                 => "UNREGISTERED",
         input_register_c1                 => "UNREGISTERED",
         input_register_c2                 => "UNREGISTERED",
         input_register_c3                 => "UNREGISTERED",
         input_aclr_c0                     => "NONE",
         input_aclr_c1                     => "NONE",
         input_aclr_c2                     => "NONE",
         input_aclr_c3                     => "NONE",
         accumulator                       => "NO",
         accum_direction                   => "ADD",
         use_sload_accum_port              => "NO",
         loadconst_value                   => 64,
         accum_sload_register              => "UNREGISTERED",
         accum_sload_aclr                  => "NONE",
         double_accum                      => "NO",
         width_chainin                     => 1,
         chainout_adder                    => "NO",
         systolic_delay1                   => "UNREGISTERED",
         systolic_aclr1                    => "NONE",
         systolic_delay3                   => "UNREGISTERED",
         systolic_aclr3                    => "NONE",
         latency                           => LATENCY_ADDED_c,
         input_a0_latency_clock            => "CLOCK0",
         input_a1_latency_clock            => "CLOCK0",
         input_a2_latency_clock            => "UNREGISTERED",
         input_a3_latency_clock            => "UNREGISTERED",
         input_a0_latency_aclr             => "ACLR0",
         input_a1_latency_aclr             => "ACLR0",
         input_a2_latency_aclr             => "NONE",
         input_a3_latency_aclr             => "NONE",
         input_b0_latency_clock            => "CLOCK0",
         input_b1_latency_clock            => "CLOCK0",
         input_b2_latency_clock            => "UNREGISTERED",
         input_b3_latency_clock            => "UNREGISTERED",
         input_b0_latency_aclr             => "ACLR0",
         input_b1_latency_aclr             => "ACLR0",
         input_b2_latency_aclr             => "NONE",
         input_b3_latency_aclr             => "NONE",
         input_c0_latency_clock            => "UNREGISTERED",
         input_c1_latency_clock            => "UNREGISTERED",
         input_c2_latency_clock            => "UNREGISTERED",
         input_c3_latency_clock            => "UNREGISTERED",
         input_c0_latency_aclr             => "NONE",
         input_c1_latency_aclr             => "NONE",
         input_c2_latency_aclr             => "NONE",
         input_c3_latency_aclr             => "NONE",
         coefsel0_latency_clock            => "UNREGISTERED",
         coefsel1_latency_clock            => "UNREGISTERED",
         coefsel2_latency_clock            => "UNREGISTERED",
         coefsel3_latency_clock            => "UNREGISTERED",
         coefsel0_latency_aclr             => "NONE",
         coefsel1_latency_aclr             => "NONE",
         coefsel2_latency_aclr             => "NONE",
         coefsel3_latency_aclr             => "NONE",
         signed_latency_clock_a            => "UNREGISTERED",
         signed_latency_aclr_a             => "NONE",
         signed_latency_clock_b            => "UNREGISTERED",
         signed_latency_aclr_b             => "NONE",
         addnsub_multiplier_latency_clock1 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr1  => "NONE",
         addnsub_multiplier_latency_clock3 => "UNREGISTERED",
         addnsub_multiplier_latency_aclr3  => "NONE",
         accum_sload_latency_clock         => "UNREGISTERED",
         accum_sload_latency_aclr          => "NONE",
         selected_device_family            => DEVICE_FAMILY_g
      )
      port map (
         result                => di_tr,                             --  result.result
         dataa                 => di_del_0,
         datab                 => tr_del_0,
         clock0                => clk,                             --  clock0.clk
         aclr0                 => reset,                              --  aclr0.aclr0
         scaninb               => (others => '0'),                    -- (terminated)
         sourcea               => (others => '0'),                    -- (terminated)
         sourceb               => (others => '0'),                    -- (terminated)
         scanoutb              => open,                               -- (terminated)
         mult01_round          => '0',                                -- (terminated)
         mult23_round          => '0',                                -- (terminated)
         mult01_saturation     => '0',                                -- (terminated)
         mult23_saturation     => '0',                                -- (terminated)
         addnsub1_round        => '0',                                -- (terminated)
         addnsub3_round        => '0',                                -- (terminated)
         mult0_is_saturated    => open,                               -- (terminated)
         mult1_is_saturated    => open,                               -- (terminated)
         mult2_is_saturated    => open,                               -- (terminated)
         mult3_is_saturated    => open,                               -- (terminated)
         output_round          => '0',                                -- (terminated)
         chainout_round        => '0',                                -- (terminated)
         output_saturate       => '0',                                -- (terminated)
         chainout_saturate     => '0',                                -- (terminated)
         chainout_sat_overflow => open,                               -- (terminated)
         zero_chainout         => '0',                                -- (terminated)
         rotate                => '0',                                -- (terminated)
         shift_right           => '0',                                -- (terminated)
         zero_loopback         => '0',                                -- (terminated)
         signa                 => '0',                                -- (terminated)
         signb                 => '0',                                -- (terminated)
         addnsub1              => '1',                                -- (terminated)
         addnsub3              => '1',                                -- (terminated)
         clock1                => '1',                                -- (terminated)
         clock2                => '1',                                -- (terminated)
         clock3                => '1',                                -- (terminated)
         ena0                  =>  enable,
         ena1                  => '1',                                -- (terminated)
         ena2                  => '1',                                -- (terminated)
         ena3                  => '1',                                -- (terminated)
         aclr1                 => '0',                                -- (terminated)
         aclr2                 => '0',                                -- (terminated)
         aclr3                 => '0',                                -- (terminated)
         scanina               => (others => '0'),                    -- (terminated)
         scanouta              => open,                               -- (terminated)
         coefsel0              => (others => '0'),                    -- (terminated)
         coefsel1              => (others => '0'),                    -- (terminated)
         coefsel2              => (others => '0'),                    -- (terminated)
         coefsel3              => (others => '0'),                    -- (terminated)
         datac                 => (others => '0'),                    -- (terminated)
         accum_sload           => '0',                                -- (terminated)
         sload_accum           => '0',                                -- (terminated)
         chainin               => open                                -- (terminated)
      );

      real_in_a <= std_logic_vector(resize(signed(dr_tr_del),DATAWIDTH_g + TWIDWIDTH_g + 1));
      real_in_b <= std_logic_vector(resize(signed(di_ti_del),DATAWIDTH_g + TWIDWIDTH_g + 1));
      imag_in_a <= std_logic_vector(resize(signed(di_tr_del),DATAWIDTH_g + TWIDWIDTH_g + 1));
      imag_in_b <= std_logic_vector(resize(signed(dr_ti_del),DATAWIDTH_g + TWIDWIDTH_g + 1));
      real_sum : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 3,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '0',
          dataa  => real_in_a,
          datab  => real_in_b,
          result => real_res);

      imag_sum : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 3,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => imag_in_a,
          datab  => imag_in_b,
          result => imag_res);

        
    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => real_result(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundrealff
      );

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => imag_result(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimagff
      );










    end generate large_mult;

  end generate  A10_C_Mult_Archs;



  NONA10_C_Mult_Archs : if not(DEVICE_FAMILY_g = "Arria 10") generate

  -----------------------------------------------------------------------------
  -- SMALL MULTIPLIER, WHEN BOTH DATA AND TWIDDLE ARE <= 18
  -- Rounding done external to the DSP block.
  -----------------------------------------------------------------------------
  gen_small_mult : if MULT_18_X_18 and DSP_ROUNDING_g = 0 generate
    signal in_real_d : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_d : std_logic_vector(DATAWIDTH_g - 1 downto 0);

    signal real_mult_data_in : std_logic_vector(2*DATAWIDTH_g - 1 downto 0);
    signal real_mult_twid_in : std_logic_vector(2*TWIDWIDTH_g - 1 downto 0);

    signal imag_mult_data_in : std_logic_vector(2*DATAWIDTH_g - 1 downto 0);
    signal imag_mult_twid_in : std_logic_vector(2*TWIDWIDTH_g - 1 downto 0);

    signal real_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal imag_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal real_result_tmp : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal imag_result_tmp : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);

    signal roundreal : std_logic_vector(DATAWIDTH_g + GROW_g  - 1 downto 0);
    signal roundimag : std_logic_vector(DATAWIDTH_g + GROW_g  - 1 downto 0);
    signal in_real_dd : std_logic_vector(DATAWIDTH_g -1 downto 0);
    signal in_imag_dd : std_logic_vector(DATAWIDTH_g -1 downto 0);
    begin

    -- if optimize_mem = 1, then twiddles come 1 cycle later, so no need to
    -- delay the data, no change in overall pipeline latency

      -- register input data to align with twiddles
      delay_data_p : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            in_real_dd <= (others => '0');
            in_imag_dd <= (others => '0');
            in_real_d  <= (others => '0');
            in_imag_d  <= (others => '0');
          elsif enable = '1' then
            in_real_dd <= in_real_std;
            in_imag_dd <= in_imag_std;
            in_imag_d  <= in_imag_dd;
            in_real_d  <= in_real_dd;
          end if;
        end if;
      end process delay_data_p;


    real_mult_data_in <= in_imag_d & in_real_d;
    real_mult_twid_in <= imagtwid_std & realtwid_std;

    MULT_ADD_real : altera_fft_mult_add
      generic map (
        selected_device_family                => DEVICE_FAMILY_g,
        multiplier1_direction                 => "SUB",
        number_of_multipliers                 => 2,
        width_a                               => DATAWIDTH_g,
        width_b                               => TWIDWIDTH_g,
        width_result                          => DATAWIDTH_g + TWIDWIDTH_g + 1
        )
      port map (
        dataa  => real_mult_data_in,
        datab  => real_mult_twid_in,
        clock0 => clk,
        aclr0  => reset,
        ena0   => enable,
        result => real_result_tmp
        );

    imag_mult_data_in <= in_imag_d & in_real_d;
    imag_mult_twid_in <= realtwid_std & imagtwid_std;


    MULT_ADD_imag : altera_fft_mult_add
      generic map (
        selected_device_family                => DEVICE_FAMILY_g,
        multiplier1_direction                 => "ADD",
        number_of_multipliers                 => 2,
        width_a                               => DATAWIDTH_g,
        width_b                               => TWIDWIDTH_g,
        width_result                          => DATAWIDTH_g + TWIDWIDTH_g + 1
        )
      port map (
        dataa  => imag_mult_data_in,
        datab  => imag_mult_twid_in,
        clock0 => clk,
        aclr0  => reset,
        ena0   => enable,
        result => imag_result_tmp
        );

    -- register here for timing purposes
    reg_intermediate : process (clk)
    begin  -- process fwqe
      if rising_edge(clk) then
        if reset = '1' then
          imag_result <= (others => '0');
          real_result <= (others => '0');
        elsif enable = '1' then
          real_result <= real_result_tmp;
          imag_result <= imag_result_tmp;
        end if;
      end if;
    end process reg_intermediate;
    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => real_result(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundreal);

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => imag_result(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimag);

    roundrealff <= roundreal;
    roundimagff <= roundimag;

    
  end generate gen_small_mult;

  -----------------------------------------------------------------------------
  -- MULTIPLIER WITH ROUNDING - uses the rounding block available in the
  -- stratix III. Not available for other device families, sign extends the
  -- inputs to perform correct dsp rounding
  -----------------------------------------------------------------------------
  gen_mult_rounded_sx : if DSP_ROUNDING_g = 1 and MULT_18_X_18 generate

    constant DSP_ELEMENT_SIZE_c : natural := 18;


    signal in_real_extended : std_logic_vector(DSP_ELEMENT_SIZE_c - 1 downto 0);
    signal in_imag_extended : std_logic_vector(DSP_ELEMENT_SIZE_c - 1 downto 0);

    signal realtwid_extended : std_logic_vector(DSP_ELEMENT_SIZE_c - 1 downto 0);
    signal imagtwid_extended : std_logic_vector(DSP_ELEMENT_SIZE_c - 1 downto 0);

    signal real_mult_data_in : std_logic_vector(2*DSP_ELEMENT_SIZE_c - 1 downto 0);
    signal real_mult_twid_in : std_logic_vector(2*DSP_ELEMENT_SIZE_c - 1 downto 0);

    signal imag_mult_data_in : std_logic_vector(2*DSP_ELEMENT_SIZE_c - 1 downto 0);
    signal imag_mult_twid_in : std_logic_vector(2*DSP_ELEMENT_SIZE_c - 1 downto 0);

    signal real_result : std_logic_vector(2*DSP_ELEMENT_SIZE_c downto 0);
    signal imag_result : std_logic_vector(2*DSP_ELEMENT_SIZE_c downto 0);

  begin

    -- if optimize mem, then twiddles come 1 cycle later, so delay the data,
    -- overall latency increased by 1.
      delay_input_data : process (clk)
      begin  -- process delay_input_data
        if rising_edge(clk) then
          if reset = '1' then
            in_real_extended <= (others => '0');
            in_imag_extended <= (others => '0');
          elsif enable = '1' then
            in_real_extended <= std_logic_vector(resize(signed(in_real_std), DSP_ELEMENT_SIZE_c));
            in_imag_extended <= std_logic_vector(resize(signed(in_imag_std), DSP_ELEMENT_SIZE_c));
          end if;
        end if;
      end process delay_input_data;




    realtwid_extended <= std_logic_vector(resize(signed(realtwid_std), DSP_ELEMENT_SIZE_c));
    imagtwid_extended <= std_logic_vector(resize(signed(imagtwid_std), DSP_ELEMENT_SIZE_c));

    real_mult_data_in <= in_imag_extended & in_real_extended;
    real_mult_twid_in <= imagtwid_extended & realtwid_extended;

    real_mult : altera_fft_mult_add
      generic map (
        selected_device_family                => DEVICE_FAMILY_g,
        multiplier1_direction                 => "SUB",
        number_of_multipliers                 => 2,
        width_a                               => DSP_ELEMENT_SIZE_c,
        width_b                               => DSP_ELEMENT_SIZE_c,
        width_result                          => DSP_ELEMENT_SIZE_c*2 + 1
        )
      port map (
        dataa           => real_mult_data_in,
        datab           => real_mult_twid_in,
        clock0          => clk,
        aclr0           => reset,
        ena0            => enable,
        result          => real_result
        );

    imag_mult_data_in <= in_imag_extended & in_real_extended;
    imag_mult_twid_in <= realtwid_extended & imagtwid_extended;

    imag_mult : altera_fft_mult_add
      generic map (
        selected_device_family                => DEVICE_FAMILY_g,
        multiplier1_direction                 => "ADD",
        number_of_multipliers                 => 2,
        width_a                               => DSP_ELEMENT_SIZE_c,
        width_b                               => DSP_ELEMENT_SIZE_c,
        width_result                          => 2*DSP_ELEMENT_SIZE_c + 1
        )
      port map (
        dataa           => imag_mult_data_in,
        datab           => imag_mult_twid_in,
        clock0          => clk,
        aclr0           => reset,
        ena0            => enable,
        result          => imag_result
        );

    ---------------------------------------------------------------------------
    -- take the relevant bits of the output result (dont have to worry about
    -- the extra bit X from the addition as the twiddle values will never cause
    -- an overflow into that bit)
    --
    -- <- 2*DSP_ELT_SIZE -
    --              DATAWIDTH-TWIDWIDTH ->  X   <-  DATAWIDTH   -> <- TWIDWIDTH-->
    -- |----------------------------------|----|------------------|--------------|
    --                         WIDTH_RESULT = 2*DSP_ELT_SIZE +1
    -- <------------------------------------------------------------------------->
    --  WIDTH_SATURATE_SIGN=2*DSP_ELT_SIZE+1 -
    --                  DATAWIDTH_g - TWIDWIDTH_g
    -- <-------------------------------------->
    --  WIDTH_MSB = 2*DSP_ELT_SIZE +1
    -- <---------------------------------------------------------->
    --                                         OUTPUT RESULT
    --                                         <------------------>
    ---------------------------------------------------------------------------

    
    roundrealff <= std_logic_vector(resize(unsigned(real_result(real_result'high) & real_result(DATAWIDTH_g + TWIDWIDTH_g - 1 downto TWIDWIDTH_g -1)), DATAWIDTH_g + GROW_g ));
    roundimagff <= std_logic_vector(resize(unsigned(imag_result(imag_result'high) & imag_result(DATAWIDTH_g + TWIDWIDTH_g - 1 downto TWIDWIDTH_g -1)), DATAWIDTH_g + GROW_g ));

    
  end generate gen_mult_rounded_sx;



  -----------------------------------------------------------------------------
  -- LARGE MULTIPLIER - WHEN ONE OR BOTH OPERANDS > 18. This is more efficient
  -- than the direct instantiation of the alt_mult_add which requires 4*8 dsp 9 -
  -- bit elements (for stratix II). This only requires 4*4
  -- For Arria V where data between 28 and 36 bits and twiddle below 18 bits.
  -- 4 multiplier implementation requires 8 dsp blocks, and 3 multiplier implementation
  -- requires 6 dsp blocks. This only requires 4 dsp blocks.
  -----------------------------------------------------------------------------
  gen_large_mult1 : if not MULT_18_X_18 and ((DSP_ARCH_g = 0 and DATAWIDTH_g >= TWIDWIDTH_g) or MULT_AV_D27_TO_D38_X_T18 or MULT_SV_OPT_D37_AND_OVER) generate

    signal in_real_d  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_d  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal realtwid_d : std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    signal imagtwid_d : std_logic_vector(TWIDWIDTH_g - 1 downto 0);

    constant HALFWIDTH_c : positive := DATAWIDTH_g / 2;
    constant HIWIDTH_c   : positive := DATAWIDTH_g - HALFWIDTH_c;
    constant LOWWIDTH_c  : positive := HALFWIDTH_c + 1;

    -- signal outtestff : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g - 1 downto 0);

    signal in_real_l : std_logic_vector (HALFWIDTH_c downto 0);
    signal in_real_h : std_logic_vector (DATAWIDTH_g - HALFWIDTH_c - 1 downto 0);
    signal in_imag_l : std_logic_vector (HALFWIDTH_c downto 0);
    signal in_imag_h : std_logic_vector (DATAWIDTH_g - HALFWIDTH_c - 1 downto 0);

    -- size  = HALFWIDTH_c + 1 (zero extend) + TWIDWIDTH_g
    signal XA_l : std_logic_vector (HALFWIDTH_c + TWIDWIDTH_g downto 0);
    -- size = HIWIDTH_c + TWIDWIDTH_g
    signal XA_h : std_logic_vector (HIWIDTH_c + TWIDWIDTH_g - 1 downto 0);
    signal YB_l : std_logic_vector (HALFWIDTH_c + TWIDWIDTH_g downto 0);
    signal YB_h : std_logic_vector (HIWIDTH_c + TWIDWIDTH_g - 1 downto 0);
    signal XB_l : std_logic_vector (HALFWIDTH_c + TWIDWIDTH_g downto 0);
    signal XB_h : std_logic_vector (HIWIDTH_c + TWIDWIDTH_g - 1 downto 0);
    signal YA_l : std_logic_vector (HALFWIDTH_c + TWIDWIDTH_g downto 0);
    signal YA_h : std_logic_vector (HIWIDTH_c + TWIDWIDTH_g - 1 downto 0);

    -- size = HALFWIDTH_c + 1 + TWIDWIDTH_g (no growth needed as extended in XA_l
    signal subpart_l : std_logic_vector (HALFWIDTH_c + TWIDWIDTH_g downto 0);
    -- size = HIWIDTH_c + TWIDWIDTH_g + 1 
    signal subpart_h : std_logic_vector (HIWIDTH_c + TWIDWIDTH_g downto 0);
    signal addpart_l : std_logic_vector (HALFWIDTH_c + TWIDWIDTH_g downto 0);
    signal addpart_h : std_logic_vector (HIWIDTH_c + TWIDWIDTH_g downto 0);

    -- resized and sign extended versions
    signal subpart_l_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal subpart_h_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal addpart_l_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal addpart_h_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);

    -- size=HIWIDTH_c + TWIDWIDTH_g + 1 + HALFWIDTH_c = DATAWIDTH_g + TWIDWIDTH_g + 1 
    signal submultff : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal addmultff : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    
  begin

    -- if memory_opt = 1 , then twiddles arrive 1 cycle later, so delay the
    -- input data, overall latency increases by 1
      
      delay_data : process (clk)
      begin  -- process delay_data
        if rising_edge(clk) then
          if reset = '1' then
            in_real_d <= (others => '0');
            in_imag_d <= (others => '0');
          elsif enable = '1' then
            in_real_d <= in_real_std;
            in_imag_d <= in_imag_std;
          end if;
        end if;
      end process delay_data;


    realtwid_d <= realtwid_std;
    imagtwid_d <= imagtwid_std;

    -- split data into low and high parts
    split_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          in_real_l <= (others => '0');
          in_real_h <= (others => '0');
          in_imag_l <= (others => '0');
          in_imag_h <= (others => '0');
        elsif enable = '1' then
          in_real_l <= '0' & in_real_d(HALFWIDTH_c - 1 downto 0);
          in_real_h <= in_real_d(DATAWIDTH_g - 1 downto HALFWIDTH_c);
          in_imag_l <= '0' & in_imag_d(HALFWIDTH_c - 1 downto 0);
          in_imag_h <= in_imag_d(DATAWIDTH_g - 1 downto HALFWIDTH_c);
        end if;
      end if;
    end process split_p;

    ---------------------------------------------------------------------------
    -- Calculation is split into low and high parts so that the adders in the
    -- DSP block can be utilised.

    ---------------------------------------------------------------------------
    -- XA - YB
    -- real part XA - YB = realin*realtwid - imagin*imagtwid
    -- ie XA - YB =  XA_l(sign ext) + XA_h(shift_right) -  (YB_l(sign ext) + YB_h(shift_left)
    --            = (XA_l - YB_l)(sign ext) + (XA_h + YB_h)(shift_left)
    ---------------------------------------------------------------------------

    calc_parts_real_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          XA_l <= (others => '0');
          XA_h <= (others => '0');
          YB_l <= (others => '0');
          YB_h <= (others => '0');
        elsif enable = '1' then
          XA_l <= std_logic_vector(signed(in_real_l)*signed(realtwid_d));
          XA_h <= std_logic_vector(signed(in_real_h)*signed(realtwid_d));
          YB_l <= std_logic_vector(signed(in_imag_l)*signed(imagtwid_d));
          YB_h <= std_logic_vector(signed(in_imag_h)*signed(imagtwid_d));
        end if;
      end if;
    end process calc_parts_real_p;

    ---------------------------------------------------------------------------
    -- XB + YA = realin*imagtwid + imagin*realtwid
    -- imaginary part 
    -- ie XB + YA =  XB_l(sign ext) + XB_h(shift_right) + (YA_l(sign ext) + YA_h(shift_left)
    --            = (XB_l + YA_l)(sign ext) + (XB_h + YA_h)(shift_left)
    ---------------------------------------------------------------------------
    calc_parts_imag_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
        XB_l <= (others => '0');
        XB_h <= (others => '0');
        YA_l <= (others => '0');
        YA_h <= (others => '0');
      elsif enable = '1' then
          XB_l <= std_logic_vector(signed(in_real_l)*signed(imagtwid_d));
          XB_h <= std_logic_vector(signed(in_real_h)*signed(imagtwid_d));
          YA_l <= std_logic_vector(signed(in_imag_l)*signed(realtwid_d));
          YA_h <= std_logic_vector(signed(in_imag_h)*signed(realtwid_d));
        end if;
      end if;
    end process calc_parts_imag_p;


    -- perform additionand subtractions on parts
    -- The adder in the DSP block is used here because the size of the operands
    -- are the same.
    -- XA_l - YB_l
    -- XA_h - YB_h
    -- XB_l + YA_l
    -- XB_h + YA_h
    add_parts_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          subpart_l <= (others => '0');
          subpart_h <= (others => '0');
          addpart_l <= (others => '0');
          addpart_h <= (others => '0');
        elsif enable = '1' then
          subpart_l <= std_logic_vector(signed(XA_l) - signed(YB_l));
          subpart_h <= std_logic_vector(resize(signed(XA_h), subpart_h'length) -
                                        resize(signed(YB_h), subpart_h'length));
          addpart_l <= std_logic_vector(signed(XB_l) + signed(YA_l));
          addpart_h <= std_logic_vector(resize(signed(XB_h), addpart_h'length) +
                                        resize(signed(YA_h), addpart_h'length));
        end if;
      end if;
    end process add_parts_p;


    ---------------------------------------------------------------------------
    -- perform final addition.
    -- This can be done either by using a pipelined adder (larger resources, faster)
    -- or the regular adder.
    -- Not sure why, but using addsub with a latency of 1 does not produce as
    -- good timing results as the inferred adder.
    ---------------------------------------------------------------------------
    gen_fast_adder : if OPTIMIZE_SPEED_g = 1 generate
    begin  -- generate gen_fast_adder

      subpart_h_ext <= std_logic_vector(shift_left(resize(signed(subpart_h), DATAWIDTH_g + TWIDWIDTH_g+1), HALFWIDTH_c));
      subpart_l_ext <= std_logic_vector(resize(signed(subpart_l), DATAWIDTH_g + TWIDWIDTH_g+1));

      add_sub_total : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 2,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => subpart_h_ext,
          datab  => subpart_l_ext,
          result => submultff);

      addpart_h_ext <= std_logic_vector(shift_left(resize(signed(addpart_h), DATAWIDTH_g + TWIDWIDTH_g+1), HALFWIDTH_c));
      addpart_l_ext <= std_logic_vector(resize(signed(addpart_l), DATAWIDTH_g + TWIDWIDTH_g+1));

      add_add_total : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 2,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => addpart_h_ext,
          datab  => addpart_l_ext,
          result => addmultff);
    end generate gen_fast_adder;

    gen_adder : if OPTIMIZE_SPEED_g = 0 generate
    begin

      add_total_p : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            submultff <= (others => '0');
            addmultff <= (others => '0');
          elsif enable = '1' then
            submultff <= std_logic_vector(shift_left(resize(signed(subpart_h), submultff'length), HALFWIDTH_c) +
                                          resize(signed(subpart_l), submultff'length));
            addmultff <= std_logic_vector(shift_left(resize(signed(addpart_h), addmultff'length), HALFWIDTH_c) +
                                          resize(signed(addpart_l), addmultff'length));
          end if;
        end if;
      end process add_total_p;
    end generate gen_adder;


    ---------------------------------------------------------------------------
    -- Round result back down to DATAWIDTH_g.
    -- 
    -- MAX|submultff/addmultff| = DATAWIDTH_g + TWIDWIDTH_g + 1
    -- where twid values range from
    --  -2**(TWIDWIDTH_g - 1) - 1  to  2**(TWIDWIDTH_g - 1) - 1
    --
    -- Therefore the MAX|data*twid| =
    -- (-2**(TWIDWIDTH_g - 1) - 1) * (2**(DATAWIDTH_g - 1))
    -- which can be accommodated in TWIDWIDTH_g - 1 + DATAWIDTH_g bits
    --
    -- The addition subtraction operation makes the total maximum output width
    -- TWIDWIDTH_g - 1 + DATAWIDTH_g + 1 (if we are growing the stage)
    -- TWIDWIDTH_g - 1 + DATAWIDTH_g     (if we are not growing the stage)
    -- 
    -- The scaler works by placing the decimal point at IN_WIDTH_g - OUT_WIDTH_g.
    -- ie after TWIDWIDTH_g - 1.
    --
    -- Rounding is round to 0.
    -- SCALE option can be used to scale result of multiplier. Round to 0.
    ---------------------------------------------------------------------------
    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => submultff(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundrealff);

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => addmultff(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimagff);

    

  end generate gen_large_mult1;

gen_large_mult2 : if not MULT_18_X_18 and ((DSP_ARCH_g = 0 and DATAWIDTH_g < TWIDWIDTH_g)) generate

    signal in_real_d  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_real_d2 : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_d  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_d2 : std_logic_vector(DATAWIDTH_g - 1 downto 0);

    constant HALFWIDTH_c : positive := TWIDWIDTH_g / 2;
    constant HIWIDTH_c   : positive := TWIDWIDTH_g - HALFWIDTH_c;
    constant LOWWIDTH_c  : positive := HALFWIDTH_c + 1;

    -- signal outtestff : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g - 1 downto 0);

    signal realtwid_l : std_logic_vector (HALFWIDTH_c downto 0);
    signal realtwid_h : std_logic_vector (TWIDWIDTH_g - HALFWIDTH_c - 1 downto 0);
    signal imagtwid_l : std_logic_vector (HALFWIDTH_c downto 0);
    signal imagtwid_h : std_logic_vector (TWIDWIDTH_g - HALFWIDTH_c - 1 downto 0);

    -- size  = HALFWIDTH_c + 1 (zero extend) + TWIDWIDTH_g
    signal XA_l : std_logic_vector (HALFWIDTH_c + DATAWIDTH_g downto 0);
    -- size = HIWIDTH_c + TWIDWIDTH_g
    signal XA_h : std_logic_vector (HIWIDTH_c + DATAWIDTH_g - 1 downto 0);
    signal YB_l : std_logic_vector (HALFWIDTH_c + DATAWIDTH_g downto 0);
    signal YB_h : std_logic_vector (HIWIDTH_c + DATAWIDTH_g - 1 downto 0);
    signal XB_l : std_logic_vector (HALFWIDTH_c + DATAWIDTH_g downto 0);
    signal XB_h : std_logic_vector (HIWIDTH_c + DATAWIDTH_g - 1 downto 0);
    signal YA_l : std_logic_vector (HALFWIDTH_c + DATAWIDTH_g downto 0);
    signal YA_h : std_logic_vector (HIWIDTH_c + DATAWIDTH_g - 1 downto 0);

    -- size = HALFWIDTH_c + 1 + TWIDWIDTH_g (no growth needed as extended in XA_l
    signal subpart_l : std_logic_vector (HALFWIDTH_c + DATAWIDTH_g downto 0);
    -- size = HIWIDTH_c + TWIDWIDTH_g + 1 
    signal subpart_h : std_logic_vector (HIWIDTH_c + DATAWIDTH_g downto 0);
    signal addpart_l : std_logic_vector (HALFWIDTH_c + DATAWIDTH_g downto 0);
    signal addpart_h : std_logic_vector (HIWIDTH_c + DATAWIDTH_g downto 0);

    -- resized and sign extended versions
    signal subpart_l_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal subpart_h_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal addpart_l_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal addpart_h_ext : std_logic_vector (DATAWIDTH_g + TWIDWIDTH_g downto 0);

    -- size=HIWIDTH_c + TWIDWIDTH_g + 1 + HALFWIDTH_c = DATAWIDTH_g + TWIDWIDTH_g + 1 
    signal submultff : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal addmultff : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    
  begin

    -- if memory_opt = 1 , then twiddles arrive 1 cycle later, so delay the
    -- input data, overall latency increases by 1
      
      delay_data : process (clk)
      begin  -- process delay_data
        if rising_edge(clk) then
          if reset = '1' then
            in_real_d  <= (others => '0');
            in_real_d2 <= (others => '0');
            in_imag_d  <= (others => '0');
            in_imag_d2 <= (others => '0');
          elsif enable = '1' then
            in_real_d  <= in_real_std;
            in_real_d2 <= in_real_d;
            in_imag_d  <= in_imag_std;
            in_imag_d2 <= in_imag_d;
          end if;
        end if;
      end process delay_data;


    realtwid_l <= '0' & realtwid(HALFWIDTH_c - 1 downto 0);
    realtwid_h <= realtwid(TWIDWIDTH_g - 1 downto HALFWIDTH_c);
    imagtwid_l <= '0' & imagtwid_std(HALFWIDTH_c - 1 downto 0);
    imagtwid_h <= imagtwid_std(TWIDWIDTH_g - 1 downto HALFWIDTH_c);

    ---------------------------------------------------------------------------
    -- Calculation is split into low and high parts so that the adders in the
    -- DSP block can be utilised.

    ---------------------------------------------------------------------------
    -- XA - YB
    -- real part XA - YB = realin*realtwid - imagin*imagtwid
    -- ie XA - YB =  XA_l(sign ext) + XA_h(shift_right) -  (YB_l(sign ext) + YB_h(shift_left)
    --            = (XA_l - YB_l)(sign ext) + (XA_h + YB_h)(shift_left)
    ---------------------------------------------------------------------------

    calc_parts_real_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          XA_l <= (others => '0');
          XA_h <= (others => '0');
          YB_l <= (others => '0');
          YB_h <= (others => '0');
        elsif enable = '1' then
          XA_l <= std_logic_vector(signed(in_real_d2)*signed(realtwid_l));
          XA_h <= std_logic_vector(signed(in_real_d2)*signed(realtwid_h));
          YB_l <= std_logic_vector(signed(in_imag_d2)*signed(imagtwid_l));
          YB_h <= std_logic_vector(signed(in_imag_d2)*signed(imagtwid_h));
        end if;
      end if;
    end process calc_parts_real_p;

    ---------------------------------------------------------------------------
    -- XB + YA = realin*imagtwid + imagin*realtwid
    -- imaginary part 
    -- ie XB + YA =  XB_l(sign ext) + XB_h(shift_right) + (YA_l(sign ext) + YA_h(shift_left)
    --            = (XB_l + YA_l)(sign ext) + (XB_h + YA_h)(shift_left)
    ---------------------------------------------------------------------------
    calc_parts_imag_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          XB_l <= (others => '0');
          XB_h <= (others => '0');
          YA_l <= (others => '0');
          YA_h <= (others => '0');
        elsif enable = '1' then
          XB_l <= std_logic_vector(signed(in_real_d2)*signed(imagtwid_l));
          XB_h <= std_logic_vector(signed(in_real_d2)*signed(imagtwid_h));
          YA_l <= std_logic_vector(signed(in_imag_d2)*signed(realtwid_l));
          YA_h <= std_logic_vector(signed(in_imag_d2)*signed(realtwid_h));
        end if;
      end if;
    end process calc_parts_imag_p;


    -- perform additionand subtractions on parts
    -- The adder in the DSP block is used here because the size of the operands
    -- are the same.
    -- XA_l - YB_l
    -- XA_h - YB_h
    -- XB_l + YA_l
    -- XB_h + YA_h
    add_parts_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          subpart_l <= (others => '0');
          subpart_h <= (others => '0');
          addpart_l <= (others => '0');
          addpart_h <= (others => '0');
        elsif enable = '1' then
          subpart_l <= std_logic_vector(signed(XA_l) - signed(YB_l));
          subpart_h <= std_logic_vector(resize(signed(XA_h), subpart_h'length) -
                                        resize(signed(YB_h), subpart_h'length));
          addpart_l <= std_logic_vector(signed(XB_l) + signed(YA_l));
          addpart_h <= std_logic_vector(resize(signed(XB_h), addpart_h'length) +
                                        resize(signed(YA_h), addpart_h'length));
        end if;
      end if;
    end process add_parts_p;


    ---------------------------------------------------------------------------
    -- perform final addition.
    -- This can be done either by using a pipelined adder (larger resources, faster)
    -- or the regular adder.
    -- Not sure why, but using addsub with a latency of 1 does not produce as
    -- good timing results as the inferred adder.
    ---------------------------------------------------------------------------
    gen_fast_adder : if OPTIMIZE_SPEED_g = 1 generate
    begin  -- generate gen_fast_adder

      subpart_h_ext <= std_logic_vector(shift_left(resize(signed(subpart_h), DATAWIDTH_g + TWIDWIDTH_g+1), HALFWIDTH_c));
      subpart_l_ext <= std_logic_vector(resize(signed(subpart_l), DATAWIDTH_g + TWIDWIDTH_g+1));

      add_sub_total : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 2,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => subpart_h_ext,
          datab  => subpart_l_ext,
          result => submultff);

      addpart_h_ext <= std_logic_vector(shift_left(resize(signed(addpart_h), DATAWIDTH_g + TWIDWIDTH_g+1), HALFWIDTH_c));
      addpart_l_ext <= std_logic_vector(resize(signed(addpart_l), DATAWIDTH_g + TWIDWIDTH_g+1));

      add_add_total : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g + TWIDWIDTH_g+1,
          PIPELINE_g  => 2,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => addpart_h_ext,
          datab  => addpart_l_ext,
          result => addmultff);
    end generate gen_fast_adder;

    gen_adder : if OPTIMIZE_SPEED_g = 0 generate
    begin

      add_total_p : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            submultff <= (others => '0');
            addmultff <= (others => '0');
          elsif enable = '1' then
            submultff <= std_logic_vector(shift_left(resize(signed(subpart_h), submultff'length), HALFWIDTH_c) +
                                          resize(signed(subpart_l), submultff'length));
            addmultff <= std_logic_vector(shift_left(resize(signed(addpart_h), addmultff'length), HALFWIDTH_c) +
                                          resize(signed(addpart_l), addmultff'length));
          end if;
        end if;
      end process add_total_p;
    end generate gen_adder;


    ---------------------------------------------------------------------------
    -- Round result back down to DATAWIDTH_g.
    -- 
    -- MAX|submultff/addmultff| = DATAWIDTH_g + TWIDWIDTH_g + 1
    -- where twid values range from
    --  -2**(TWIDWIDTH_g - 1) - 1  to  2**(TWIDWIDTH_g - 1) - 1
    --
    -- Therefore the MAX|data*twid| =
    -- (-2**(TWIDWIDTH_g - 1) - 1) * (2**(DATAWIDTH_g - 1))
    -- which can be accommodated in TWIDWIDTH_g - 1 + DATAWIDTH_g bits
    --
    -- The addition subtraction operation makes the total maximum output width
    -- TWIDWIDTH_g - 1 + DATAWIDTH_g + 1 (if we are growing the stage)
    -- TWIDWIDTH_g - 1 + DATAWIDTH_g     (if we are not growing the stage)
    -- 
    -- The scaler works by placing the decimal point at IN_WIDTH_g - OUT_WIDTH_g.
    -- ie after TWIDWIDTH_g - 1.
    --
    -- Rounding is round to 0.
    -- SCALE option can be used to scale result of multiplier. Round to 0.
    ---------------------------------------------------------------------------
    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => submultff(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundrealff);

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => addmultff(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimagff);

    

  end generate gen_large_mult2;


  -----------------------------------------------------------------------------
  -- 3-MULTIPLIER IMPLEMENTATION
  -- STRATIX V FOR 10.0 
  -- New complex 18x25 mode (WYS version)
  -- New complex 27x27 mode and other modes (infer)
  -- ARRIA V FOR 11.1
  -- New 18x25 25pa, 20x24 24pa, 27x27 27pa (infer)
  -----------------------------------------------------------------------------

  gen_da: if not MULT_18_X_18 and ((DSP_ARCH_g = 1 and not MULT_SV_OPT_D37_AND_OVER) or (DSP_ARCH_g = 2 and not MULT_D27_TO_D38_X_T18)) generate
  
    signal in_real_d : std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal in_imag_d : std_logic_vector(DATAWIDTH_g - 1 downto 0);

    signal real_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal imag_result     : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal real_result_tmp : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);
    signal imag_result_tmp : std_logic_vector(DATAWIDTH_g + TWIDWIDTH_g downto 0);

    signal roundreal : std_logic_vector(DATAWIDTH_g + GROW_g  - 1 downto 0);
    signal roundimag : std_logic_vector(DATAWIDTH_g + GROW_g  - 1 downto 0);
    
    signal in_real_dd : std_logic_vector(DATAWIDTH_g -1 downto 0);
    signal in_imag_dd : std_logic_vector(DATAWIDTH_g -1 downto 0); 
  begin


    -- if optimize_mem = 1, then twiddles come 1 cycle later, so no need to
    -- delay the data, no change in overall pipeline latency

      delay_data_p : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            in_real_dd <= (others => '0');
            in_imag_dd <= (others => '0');
            in_real_d  <= (others => '0');
            in_imag_d  <= (others => '0');
          elsif enable = '1' then
            in_real_dd <= in_real_std;
            in_imag_dd <= in_imag_std;
            in_imag_d  <= in_imag_dd;
            in_real_d  <= in_real_dd;
          end if;
        end if;
      end process delay_data_p;



    gen_da1: if DSP_ARCH_g = 1 generate
    cpx_1825a: if (DATAWIDTH_g > 18 and DATAWIDTH_g <= 25 and TWIDWIDTH_g <= 18) generate
      calc_mac_cpx: apn_fft_mult_cpx_1825
      generic map(
        mpr => DATAWIDTH_g,
        twr => TWIDWIDTH_g
      )
      port map(
        clk     => clk,
        reset   => reset,
        global_clock_enable => enable,
        a_r     => in_real_d,
        a_i     => in_imag_d,
        b_r     => realtwid_std,
        b_i     => imagtwid_std,
        p_r     => real_result_tmp,
        p_i     => imag_result_tmp
      );
      end generate cpx_1825a;

      cpx_1825b: if (TWIDWIDTH_g > 18 and TWIDWIDTH_g <= 25 and DATAWIDTH_g <= 18) generate
        calc_mac_cpx: apn_fft_mult_cpx_1825
        generic map(
          mpr => TWIDWIDTH_g,
          twr => DATAWIDTH_g
        )
        port map(
          clk     => clk,
          reset   => reset,
          global_clock_enable => enable,
          a_r     => realtwid_std,
          a_i     => imagtwid_std,
          b_r     => in_real_d,
          b_i     => in_imag_d,
          p_r     => real_result_tmp,
          p_i     => imag_result_tmp
        );
      end generate cpx_1825b;

      cpx_infer : if not ((DATAWIDTH_g > 18 and DATAWIDTH_g <= 25 and TWIDWIDTH_g <= 18) or 
                          (TWIDWIDTH_g > 18 and TWIDWIDTH_g <= 25 and DATAWIDTH_g <= 18)) generate
        calc_infr_cpx: apn_fft_mult_cpx
        generic map(
          mpr => DATAWIDTH_g,
          twr => TWIDWIDTH_g
        )
        port map(
          global_clock_enable => enable,
          clk     => clk,
          reset   => reset,
          a       => in_real_d,
          b       => in_imag_d,
          c       => realtwid_std,
          d       => imagtwid_std,
          rout    => real_result_tmp,
          iout    => imag_result_tmp
        );
      end generate cpx_infer;
    end generate gen_da1;
    
    gen_da2: if DSP_ARCH_g = 2 generate
      gen_infr_3cpx: apn_fft_mult_can
      generic map(
        mpr => DATAWIDTH_g,
        twr => TWIDWIDTH_g
      )
      port map(
        global_clock_enable => enable,
        clk     => clk,
        reset   => reset,
        a       => in_real_d,
        b       => in_imag_d,
        c       => realtwid_std,
        d       => imagtwid_std,
        rout    => real_result_tmp,
        iout    => imag_result_tmp
      );        
    end generate gen_da2;
 
    reg_intermediate : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          imag_result <= (others => '0');
          real_result <= (others => '0');
        elsif enable = '1' then
          real_result <= real_result_tmp;
          imag_result <= imag_result_tmp;
        end if;
      end if;
    end process reg_intermediate;

    round_real : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => real_result(DATAWIDTH_g + TWIDWIDTH_g - 1 + GROW_g - 1 downto 0),
        dataout => roundrealff
      );

    round_imag : auk_dspip_roundsat
      generic map (
        IN_WIDTH_g      => DATAWIDTH_g + TWIDWIDTH_g -1 + GROW_g,
        OUT_WIDTH_g     => DATAWIDTH_g + GROW_g ,
        LATENCY => 3,
        ROUNDING_TYPE_g => "CONV_ROUND")
      port map (
        clk     => clk,
        reset   => reset,
        enable  => enable,
        datain  => imag_result(DATAWIDTH_g + TWIDWIDTH_g -1 +GROW_g - 1 downto 0),
        dataout => roundimagff
      );

  end generate gen_da;
  end generate NONA10_C_Mult_Archs;

  out_real <= std_logic_vector(resize(signed(roundrealff), out_real'length));
  out_imag <= std_logic_vector(resize(signed(roundimagff), out_imag'length));


  -----------------------------------------------------------------------------
  -- CONTROL SIGNALS
  -----------------------------------------------------------------------------
  -- delay control by the latency
  delay_control_p : process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_control_d <= (others => (others => '0'));
      elsif enable = '1'then
        out_control_d(0) <= in_control;
        for i in 1 to PIPELINE_g - 1 loop
          out_control_d(i) <= out_control_d(i-1);
        end loop;  -- i
      end if;
    end if;
  end process delay_control_p;


  -- delay valid by latency
  delay_valid_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_valid_d <= (others => '0');
      elsif enable = '1' then
        out_valid_d(0) <= in_valid;
        for i in 1 to PIPELINE_g - 1 loop
          out_valid_d(i) <= out_valid_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_valid_p;


  -- delay sop by latency
  delay_sop_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_sop_d <= (others => '0');
      elsif enable = '1' then
        out_sop_d(0) <= in_sop;
        for i in 1 to PIPELINE_g - 1 loop
          out_sop_d(i) <= out_sop_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_sop_p;
  -- delay eop by latency
  delay_eop_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_eop_d <= (others => '0');
      elsif enable = '1' then
        out_eop_d(0) <= in_eop;
        for i in 1 to PIPELINE_g - 1 loop
          out_eop_d(i) <= out_eop_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_eop_p;

-- delay inverse by latency
  delay_inv_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_inverse_d <= (others => '0');
      elsif enable = '1' then
        out_inverse_d(0) <= in_inverse;
        for i in 1 to PIPELINE_g - 1 loop
          out_inverse_d(i) <= out_inverse_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_inv_p;

  out_inverse <= out_inverse_d(PIPELINE_g - 1);
  out_sop     <= out_sop_d(PIPELINE_g - 1);
  out_eop     <= out_eop_d(PIPELINE_g - 1);
  out_valid   <= out_valid_d(PIPELINE_g - 1);
  out_control <= out_control_d(PIPELINE_g - 1);
  
end rtl;
