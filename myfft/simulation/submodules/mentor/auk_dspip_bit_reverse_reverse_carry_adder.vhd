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
-- reverse carry propagation adder. 
--   a(3)+-----+
--  ---->|  1  |----> sum(3)
--   b(3)| bit |
--  ---->| add |---+ cout(3)
--       +-----+   |
--                 |
--          +------+
--          |cin(2)
--          v
--   a(2)+-----+
--  ---->|  1  |----> sum(2)
--   b(2)| bit |
--  ---->| add |---+ cout(2)
--       +-----+   |
--                 |
--          +------+
--          |cin(1)
--          v
--   a(1)+-----+
--  ---->|  1  |----> sum(1)
--   b(1)| bit |
--  ---->| add |---+ cout(1)
--       +-----+   |
--                 |
--          +------+
--          |cin(0)
--          v
--   a(0)+-----+
--  ---->|  1  |----> sum(0)
--   b(0)| bit |
--  ---->| add |
--       +-----+   

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

entity auk_dspip_bit_reverse_reverse_carry_adder is
  generic (
    MAX_SIZE_g : natural := 9);
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    add_a   : in  std_logic_vector(MAX_SIZE_g - 1 downto 0);
    add_b   : in  std_logic_vector(MAX_SIZE_g - 1 downto 0);
    sum_out : out std_logic_vector(MAX_SIZE_g - 1 downto 0));
end entity auk_dspip_bit_reverse_reverse_carry_adder;


architecture rtl of auk_dspip_bit_reverse_reverse_carry_adder is
  signal cout : std_logic_vector(MAX_SIZE_g  downto 0);
  
begin  -- architecture rtl

  -- connect 1 bit adders with carry out connected to previous carry in
  cout(MAX_SIZE_g) <= '0';
  
  gen_adder: for i in MAX_SIZE_g - 1 downto 0 generate
    sum_out(i) <=  add_a(i) xor add_b(i) xor cout(i+1);
    -- cout 1 if majority of inputs are 1
    cout(i) <= (add_a(i) and add_b(i)) or
               (add_a(i) and cout(i+1)) or
               (add_b(i) and cout(i+1));
  end generate gen_adder;
  
  
end architecture rtl;
