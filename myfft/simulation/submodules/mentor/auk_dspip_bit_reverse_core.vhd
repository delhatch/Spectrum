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


-- (C) 2001-2015 Altera Corporation. All rights reserved.
-- Your use of Altera Corporation's design tools, logic functions and other 
-- software and tools, and its AMPP partner logic functions, and any output 
-- files any of the foregoing (including device programming or simulation 
-- files), and any associated documentation or information are expressly subject 
-- to the terms and conditions of the Altera Program License Subscription 
-- Agreement, Altera MegaCore Function License Agreement, or other applicable 
-- license agreement, including, without limitation, that your use is for the 
-- sole purpose of programming logic devices manufactured by Altera and sold by 
-- Altera or its authorized distributors.  Please refer to the applicable 
-- agreement for further details.


-------------------------------------------------------------------------
-------------------------------------------------------------------------
--
-- Revision Control Information
--
-- $RCSfile: auk_dspip_bit_reverse_core.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_bit_reverse_core.vhd,v $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   : kmarks
--
-- Project      : auk_dspip_lin
--
-- Description : 
--
-- bit reversal core. 
-- 
--
-- $Log: auk_dspip_bit_reverse_core.vhd,v $
-- Revision 1.1.8.2  2007/03/06 17:58:45  kmarks
-- SPR 236299 removed synthesis warnings
--
-- Revision 1.1.8.1  2007/02/26 17:22:08  kmarks
-- SPR234935 - Dynamic clk_ena control
--
-- Revision 1.1  2006/08/24 12:49:28  kmarks
-- various bug fixes and added bit reversal.
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

--library lpm;
--use lpm.lpm_components.all;
library altera_mf;
use altera_mf.altera_mf_components.all;

entity auk_dspip_bit_reverse_core is
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
end entity auk_dspip_bit_reverse_core;


architecture rtl of auk_dspip_bit_reverse_core is

  signal rd_addr          : std_logic_vector(log2_ceil(MAX_BLKSIZE_g) - 1 downto 0);
  signal wr_addr, wr_addr_reg          : std_logic_vector(log2_ceil(MAX_BLKSIZE_g) - 1 downto 0);
  signal rd_valid         : std_logic;
  signal rd_valid_d       : std_logic;
  signal rd_valid_dd      : std_logic;
  signal between_datasets : std_logic;
  signal indexing         : std_logic;
  signal in_data, in_data_reg          : std_logic_vector(DATAWIDTH_g*2 - 1 downto 0);
  signal out_data         : std_logic_vector(DATAWIDTH_g*2 - 1 downto 0);

  signal system_enable : std_logic;
  signal wr_enable, wr_enable_reg     : std_logic;
  signal rd_enable, rd_enable_reg     : std_logic;
  signal out_stall_d   : std_logic;

  signal processing_while_write : std_logic;
