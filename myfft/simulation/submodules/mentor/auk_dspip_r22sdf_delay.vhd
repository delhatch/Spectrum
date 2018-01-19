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
-- $RCSfile: auk_dspip_r22sdf_delay.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_delay.vhd,v $
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
-- Delay unit. Either delay input by DELAY_g or DELAY_g/2 based on radix_2
-- 
--
-- $Log: auk_dspip_r22sdf_delay.vhd,v $
-- Revision 1.4.8.1  2007/07/23 13:31:34  kmarks
-- SPR 247689 MLAB inferred./
--
-- Revision 1.4  2006/12/05 10:54:43  kmarks
-- updated from the 6.1 branch
--
-- Revision 1.3.2.2  2006/09/28 16:47:29  kmarks
-- fmax improvements SPR 219316
--
-- Revision 1.3.2.1  2006/09/22 17:19:49  kmarks
-- SPR 217764
--
-- Revision 1.3  2006/09/08 10:40:47  kmarks
-- registers selected if delay <4
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

use work.auk_dspip_r22sdf_lib_pkg.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity auk_dspip_r22sdf_delay is

  generic (
    DEVICE_FAMILY_g : string;
    DATAWIDTH_g  : natural := 18;
    MAX_FFTPTS_g : natural := 1024;
    PIPELINE_g : natural := 1;
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

end entity auk_dspip_r22sdf_delay;

architecture rtl of auk_dspip_r22sdf_delay is

  -- registered data out
  signal dataout_s : std_logic_vector(DATAWIDTH_g - 1 downto 0);


begin  -- architecture delblk_auto_rtl

  dataout <= dataout_s;

  ---------------------------------------------------------------------------
  -- NO DELAY
  ---------------------------------------------------------------------------
  gen_no_delay : if (DELAY_g/2-PIPELINE_g < 0) or (DELAY_g/2-PIPELINE_g = 0 and  DELAY_g-PIPELINE_g /= 1) generate
  begin
    dataout_s <= datain;
  end generate gen_no_delay;

  -----------------------------------------------------------------------------
  -- ONE DELAY
  ---------------------------------------------------------------------------
  gen_one_delay : if DELAY_g/2-PIPELINE_g = 0 and  DELAY_g-PIPELINE_g = 1 generate
    signal dataout_int : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  begin

    dataout_s <= datain when radix_2 = '1' else
                 dataout_int;
    
    send_data_p : process (clk)
    begin
      if rising_edge(clk) then
        if reset = '1' then
          dataout_int <= (others => '0');
        elsif enable = '1' then
          dataout_int <= datain;
        end if;
      end if;
    end process send_data_p;
  end generate gen_one_delay;

  ---------------------------------------------------------------------------
  -- REGISTER DELAY BLOCK
  ---------------------------------------------------------------------------
  -- gen_reg_delay : if DELAY_g-PIPELINE_g <= 8 and DELAY_g/2-PIPELINE_g >= 1 generate
  gen_reg_delay : if DELAY_g/2-PIPELINE_g >= 1 and (DELAY_g/2-PIPELINE_g <4 or DELAY_g-PIPELINE_g <= 8) generate
    -- register signals
    type   del_reg_array_t is array (DELAY_g - PIPELINE_g downto 1) of std_logic_vector(DATAWIDTH_g - 1 downto 0);
    signal del_reg_array : del_reg_array_t;
  begin

    -- Shift register array left 1 per clock cycle.
    -- SPR 247689 Reset removed to allow MLAB to be inferred.
    -- SPR 307704 Reintroduce the reset, to improve fmax
    shift_reg_p : process (clk)
    begin
     if rising_edge(clk) then
        if reset = '1' then
          del_reg_array <= (others => (others => '0'));
        elsif enable = '1' then
          del_reg_array(DELAY_g - PIPELINE_g downto 1) <= del_reg_array(DELAY_g - PIPELINE_g - 1 downto 1) & datain;
        end if;
      end if;
    end process shift_reg_p;

    dataout_s <= del_reg_array(DELAY_g/2 - PIPELINE_g) when radix_2 = '1' else
                 del_reg_array(DELAY_g - PIPELINE_g);

  end generate gen_reg_delay;



  ---------------------------------------------------------------------------
  -- M4K DELAY BLOCK
  ---------------------------------------------------------------------------
  -- gen_m4k_delay : if DELAY_g-PIPELINE_g > 8 generate
  gen_m4k_delay : if DELAY_g-PIPELINE_g > 8 and DELAY_g/2-PIPELINE_g >= 4 generate
    signal delay : natural range 0 to DELAY_g-PIPELINE_g;
    constant ADDRWIDTH_c : natural := log2_ceil(DELAY_g-PIPELINE_g);
    signal rdptr       : std_logic_vector(ADDRWIDTH_c downto 0);
    signal wrptr       : std_logic_vector(ADDRWIDTH_c downto 0);
    signal radix_2_reg, ptr_reset, rdptr_reset, init_reset : std_logic;
    signal ptr_max     : std_logic_vector(ADDRWIDTH_c downto 0);

  begin

    delay <= DELAY_g/2 - PIPELINE_g when radix_2 = '1' else
             DELAY_g - PIPELINE_g;
    
      ram_component : altera_fft_dual_port_ram
      generic map (
        selected_device_family             => DEVICE_FAMILY_g,
        numwords                           => DELAY_g- PIPELINE_g,
        addr_width                         => ADDRWIDTH_c,
        data_width                         => DATAWIDTH_g
        )
      port map (
        clocken0  => enable,
        aclr0     => '0',
        wren_a    => enable,
        clock0    => clk,
        address_a => wrptr(ADDRWIDTH_c - 1 downto 0),
        address_b => rdptr(ADDRWIDTH_c - 1 downto 0),
        data_a    => datain,
        q_b       => dataout_s
        );

    ---- implement buffer, read pointer always DELAY_g behind the write pointer
    --move_wrptr : process (clk)
    --begin
    --  if rising_edge(clk) then
    --    if reset = '1' then
    --      wrptr <= (others => '0');
    --    elsif enable = '1' then
    --     -- if unsigned(wrptr) >= delay - 2- 1 then
    --      if unsigned(wrptr) >= delay - 1 then
    --        wrptr <= (others => '0');
    --      else
    --        wrptr <= std_logic_vector(unsigned(wrptr) + 1);
    --      end if;
    --    end if;
    --  end if;
    --end process move_wrptr;
    
    --move_rdptr : process (clk)
    --begin  -- process move_rdptr
    --  if rising_edge(clk) then
    --    if reset = '1' then
    --      rdptr <= (others => '0');
    --    elsif enable = '1' then
    --      if  (unsigned(rdptr) >= delay - 1) then
    --        if (unsigned(wrptr) = delay - 2 ) then -- special case if delay changes into exactly rdptr=delay and wrptr=delay-2
    --          rdptr <= std_logic_vector(to_unsigned(1,rdptr'length)); --rdptr <= std_logic_vector(unsigned(wrptr) - (delay - 2) + 1);
    --        else
    --          rdptr <= (others => '0'); -- regular reset of the counter rdptr
    --        end if;
    --      elsif (unsigned(wrptr) = delay - 2 - 1)  then -- first time setup to make sure rd pointer is always behind
    --        rdptr <= (others => '0');
    --      else
    --        rdptr <= std_logic_vector(unsigned(rdptr) + 1);
    --      end if;
    --    end if;
    --  end if;
    --end process move_rdptr;


    -- implement buffer, read pointer always DELAY_g behind the write pointer
    in_radix_2_reg : process (clk)
    begin
      if rising_edge(clk) then
        radix_2_reg <= radix_2; -- can further register this value if needed
      end if;
    end process;
    ptr_reset <= '1' when ((radix_2_reg /= radix_2) or reset = '1')  else
                 '0'; -- any time the delay value changes, reset the pointers; delay change only happens when input block size changes and the sytem starts over
    ptr_max <= std_logic_vector(to_unsigned(delay, ADDRWIDTH_c+1) - to_unsigned(1, ADDRWIDTH_c+1)); -- can register this value if needed

    --move_wrptr : process (clk)
    --begin
    --  if rising_edge(clk) then
    --    if reset = '1' then
    --      wrptr <= (others => '0');
    --    elsif enable = '1' then
    --     -- if unsigned(wrptr) >= delay - 2- 1 then
    --      if unsigned(wrptr) >= delay - 1 then
    --        wrptr <= (others => '0');
    --      elsif ptr_reset = '1' then
    --        wrptr <= (others => '0');
    --      else
    --        wrptr <= std_logic_vector(unsigned(wrptr) + 1);
    --      end if;
    --    end if;
    --  end if;
    --end process move_wrptr;

    move_wrptr_inst : counter_module
    generic map (COUNTER_WIDTH   => ADDRWIDTH_c + 1,
             COUNTER_STAGE_WIDTH => 4)
    port map (clk         => clk,
              clken       => enable,
              reset       => ptr_reset,
              reset_c     => '0',
              reset_value => (others=>'0'),
              counter_max => ptr_max,
              counter_out => wrptr);

    --move_rdptr : process (clk)
    --begin  -- process move_rdptr
    --  if rising_edge(clk) then
    --    if reset = '1' then
    --      rdptr <= (others => '0');
    --    elsif enable = '1' then
    --      if  (unsigned(rdptr) >= delay - 1) then
    --        rdptr <= (others => '0'); -- regular reset of the counter rdptr
    --      elsif (ptr_reset = '1') then
    --          rdptr <= (others => '0');
    --      elsif (unsigned(wrptr) = delay - 2 - 1)  then -- first time setup to make sure rd pointer is always behind
    --        rdptr <= (others => '0');
    --      else
    --        rdptr <= std_logic_vector(unsigned(rdptr) + 1);
    --      end if;
    --    end if;
    --  end if;
    --end process move_rdptr;

    move_rdptr_inst : counter_module
    generic map (COUNTER_WIDTH   => ADDRWIDTH_c + 1,
             COUNTER_STAGE_WIDTH => 4)
    port map (clk         => clk,
              clken       => enable,
              reset       => ptr_reset,
              reset_c     => init_reset,
              reset_value => (others=>'0'),
              counter_max => ptr_max,
              counter_out => rdptr);
    init_reset_proc : process (clk) -- first time setup to make sure rd pointer is always behind
    begin
      if rising_edge(clk) then
        if (enable = '1') then
          if (unsigned(wrptr) = delay - 2 - 2) then
            init_reset <= '1';
          else
            init_reset <= '0';
          end if;
        end if;
      end if;
    end process;




  end generate gen_m4k_delay;


end architecture rtl;


