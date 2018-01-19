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
-- $RCSfile: auk_dspip_r22sdf_cma_adder_fp.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_cma_adder_fp.vhd,v $
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
-- $Log: auk_dspip_r22sdf_cma_adder_fp.vhd,v $
-- Revision 1.4.2.1  2007/07/23 13:31:34  kmarks
-- SPR 247689 MLAB inferred./
--
-- Revision 1.4  2007/07/02 12:23:55  kmarks
-- removed reference to fft_7_2
--
-- Revision 1.3  2007/06/04 08:54:00  kmarks
-- updated the verilog testbench and regression testbench for floating point. Fixed a few bugs in the floating point data path. Added -N/2 to N/2 support for floating pt. Fixed a bug in the fpadd
--
-- Revision 1.2  2007/05/21 16:18:45  kmarks
-- bug fixes - works for N= 64 with bit reversed inputs
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
library work;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

library work;
use work.auk_dspip_lib_pkg.all;

entity auk_dspip_r22sdf_cma_adder_fp is
  generic (
    INPUT_MUX_CONTROL_g : natural := 0);  -- indicates if an input mux should be added
  port (
    sysclk         : in std_logic;
    reset          : in std_logic;
    enable         : in std_logic;
    input_mux_ctrl : in std_logic := '0';
    realin         : in std_logic_vector (32 downto 1);
    imagin         : in std_logic_vector (32 downto 1);
    realin_d       : in std_logic_vector (32 downto 1);
    imagin_d       : in std_logic_vector (32 downto 1);
    realtwid       : in std_logic_vector (32 downto 1);
    imagtwid       : in std_logic_vector (32 downto 1);

    realout      : out std_logic_vector (32 downto 1);
    imagout      : out std_logic_vector (32 downto 1);
    realout_d    : out std_logic_vector (32 downto 1);
    imagout_d    : out std_logic_vector (32 downto 1);
    cma_real_out : out std_logic_vector (32 downto 1);
    cma_imag_out : out std_logic_vector (32 downto 1)
    );
end auk_dspip_r22sdf_cma_adder_fp;

