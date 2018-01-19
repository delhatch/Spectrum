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


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.std_logic_arith.all; 

--
-- This is a convenience wrapper for altera_mult_add.
-- Latency is 3 cycles. 
--
entity altera_fft_mult_add is
   generic (
      selected_device_family  : STRING;
      multiplier1_direction   : STRING := "ADD";
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
end altera_fft_mult_add;

architecture rtl of altera_fft_mult_add is
   constant USE_OLD_MULT_ADD : boolean := selected_device_family = "Arria II GX"    or
                                          selected_device_family = "Arria II GZ"    or
                                          selected_device_family = "Cyclone IV E"   or
                                          selected_device_family = "Cyclone IV GX"  or
                                          selected_device_family = "Cyclone 10 LP"  or
                                          selected_device_family = "MAX 10 FPGA"    or
                                          selected_device_family = "MAX 10"         or 
                                          selected_device_family = "Stratix IV"     ; 


   component altera_fft_mult_add_new is
   generic (
      selected_device_family  : STRING;
      multiplier1_direction   : STRING := "ADD";
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
   end component altera_fft_mult_add_new;

   component altera_fft_mult_add_old is
   generic (
      selected_device_family  : STRING;
      multiplier1_direction   : STRING := "ADD";
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
   end component altera_fft_mult_add_old;
begin
use_new_mult_add_gen : if not USE_OLD_MULT_ADD generate
   mult_add_inst : component altera_fft_mult_add_new
      generic map (
         selected_device_family            => selected_device_family,
         multiplier1_direction             => multiplier1_direction,
         number_of_multipliers             => number_of_multipliers,
         width_a                           => width_a,
         width_b                           => width_b,
         width_result                      => width_result
      )
      port map (
         result                => result,                             --  result.result
         dataa                 => dataa,
         datab                 => datab,
         clock0                => clock0,                             --  clock0.clk
         aclr0                 => aclr0,                              --  aclr0.aclr0
         ena0                  => ena0
      );
end generate use_new_mult_add_gen;
use_old_mult_add_gen : if USE_OLD_MULT_ADD generate
   ALTMULT_ADD_component : altera_fft_mult_add_old
   GENERIC MAP (
      selected_device_family => selected_device_family,
      multiplier1_direction => multiplier1_direction,
      number_of_multipliers => number_of_multipliers,
      width_a => width_a,
      width_b => width_b,
      width_result => width_result
   )
   PORT MAP (
      dataa => dataa,
      datab => datab,
      clock0 => clock0,
      aclr0 => aclr0,
      ena0 => ena0,
      result => result
   );
end generate use_old_mult_add_gen;
end rtl;


LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.std_logic_arith.all; 

LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.all;

entity altera_fft_mult_add_new is
   generic (
      selected_device_family  : STRING;
      multiplier1_direction   : STRING := "ADD";
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
end altera_fft_mult_add_new;

architecture rtl of altera_fft_mult_add_new is
begin
      mult_add_inst : component altera_mult_add
      generic map (
         number_of_multipliers             => number_of_multipliers,
         width_a                           => width_a,
         width_b                           => width_b,
         width_result                      => width_result,
         output_register                   => "CLOCK0",
         output_aclr                       => "ACLR0",
         multiplier1_direction             => multiplier1_direction,
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
         width_coef                        => 18,
         coefsel0_register                 => "UNREGISTERED",
         coefsel1_register                 => "UNREGISTERED",
         coefsel2_register                 => "UNREGISTERED",
         coefsel3_register                 => "UNREGISTERED",
         coefsel0_aclr                     => "NONE",
         coefsel1_aclr                     => "NONE",
         coefsel2_aclr                     => "NONE",
         coefsel3_aclr                     => "NONE",
         coef0_0                           => 0,
         coef0_1                           => 0,
         coef0_2                           => 0,
         coef0_3                           => 0,
         coef0_4                           => 0,
         coef0_5                           => 0,
         coef0_6                           => 0,
         coef0_7                           => 0,
         coef1_0                           => 0,
         coef1_1                           => 0,
         coef1_2                           => 0,
         coef1_3                           => 0,
         coef1_4                           => 0,
         coef1_5                           => 0,
         coef1_6                           => 0,
         coef1_7                           => 0,
         coef2_0                           => 0,
         coef2_1                           => 0,
         coef2_2                           => 0,
         coef2_3                           => 0,
         coef2_4                           => 0,
         coef2_5                           => 0,
         coef2_6                           => 0,
         coef2_7                           => 0,
         coef3_0                           => 0,
         coef3_1                           => 0,
         coef3_2                           => 0,
         coef3_3                           => 0,
         coef3_4                           => 0,
         coef3_5                           => 0,
         coef3_6                           => 0,
         coef3_7                           => 0,
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
         latency                           => 1,
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
         selected_device_family            => selected_device_family
      )
      port map (
         result                => result,                             --  result.result
         dataa                 => dataa,
         datab                 => datab,
         clock0                => clock0,                             --  clock0.clk
         aclr0                 => aclr0,                              --  aclr0.aclr0
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
         ena0                  =>  ena0,
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
end rtl;

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_signed.all;
USE ieee.std_logic_arith.all; 

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

entity altera_fft_mult_add_old is
   generic (
      selected_device_family  : STRING;
      multiplier1_direction   : STRING := "ADD";
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
end altera_fft_mult_add_old;

architecture rtl of altera_fft_mult_add_old is
begin
   ALTMULT_ADD_component : altmult_add
   GENERIC MAP (
      accumulator => "NO",
      addnsub_multiplier_aclr1 => "ACLR0",
      addnsub_multiplier_pipeline_aclr1 => "ACLR0",
      addnsub_multiplier_pipeline_register1 => "CLOCK0",
      addnsub_multiplier_register1 => "CLOCK0",
      chainout_adder => "NO",
      chainout_register => "UNREGISTERED",
      dedicated_multiplier_circuitry => "AUTO",
      input_aclr_a0 => "ACLR0",
      input_aclr_a1 => "ACLR0",
      input_aclr_b0 => "ACLR0",
      input_aclr_b1 => "ACLR0",
      input_register_a0 => "CLOCK0",
      input_register_a1 => "CLOCK0",
      input_register_b0 => "CLOCK0",
      input_register_b1 => "CLOCK0",
      input_source_a0 => "DATAA",
      input_source_a1 => "DATAA",
      input_source_b0 => "DATAB",
      input_source_b1 => "DATAB",
      intended_device_family => selected_device_family,
      lpm_type => "altmult_add",
      multiplier1_direction => multiplier1_direction,
      multiplier_aclr0 => "ACLR0",
      multiplier_aclr1 => "ACLR0",
      multiplier_register0 => "CLOCK0",
      multiplier_register1 => "CLOCK0",
      number_of_multipliers => number_of_multipliers,
      output_aclr => "ACLR0",
      output_register => "CLOCK0",
      port_addnsub1 => "PORT_UNUSED",
      port_addnsub3 => "PORT_UNUSED",
      port_signa => "PORT_UNUSED",
      port_signb => "PORT_UNUSED",
      representation_a => "SIGNED",
      representation_b => "SIGNED",
      signed_aclr_a => "ACLR0",
      signed_aclr_b => "ACLR0",
      signed_pipeline_aclr_a => "ACLR0",
      signed_pipeline_aclr_b => "ACLR0",
      signed_pipeline_register_a => "CLOCK0",
      signed_pipeline_register_b => "CLOCK0",
      signed_register_a => "CLOCK0",
      signed_register_b => "CLOCK0",
      systolic_delay1 => "UNREGISTERED",
      systolic_delay3 => "UNREGISTERED",
      width_a => width_a,
      width_b => width_b,
      width_chainin => 1,
      width_result => width_result,
      zero_chainout_output_register => "UNREGISTERED",
      zero_loopback_aclr => "ACLR0",
      zero_loopback_output_aclr => "ACLR0",
      zero_loopback_output_register => "CLOCK0",
      zero_loopback_pipeline_aclr => "ACLR0",
      zero_loopback_pipeline_register => "CLOCK0",
      zero_loopback_register => "CLOCK0"


   )
   PORT MAP (
      dataa => dataa,
      datab => datab,
      clock0 => clock0,
      aclr0 => aclr0,
      ena0 => ena0,
      result => result
   );
end rtl;




