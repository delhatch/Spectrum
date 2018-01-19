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
-- $RCSfile: $
-- $Source: $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   :  kmarks
--
-- Project      :  auk_dspip_lib
--
-- Description : 
--
-- controls the address - either bit reversed or incrementing
-- 
--
-- $Log: $
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

entity auk_dspip_bit_reverse_addr_control is
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
end entity auk_dspip_bit_reverse_addr_control;


architecture rtl of auk_dspip_bit_reverse_addr_control is

  signal bit_reverse_addr : std_logic_vector(log2_ceil(MAX_BLKSIZE_g) - 1 downto 0);
  signal addr_s           : std_logic_vector(log2_ceil(MAX_BLKSIZE_g) - 1 downto 0);
  
begin  -- architecture rtl

  addr <= addr_s;

  gen_addr : process (clk, reset)
  begin
    if reset = '1' then
      addr_s <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' and valid = '1' then
        --depending which cyle we are in, we are eitehr usign bit reversed or
        --ordinary indexing
        if index = '1' then
          addr_s <= bit_reverse_addr;
        else
          if unsigned(addr_s) = unsigned(blksize) - 1 then
            addr_s <= (others => '0');
          else
            addr_s <= std_logic_vector(unsigned(addr_s) + 1);
          end if;
        end if;
      end if;
    end if;
  end process gen_addr;


  reverse_carry_adder_inst : auk_dspip_bit_reverse_reverse_carry_adder
    generic map (
      MAX_SIZE_g => log2_ceil(MAX_BLKSIZE_g))
    port map (
      clk     => clk,
      reset   => reset,
      add_a   => addr_s,
      add_b   => blksize(log2_ceil(MAX_BLKSIZE_g) downto 1),
      sum_out => bit_reverse_addr);





end architecture rtl;