architecture rtl of auk_dspip_r22sdf_cma_adder_fp is

  constant DELAY_MULT_NODE_c : natural := 6;
  type     mult_node_type is array(DELAY_MULT_NODE_c downto 1) of std_logic_vector (44 downto 1);

  signal delreal_multff  : mult_node_type;
  signal delimag_multff  : mult_node_type;
  signal fpsum6_input_aa : std_logic_vector(44 downto 1);
  signal fpsum6_input_bb : std_logic_vector(44 downto 1);
  signal fpsum7_input_aa : std_logic_vector(44 downto 1);
  signal fpsum7_input_bb : std_logic_vector(44 downto 1);
  signal fpsum8_input_aa : std_logic_vector(44 downto 1);
  signal fpsum8_input_bb : std_logic_vector(44 downto 1);
  signal fpsum9_input_aa : std_logic_vector(44 downto 1);
  signal fpsum9_input_bb : std_logic_vector(44 downto 1);

  signal realinff      : std_logic_vector (32 downto 1);
  signal imaginff      : std_logic_vector (32 downto 1);
  signal realin_dff    : std_logic_vector (32 downto 1);
  signal imagin_dff    : std_logic_vector (32 downto 1);
  signal realtwidff    : std_logic_vector (32 downto 1);
  signal imagtwidff    : std_logic_vector (32 downto 1);
  signal real_multnode : std_logic_vector (44 downto 1);
  signal imag_multnode : std_logic_vector (44 downto 1);
  signal synth001ff    : std_logic_vector (44 downto 1);
  signal synth001node  : std_logic_vector (44 downto 1);
  signal synth002ff    : std_logic_vector (44 downto 1);
  signal synth002node  : std_logic_vector (44 downto 1);
  signal synth003ff    : std_logic_vector (44 downto 1);
  signal synth003node  : std_logic_vector (44 downto 1);
  signal synth004ff    : std_logic_vector (44 downto 1);
  signal synth004node  : std_logic_vector (44 downto 1);
  signal synth005ff    : std_logic_vector (44 downto 1);
  signal synth005node  : std_logic_vector (44 downto 1);
  signal synth006ff    : std_logic_vector (44 downto 1);
  signal synth006node  : std_logic_vector (44 downto 1);
  signal synth007ff    : std_logic_vector (44 downto 1);
  signal synth007node  : std_logic_vector (44 downto 1);
  signal synth008ff    : std_logic_vector (44 downto 1);
  signal synth008node  : std_logic_vector (44 downto 1);
  signal synth009ff    : std_logic_vector (44 downto 1);
  signal synth009node  : std_logic_vector (44 downto 1);
  signal synth010ff    : std_logic_vector (44 downto 1);
  signal synth010node  : std_logic_vector (44 downto 1);
  signal castx011ff    : std_logic_vector (44 downto 1);
  signal castx011node  : std_logic_vector (44 downto 1);
  signal castx012ff    : std_logic_vector (44 downto 1);
  signal castx012node  : std_logic_vector (44 downto 1);
  signal castx013ff    : std_logic_vector (44 downto 1);
  signal castx013node  : std_logic_vector (44 downto 1);
  signal castx014ff    : std_logic_vector (44 downto 1);
  signal castx014node  : std_logic_vector (44 downto 1);
  signal castx015ff    : std_logic_vector (44 downto 1);
  signal castx015node  : std_logic_vector (44 downto 1);
  signal castx016ff    : std_logic_vector (44 downto 1);
  signal castx016node  : std_logic_vector (44 downto 1);
  signal castx017ff    : std_logic_vector (44 downto 1);
  signal castx017node  : std_logic_vector (44 downto 1);
  signal castx018ff    : std_logic_vector (44 downto 1);
  signal castx018node  : std_logic_vector (44 downto 1);
  signal castx019ff    : std_logic_vector (44 downto 1);
  signal castx019node  : std_logic_vector (44 downto 1);
  signal castx020ff    : std_logic_vector (44 downto 1);
  signal castx020node  : std_logic_vector (44 downto 1);
  signal castx021ff    : std_logic_vector (44 downto 1);
  signal castx021node  : std_logic_vector (44 downto 1);
  signal castx022ff    : std_logic_vector (44 downto 1);
  signal castx022node  : std_logic_vector (44 downto 1);
  signal castx023ff    : std_logic_vector (32 downto 1);
  signal castx023node  : std_logic_vector (32 downto 1);
  signal castx024ff    : std_logic_vector (32 downto 1);
  signal castx024node  : std_logic_vector (32 downto 1);
  signal castx025ff    : std_logic_vector (32 downto 1);
  signal castx025node  : std_logic_vector (32 downto 1);
  signal castx026ff    : std_logic_vector (32 downto 1);
  signal castx026node  : std_logic_vector (32 downto 1);
  signal castx027ff    : std_logic_vector (32 downto 1);
  signal castx027node  : std_logic_vector (32 downto 1);
  signal castx028ff    : std_logic_vector (32 downto 1);
  signal castx028node  : std_logic_vector (32 downto 1);

  component auk_dspip_fpcompiler_mulfp
    port (
      sysclk       : in std_logic;
      reset        : in std_logic;
      enable       : in std_logic;
      aa           : in std_logic_vector (42 downto 1);
      aasat, aazip : in std_logic;
      bb           : in std_logic_vector (42 downto 1);
      bbsat, bbzip : in std_logic;

      cc           : out std_logic_vector (42 downto 1);
      ccsat, cczip : out std_logic
      );
  end component;

  component auk_dspip_fpcompiler_mulfx
    generic (unsignedleft  : integer  := 1;
             unsignedright : integer  := 1;
             width         : positive := 8
             );
    port (
      sysclk : in std_logic;
      reset  : in std_logic;
      enable : in std_logic;
      aa     : in std_logic_vector (width downto 1);
      bb     : in std_logic_vector (width downto 1);

      cc : out std_logic_vector (width downto 1)
      );
  end component;

  component auk_dspip_fpcompiler_alufp
    port (
      sysclk       : in std_logic;
      reset        : in std_logic;
      enable       : in std_logic;
      addsub       : in std_logic;
      aa           : in std_logic_vector (42 downto 1);
      aasat, aazip : in std_logic;
      bb           : in std_logic_vector (42 downto 1);
      bbsat, bbzip : in std_logic;

      cc           : out std_logic_vector (42 downto 1);
      ccsat, cczip : out std_logic
      );
  end component;

  component auk_dspip_fpcompiler_castftox
    port (
      aa : in std_logic_vector (32 downto 1);

      cc           : out std_logic_vector (42 downto 1);
      ccsat, cczip : out std_logic
      );
  end component;

  component auk_dspip_fpcompiler_castxtof
    port (
      sysclk       : in std_logic;
      reset        : in std_logic;
      enable       : in std_logic;
      aa           : in std_logic_vector (42 downto 1);
      aasat, aazip : in std_logic;

      cc : out std_logic_vector (32 downto 1)
      );
  end component;