begin  -- architecture rtl


  -- enable control, enable remains high after the last data is written (or
  -- between datasets)
  system_enable <= rd_enable or wr_enable_reg;
  
  wr_enable <= enable and in_valid;
  rd_enable <= enable and in_valid when (between_datasets = '0' or (in_valid = '1' and unsigned(wr_addr) = 0)) else
               not out_stall_d;
  
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        rd_enable_reg <= '0';
        wr_enable_reg <= '0';
        wr_addr_reg <= (others=>'0');
        in_data_reg <= (others=>'0');
      else
        rd_enable_reg <= rd_enable;
        wr_enable_reg <= in_valid; 
        wr_addr_reg <= wr_addr;
        in_data_reg <= in_data;
      end if;
    end if;
  end process;



  processing <= processing_while_write or rd_valid;

  -- processing high while writing data to the bit reversal
  write_processing_p : process (clk, reset)
  begin  
    if reset = '1' then
      processing_while_write <= '0';
    elsif rising_edge(clk) then
      if wr_enable = '1' then
        if unsigned(wr_addr) = unsigned(blksize) - 1 then
          processing_while_write <= '0';
        else
          processing_while_write <= '1';
        end if;
      end if;
    end if;
  end process write_processing_p;

  out_valid <= (wr_enable_reg and rd_valid_dd) when between_datasets = '0' or in_valid = '1' else
               (rd_enable_reg and rd_valid_dd);
  
  rd_addr_inst : auk_dspip_bit_reverse_addr_control
    generic map (
      MAX_BLKSIZE_g => MAX_BLKSIZE_g)
    port map (
      clk     => clk,
      reset   => reset,
      enable  => rd_enable,
      index   => indexing,
      blksize => blksize,
      valid   => rd_valid,
      addr    => rd_addr
      );

  wr_addr_inst : auk_dspip_bit_reverse_addr_control
    generic map (
      MAX_BLKSIZE_g => MAX_BLKSIZE_g)
    port map (
      clk     => clk,
      reset   => reset,
      enable  => wr_enable,
      index   => indexing,
      blksize => blksize,
      valid   => in_valid,
      addr    => wr_addr
      );

  swap_index_p : process (clk, reset)
  begin
    if reset = '1' then
      indexing <= '0';
    elsif rising_edge(clk) then
      if wr_enable = '1' then
        if unsigned(wr_addr) = unsigned(blksize) - 1 then
          indexing <= not indexing;
        end if;
      end if;
    end if;
  end process swap_index_p;

  -- delayed by 2 for memory latency
  delay_output_p : process (clk, reset)
  begin  -- process delay_output_p
    if reset = '1' then
      rd_valid_d  <= '0';
      rd_valid_dd <= '0';
      out_stall_d <= '0';
    elsif rising_edge(clk) then
      out_stall_d <= out_stall;
      if rd_enable = '1' then
        rd_valid_d  <= rd_valid;
        rd_valid_dd <= rd_valid_d;
      end if;
    end if;
  end process delay_output_p;

  --valid control, read until the current data set has been read.
  valid_ctrl_p : process (clk, reset)
  begin  -- process valid_ctrl
    if reset = '1' then
      rd_valid <= '0';
    elsif rising_edge(clk) then
      if wr_enable = '1' then
        if unsigned(wr_addr) = unsigned(blksize) - 1 then
          rd_valid <= '1';
        end if;
      end if;
      if rd_enable = '1' then
        if unsigned(rd_addr) = unsigned(blksize) - 1 and
          unsigned(wr_addr) /= unsigned(blksize) - 1 then
          rd_valid <= '0';
        end if;
      end if;
    end if;
  end process valid_ctrl_p;

  between_datasets_p : process (clk, reset)
  begin  -- process between_datasets_p
    if reset = '1' then
      between_datasets <= '0';
    elsif rising_edge(clk) then
      if wr_enable = '1' then
        if (unsigned(wr_addr) = unsigned(blksize) - 1) and in_valid = '1' then
          between_datasets <= '1';
        elsif in_valid = '1' then
          between_datasets <= '0';
        end if;
      end if;
    end if;
  end process between_datasets_p;


  in_data <= in_real & in_imag;

    real_buf : altera_fft_dual_port_ram
    generic map (
      selected_device_family             => DEVICE_FAMILY_g,
      numwords                           => MAX_BLKSIZE_g,
      read_during_write_mode_mixed_ports => "OLD_DATA",
      addr_width                         => log2_ceil(MAX_BLKSIZE_g),
      data_width                         => 2*DATAWIDTH_g
      )
    port map (
      clocken0  => system_enable,
      wren_a    => wr_enable_reg,
      rden_b    => rd_enable,
      aclr0     => reset,
      clock0    => clk,
      address_a => wr_addr_reg,
      address_b => rd_addr,
      data_a    => in_data_reg,
      q_b       => out_data
      );

  


  out_real <= out_data(DATAWIDTH_g*2 - 1 downto DATAWIDTH_g);
  out_imag <= out_data(DATAWIDTH_g - 1 downto 0);

end architecture rtl;
