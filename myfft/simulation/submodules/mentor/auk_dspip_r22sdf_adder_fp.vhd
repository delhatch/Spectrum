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
-- $RCSfile: auk_dspip_r22sdf_adder_fp.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_adder_fp.vhd,v $
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
-- $Log: auk_dspip_r22sdf_adder_fp.vhd,v $
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


entity auk_dspip_r22sdf_adder_fp is
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
    imagout_d : out std_logic_vector (32 downto 1)
    );
end auk_dspip_r22sdf_adder_fp;

architecture rtl of auk_dspip_r22sdf_adder_fp is



  signal realinff     : std_logic_vector (32 downto 1);
  signal imaginff     : std_logic_vector (32 downto 1);
  signal realin_dff   : std_logic_vector (32 downto 1);
  signal imagin_dff   : std_logic_vector (32 downto 1);
  signal synth001ff   : std_logic_vector (44 downto 1);
  signal synth001node : std_logic_vector (44 downto 1);
  signal synth002ff   : std_logic_vector (44 downto 1);
  signal synth002node : std_logic_vector (44 downto 1);
  signal synth003ff   : std_logic_vector (44 downto 1);
  signal synth003node : std_logic_vector (44 downto 1);
  signal synth004ff   : std_logic_vector (44 downto 1);
  signal synth004node : std_logic_vector (44 downto 1);
  signal castx005ff   : std_logic_vector (44 downto 1);
  signal castx005node : std_logic_vector (44 downto 1);
  signal castx006ff   : std_logic_vector (44 downto 1);
  signal castx006node : std_logic_vector (44 downto 1);
  signal castx007ff   : std_logic_vector (44 downto 1);
  signal castx007node : std_logic_vector (44 downto 1);
  signal castx008ff   : std_logic_vector (44 downto 1);
  signal castx008node : std_logic_vector (44 downto 1);
  signal castx009ff   : std_logic_vector (44 downto 1);
  signal castx009node : std_logic_vector (44 downto 1);
  signal castx010ff   : std_logic_vector (44 downto 1);
  signal castx010node : std_logic_vector (44 downto 1);
  signal castx011ff   : std_logic_vector (44 downto 1);
  signal castx011node : std_logic_vector (44 downto 1);
  signal castx012ff   : std_logic_vector (44 downto 1);
  signal castx012node : std_logic_vector (44 downto 1);
  signal castx013ff   : std_logic_vector (32 downto 1);
  signal castx013node : std_logic_vector (32 downto 1);
  signal castx014ff   : std_logic_vector (32 downto 1);
  signal castx014node : std_logic_vector (32 downto 1);
  signal castx015ff   : std_logic_vector (32 downto 1);
  signal castx015node : std_logic_vector (32 downto 1);
  signal castx016ff   : std_logic_vector (32 downto 1);
  signal castx016node : std_logic_vector (32 downto 1);
  signal deladdsub_in_ff : std_logic_vector(2 downto 1);
  signal deladdsub_in_d_ff : std_logic_vector(2 downto 1);
  component auk_dspip_fpcompiler_alufp
    port (
      sysclk       : in std_logic;
      reset        : in std_logic;
      enable    : in std_logic;
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
      enable    : in std_logic;
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

        synth001ff <= (others => '0');
        synth002ff <= (others => '0');
        synth003ff <= (others => '0');
        synth004ff <= (others => '0');
        castx005ff <= (others => '0');
        castx006ff <= (others => '0');
        castx007ff <= (others => '0');
        castx008ff <= (others => '0');
        castx009ff <= (others => '0');
        castx010ff <= (others => '0');
        castx011ff <= (others => '0');
        castx012ff <= (others => '0');
        castx013ff <= (others => '0');
        castx014ff <= (others => '0');
        castx015ff <= (others => '0');
        castx016ff <= (others => '0');
        deladdsub_in_ff <= (others => '0');
        deladdsub_in_d_ff <= (others => '1');
      elsif enable = '1' then
        realinff   <= realin;
        imaginff   <= imagin;
        realin_dff <= realin_d;
        imagin_dff <= imagin_d;
        deladdsub_in_ff(1) <=  addsub_in;
        deladdsub_in_d_ff(1) <=  addsub_in_d;
        deladdsub_in_d_ff(2) <= deladdsub_in_d_ff(1);
        deladdsub_in_ff(2) <= deladdsub_in_ff(1);
        synth001ff <= synth001node;
        synth002ff <= synth002node;
        synth003ff <= synth003node;
        synth004ff <= synth004node;
        castx005ff <= castx005node;
        castx006ff <= castx006node;
        castx007ff <= castx007node;
        castx008ff <= castx008node;
        castx009ff <= castx009node;
        castx010ff <= castx010node;
        castx011ff <= castx011node;
        castx012ff <= castx012node;
        castx013ff <= castx013node;
        castx014ff <= castx014node;
        castx015ff <= castx015node;
        castx016ff <= castx016node;
      end if;
    end if;

  end process;

  fpsum0 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk, reset => reset, enable => enable, addsub => '0',
              aa     => castx005ff(42 downto 1), aasat => castx005ff(43), aazip => castx005ff(44),
              bb     => castx009ff(42 downto 1), bbsat => castx009ff(43), bbzip => castx009ff(44),
              cc     => synth001node(42 downto 1), ccsat => synth001node(43), cczip => synth001node(44));
  fpsum1 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk, reset => reset, enable => enable, addsub => deladdsub_in_ff(2),
              aa     => castx011ff(42 downto 1), aasat => castx011ff(43), aazip => castx011ff(44),
              bb     => castx007ff(42 downto 1), bbsat => castx007ff(43), bbzip => castx007ff(44),
              cc     => synth002node(42 downto 1), ccsat => synth002node(43), cczip => synth002node(44));
  fpsum2 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk, reset => reset, enable => enable, addsub => '1',
              aa     => castx010ff(42 downto 1), aasat => castx010ff(43), aazip => castx010ff(44),
              bb     => castx006ff(42 downto 1), bbsat => castx006ff(43), bbzip => castx006ff(44),
              cc     => synth003node(42 downto 1), ccsat => synth003node(43), cczip => synth003node(44));
  fpsum3 : auk_dspip_fpcompiler_alufp
    port map (sysclk => sysclk, reset => reset, enable => enable, addsub => deladdsub_in_d_ff(2),
              aa     => castx012ff(42 downto 1), aasat => castx012ff(43), aazip => castx012ff(44),
              bb     => castx008ff(42 downto 1), bbsat => castx008ff(43), bbzip => castx008ff(44),
              cc     => synth004node(42 downto 1), ccsat => synth004node(43), cczip => synth004node(44));
  cast4 : auk_dspip_fpcompiler_castftox
    port map (aa => realinff(32 downto 1),
              cc => castx005node(42 downto 1), ccsat => castx005node(43), cczip => castx005node(44));
  cast5 : auk_dspip_fpcompiler_castftox
    port map (aa => realinff(32 downto 1),
              cc => castx006node(42 downto 1), ccsat => castx006node(43), cczip => castx006node(44));
  cast6 : auk_dspip_fpcompiler_castftox
    port map (aa => imaginff(32 downto 1),
              cc => castx007node(42 downto 1), ccsat => castx007node(43), cczip => castx007node(44));
  cast7 : auk_dspip_fpcompiler_castftox
    port map (aa => imaginff(32 downto 1),
              cc => castx008node(42 downto 1), ccsat => castx008node(43), cczip => castx008node(44));
  cast8 : auk_dspip_fpcompiler_castftox
    port map (aa => realin_dff(32 downto 1),
              cc => castx009node(42 downto 1), ccsat => castx009node(43), cczip => castx009node(44));
  cast9 : auk_dspip_fpcompiler_castftox
    port map (aa => realin_dff(32 downto 1),
              cc => castx010node(42 downto 1), ccsat => castx010node(43), cczip => castx010node(44));
  cast10 : auk_dspip_fpcompiler_castftox
    port map (aa => imagin_dff(32 downto 1),
              cc => castx011node(42 downto 1), ccsat => castx011node(43), cczip => castx011node(44));
  cast11 : auk_dspip_fpcompiler_castftox
    port map (aa => imagin_dff(32 downto 1),
              cc => castx012node(42 downto 1), ccsat => castx012node(43), cczip => castx012node(44));
  cast12 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth001ff(42 downto 1), aasat => synth001ff(43), aazip => synth001ff(44),
              cc     => castx013node(32 downto 1));
  cast13 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth002ff(42 downto 1), aasat => synth002ff(43), aazip => synth002ff(44),
              cc     => castx014node(32 downto 1));
  cast14 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth003ff(42 downto 1), aasat => synth003ff(43), aazip => synth003ff(44),
              cc     => castx015node(32 downto 1));
  cast15 : auk_dspip_fpcompiler_castxtof
    port map (sysclk => sysclk, reset => reset, enable => enable,
              aa     => synth004ff(42 downto 1), aasat => synth004ff(43), aazip => synth004ff(44),
              cc     => castx016node(32 downto 1));

  realout      <= castx013ff;
  imagout      <= castx014ff;
  realout_d <= castx015ff;
  imagout_d <= castx016ff;

end rtl;