begin

  paa : process (sysclk)
  begin
    if (rising_edge(sysclk)) then
      if reset = '1' then
        realinff   <= (others => '0');
        imaginff   <= (others => '0');
        realin_dff <= (others => '0');
        imagin_dff <= (others => '0');
        realtwidff <= (others => '0');
        imagtwidff <= (others => '0');
        synth001ff <= (others => '0');
        synth002ff <= (others => '0');
        synth003ff <= (others => '0');
        synth004ff <= (others => '0');
        synth005ff <= (others => '0');
        synth006ff <= (others => '0');
        synth007ff <= (others => '0');
        synth008ff <= (others => '0');
        synth009ff <= (others => '0');
        synth010ff <= (others => '0');
        castx011ff <= (others => '0');
        castx012ff <= (others => '0');
        castx013ff <= (others => '0');
        castx014ff <= (others => '0');
        castx015ff <= (others => '0');
        castx016ff <= (others => '0');
        castx017ff <= (others => '0');
        castx018ff <= (others => '0');
        castx019ff <= (others => '0');
        castx020ff <= (others => '0');
        castx021ff <= (others => '0');
        castx022ff <= (others => '0');
        castx023ff <= (others => '0');
        castx024ff <= (others => '0');
        castx025ff <= (others => '0');
        castx026ff <= (others => '0');
        castx027ff <= (others => '0');
        castx028ff <= (others => '0');
      elsif enable = '1' then
        realinff   <= realin;
        imaginff   <= imagin;
        realin_dff <= realin_d;
        imagin_dff <= imagin_d;
        realtwidff <= realtwid;
        imagtwidff <= imagtwid;
        synth001ff <= synth001node;
        synth002ff <= synth002node;
        synth003ff <= synth003node;
        synth004ff <= synth004node;
        synth005ff <= synth005node;
        synth006ff <= synth006node;
        synth007ff <= synth007node;
        synth008ff <= synth008node;
        synth009ff <= synth009node;
        synth010ff <= synth010node;
        castx011ff <= castx011node;
        castx012ff <= castx012node;
        castx013ff <= castx013node;
        castx014ff <= castx014node;
        castx015ff <= castx015node;
        castx016ff <= castx016node;
        castx017ff <= castx017node;
        castx018ff <= castx018node;
        castx019ff <= castx019node;
        castx020ff <= castx020node;
        castx021ff <= castx021node;
        castx022ff <= castx022node;
        castx023ff <= castx023node;
        castx024ff <= castx024node;
        castx025ff <= castx025node;
        castx026ff <= castx026node;
        castx027ff <= castx027node;
        castx028ff <= castx028node;
        
      end if;
    end if;
    
  end process;

  -- SPR 245753
  -- no reset here to ensure this is recognised as a shift register and put
  -- into MLAB 
  paa_2 : process (sysclk)
  begin
    if (rising_edge(sysclk)) then
      if enable = '1' AND reset = '0' then
        delreal_multff(1) <= real_multnode;
        delimag_multff(1) <= imag_multnode;
        for i in DELAY_MULT_NODE_c downto 2 loop
          delreal_multff(i) <= delreal_multff(i-1);
          delimag_multff(i) <= delimag_multff(i-1);
        end loop;  -- i
        
      end if;
    end if;
    
  end process;
  
  fpmul0 : auk_dspip_fpcompiler_mulfp
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => castx013ff(42 downto 1), aasat => castx013ff(43), aazip => castx013ff(44),
              bb     => castx021ff(42 downto 1), bbsat => castx021ff(43), bbzip => castx021ff(44),
              cc     => synth001node(42 downto 1), ccsat => synth001node(43), cczip => synth001node(44));
  fpmul1 : auk_dspip_fpcompiler_mulfp
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => castx011ff(42 downto 1), aasat => castx011ff(43), aazip => castx011ff(44),
              bb     => castx019ff(42 downto 1), bbsat => castx019ff(43), bbzip => castx019ff(44),
              cc     => synth002node(42 downto 1), ccsat => synth002node(43), cczip => synth002node(44));
  fpsum2 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk, reset => reset, enable => enable, addsub => '1',
              aa     => synth002ff(42 downto 1), aasat => synth002ff(43), aazip => synth002ff(44),
              bb     => synth001ff(42 downto 1), bbsat => synth001ff(43), bbzip => synth001ff(44),
              cc     => synth003node(42 downto 1), ccsat => synth003node(43), cczip => synth003node(44));
  fpmul3 : auk_dspip_fpcompiler_mulfp
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => castx014ff(42 downto 1), aasat => castx014ff(43), aazip => castx014ff(44),
              bb     => castx020ff(42 downto 1), bbsat => castx020ff(43), bbzip => castx020ff(44),
              cc     => synth004node(42 downto 1), ccsat => synth004node(43), cczip => synth004node(44));
  fpmul4 : auk_dspip_fpcompiler_mulfp
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => castx012ff(42 downto 1), aasat => castx012ff(43), aazip => castx012ff(44),
              bb     => castx022ff(42 downto 1), bbsat => castx022ff(43), bbzip => castx022ff(44),
              cc     => synth005node(42 downto 1), ccsat => synth005node(43), cczip => synth005node(44));
  fpsum5 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk, reset => reset, enable => enable, addsub => '0',
              aa     => synth005ff(42 downto 1), aasat => synth005ff(43), aazip => synth005ff(44),
              bb     => synth004ff(42 downto 1), bbsat => synth004ff(43), bbzip => synth004ff(44),
              cc     => synth006node(42 downto 1), ccsat => synth006node(43), cczip => synth006node(44));
  gen_input_mux : if INPUT_MUX_CONTROL_g = 1 generate
    constant INPUT_MUX_DELAY_c : natural := 3;
    signal   input_mux_ctrl_d  : std_logic_vector(INPUT_MUX_DELAY_c - 1 downto 0);
  begin
    del_input_mux_ctrl : process (sysclk)
    begin  -- process del_input_mux_ctrl
      if rising_edge(sysclk) then
        if reset = '1' then
          input_mux_ctrl_d <= (others => '0');
        elsif enable = '1' then
          input_mux_ctrl_d(0) <= input_mux_ctrl;
          for i in INPUT_MUX_DELAY_c - 1 downto 1 loop
            input_mux_ctrl_d(i) <= input_mux_ctrl_d(i-1);
          end loop;  -- i
        end if;
      end if;
    end process del_input_mux_ctrl;

    mux_fpsum_inputs : process (sysclk)
    begin  -- process mux_fpsum_inputs
      if rising_edge(sysclk) then
        if reset = '1' then
          fpsum6_input_aa <= (others => '0');
          fpsum6_input_bb <= (others => '0');
          fpsum7_input_aa <= (others => '0');
          fpsum7_input_bb <= (others => '0');
          fpsum8_input_aa <= (others => '0');
          fpsum8_input_bb <= (others => '0');
          fpsum9_input_aa <= (others => '0');
          fpsum9_input_bb <= (others => '0');
        elsif enable = '1' then
          if input_mux_ctrl_d(input_mux_ctrl_d'high) = '1' then
            fpsum6_input_aa <= castx015ff;
            fpsum6_input_bb <= delreal_multff(DELAY_MULT_NODE_c);
            fpsum7_input_aa <= castx017ff;
            fpsum7_input_bb <= delimag_multff(DELAY_MULT_NODE_c);
            fpsum8_input_aa <= castx015ff;
            fpsum8_input_bb <= delreal_multff(DELAY_MULT_NODE_c);
            fpsum9_input_aa <= castx017ff;
            fpsum9_input_bb <= delimag_multff(DELAY_MULT_NODE_c);
          else
            fpsum6_input_aa <= delreal_multff(DELAY_MULT_NODE_c);
            fpsum6_input_bb <= castx015ff;
            fpsum7_input_aa <= delimag_multff(DELAY_MULT_NODE_c);
            fpsum7_input_bb <= castx017ff;
            fpsum8_input_aa <= delreal_multff(DELAY_MULT_NODE_c);
            fpsum8_input_bb <= castx015ff;
            fpsum9_input_aa <= delimag_multff(DELAY_MULT_NODE_c);
            fpsum9_input_bb <= castx017ff;
          end if;
        end if;
      end if;
    end process mux_fpsum_inputs;
  end generate gen_input_mux;

  gen_no_input_mux : if INPUT_MUX_CONTROL_g = 0 generate
    fpsum6_input_aa <= delreal_multff(DELAY_MULT_NODE_c);
    fpsum6_input_bb <= castx015ff;
    fpsum7_input_aa <= delimag_multff(DELAY_MULT_NODE_c);
    fpsum7_input_bb <= castx017ff;
    fpsum8_input_aa <= delreal_multff(DELAY_MULT_NODE_c);
    fpsum8_input_bb <= castx015ff;
    fpsum9_input_aa <= delimag_multff(DELAY_MULT_NODE_c);
    fpsum9_input_bb <= castx017ff;
  end generate gen_no_input_mux;

  fpsum6 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk,
              reset  => reset,
              enable => enable,
              addsub => '0',
              aa     => fpsum6_input_aa(42 downto 1),
              aasat  => fpsum6_input_aa(43),
              aazip  => fpsum6_input_aa(44),
              bb     => fpsum6_input_bb(42 downto 1),
              bbsat  => fpsum6_input_bb(43),
              bbzip  => fpsum6_input_bb(44),
              cc     => synth007node(42 downto 1),
              ccsat  => synth007node(43),
              cczip  => synth007node(44));
  fpsum7 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk,
              reset  => reset,
              enable => enable,
              addsub => '0',
              aa     => fpsum7_input_aa(42 downto 1),
              aasat  => fpsum7_input_aa(43),
              aazip  => fpsum7_input_aa(44),
              bb     => fpsum7_input_bb(42 downto 1),
              bbsat  => fpsum7_input_bb(43),
              bbzip  => fpsum7_input_bb(44),
              cc     => synth008node(42 downto 1),
              ccsat  => synth008node(43),
              cczip  => synth008node(44));
  fpsum8 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk,
              reset  => reset,
              enable => enable,
              addsub => '1',
              bb     => fpsum8_input_aa(42 downto 1),
              bbsat  => fpsum8_input_aa(43),
              bbzip  => fpsum8_input_aa(44),
              aa     => fpsum8_input_bb(42 downto 1),
              aasat  => fpsum8_input_bb(43),
              aazip  => fpsum8_input_bb(44),
              cc     => synth009node(42 downto 1),
              ccsat  => synth009node(43),
              cczip  => synth009node(44));
  fpsum9 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk,
              reset  => reset,
              enable => enable,
              addsub => '1',
              bb     => fpsum9_input_aa(42 downto 1),
              bbsat  => fpsum9_input_aa(43),
              bbzip  => fpsum9_input_aa(44),
              aa     => fpsum9_input_bb(42 downto 1),
              aasat  => fpsum9_input_bb(43),
              aazip  => fpsum9_input_bb(44),
              cc     => synth010node(42 downto 1),
              ccsat  => synth010node(43),
              cczip  => synth010node(44));
  cast10 : auk_dspip_fpcompiler_castftox
    port map (aa => realinff(32 downto 1),
              cc => castx011node(42 downto 1), ccsat => castx011node(43), cczip => castx011node(44));
  cast11 : auk_dspip_fpcompiler_castftox
    port map (aa => realinff(32 downto 1),
              cc => castx012node(42 downto 1), ccsat => castx012node(43), cczip => castx012node(44));
  cast12 : auk_dspip_fpcompiler_castftox
    port map (aa => imaginff(32 downto 1),
              cc => castx013node(42 downto 1), ccsat => castx013node(43), cczip => castx013node(44));
  cast13 : auk_dspip_fpcompiler_castftox
    port map (aa => imaginff(32 downto 1),
              cc => castx014node(42 downto 1), ccsat => castx014node(43), cczip => castx014node(44));
  cast14 : auk_dspip_fpcompiler_castftox
    port map (aa => realin_dff(32 downto 1),
              cc => castx015node(42 downto 1), ccsat => castx015node(43), cczip => castx015node(44));
  cast15 : auk_dspip_fpcompiler_castftox
    port map (aa => realin_dff(32 downto 1),
              cc => castx016node(42 downto 1), ccsat => castx016node(43), cczip => castx016node(44));
  cast16 : auk_dspip_fpcompiler_castftox
    port map (aa => imagin_dff(32 downto 1),
              cc => castx017node(42 downto 1), ccsat => castx017node(43), cczip => castx017node(44));
  cast17 : auk_dspip_fpcompiler_castftox
    port map (aa => imagin_dff(32 downto 1),
              cc => castx018node(42 downto 1), ccsat => castx018node(43), cczip => castx018node(44));
  cast18 : auk_dspip_fpcompiler_castftox
    port map (aa => realtwidff(32 downto 1),
              cc => castx019node(42 downto 1), ccsat => castx019node(43), cczip => castx019node(44));
  cast19 : auk_dspip_fpcompiler_castftox
    port map (aa => realtwidff(32 downto 1),
              cc => castx020node(42 downto 1), ccsat => castx020node(43), cczip => castx020node(44));
  cast20 : auk_dspip_fpcompiler_castftox
    port map (aa => imagtwidff(32 downto 1),
              cc => castx021node(42 downto 1), ccsat => castx021node(43), cczip => castx021node(44));
  cast21 : auk_dspip_fpcompiler_castftox
    port map (aa => imagtwidff(32 downto 1),
              cc => castx022node(42 downto 1), ccsat => castx022node(43), cczip => castx022node(44));
  cast22 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => real_multnode(42 downto 1), aasat => real_multnode(43), aazip => real_multnode(44),
              cc     => castx023node(32 downto 1));
  cast23 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => imag_multnode(42 downto 1), aasat => imag_multnode(43), aazip => imag_multnode(44),
              cc     => castx024node(32 downto 1));
  cast24 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth007ff(42 downto 1), aasat => synth007ff(43), aazip => synth007ff(44),
              cc     => castx025node(32 downto 1));
  cast25 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth008ff(42 downto 1), aasat => synth008ff(43), aazip => synth008ff(44),
              cc     => castx026node(32 downto 1));
  cast26 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth009ff(42 downto 1), aasat => synth009ff(43), aazip => synth009ff(44),
              cc     => castx027node(32 downto 1));
  cast27 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth010ff(42 downto 1), aasat => synth010ff(43), aazip => synth010ff(44),
              cc     => castx028node(32 downto 1));

  real_multnode <= synth003ff;
  imag_multnode <= synth006ff;

  realout      <= castx025ff;
  imagout      <= castx026ff;
  realout_d    <= castx027ff;
  imagout_d    <= castx028ff;
  cma_real_out <= castx023ff(32 downto 1);
  cma_imag_out <= castx024ff(32 downto 1);

end rtl;

