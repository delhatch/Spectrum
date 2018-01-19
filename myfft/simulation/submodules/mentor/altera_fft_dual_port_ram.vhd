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


library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library altera_lnsim;
use altera_lnsim.altera_lnsim_components.all;

entity altera_fft_dual_port_ram is
   generic (
      selected_device_family : string;
      ram_block_type         : string := "AUTO";
      read_during_write_mode_mixed_ports : string := "DONT_CARE";
      numwords               : natural;
      addr_width             : natural;
      data_width             : natural
           );
   port (
        clocken0  : in std_logic;
        aclr0     : in std_logic;
        wren_a    : in std_logic;
        rden_b    : in std_logic := '1';
        clock0    : in std_logic;
        address_a : in std_logic_vector(addr_width-1 downto 0);
        address_b : in std_logic_vector(addr_width-1 downto 0);
        data_a    : in std_logic_vector(data_width-1 downto 0);
        q_b       : out std_logic_vector(data_width-1 downto 0) 
        );
end altera_fft_dual_port_ram;

architecture rtl of altera_fft_dual_port_ram is
    constant USE_OLD_RAM : boolean := selected_device_family = "Arria II GX"    or
                                      selected_device_family = "Arria II GZ"    or
                                      selected_device_family = "Arria V"        or
                                      selected_device_family = "Arria V GZ"     or
                                      selected_device_family = "Cyclone IV E"   or
                                      selected_device_family = "Cyclone IV GX"  or
                                      selected_device_family = "Cyclone V"      or
                                      selected_device_family = "Cyclone 10 LP"  or
                                      selected_device_family = "MAX 10 FPGA"    or
                                      selected_device_family = "MAX 10"         or 
                                      selected_device_family = "Stratix IV"     or 
                                      selected_device_family = "Stratix V"      ;

begin
old_ram_gen : if USE_OLD_RAM generate
    old_ram_component : altsyncram
    generic map (
      address_aclr_b                     => "CLEAR0",
      address_reg_b                      => "CLOCK0",
      rdcontrol_reg_b                    => "CLOCK0",
      intended_device_family             => selected_device_family,
      lpm_type                           => "altsyncram",
      numwords_a                         => numwords,
      numwords_b                         => numwords,
      operation_mode                     => "DUAL_PORT",
      outdata_aclr_b                     => "CLEAR0",
      outdata_reg_b                      => "CLOCK0",
      power_up_uninitialized             => "FALSE",
      ram_block_type                     => ram_block_type,
      read_during_write_mode_mixed_ports => read_during_write_mode_mixed_ports,
      widthad_a                          => addr_width,
      widthad_b                          => addr_width,
      width_a                            => data_width,
      width_b                            => data_width,
      width_byteena_a                    => 1
      )
    port map (
      clocken0  => clocken0,
      aclr0     => aclr0,
      wren_a    => wren_a,
      rden_b    => rden_b,
      clock0    => clock0,
      address_a => address_a,
      address_b => address_b,
      data_a    => data_a,
      q_b       => q_b
      );
end generate old_ram_gen;

new_ram_gen : if not USE_OLD_RAM and selected_device_family /= "Stratix 10" generate
    new_ram_component : altera_syncram
    generic map (
      address_aclr_b                     => "CLEAR0",
      address_reg_b                      => "CLOCK0",
      rdcontrol_reg_b                    => "CLOCK0",
      intended_device_family             => selected_device_family,
      lpm_type                           => "altera_syncram",
      numwords_a                         => numwords,
      numwords_b                         => numwords,
      operation_mode                     => "DUAL_PORT",
      outdata_aclr_b                     => "CLEAR0",
      outdata_reg_b                      => "CLOCK0",
      power_up_uninitialized             => "FALSE",
      ram_block_type                     => ram_block_type,
      read_during_write_mode_mixed_ports => read_during_write_mode_mixed_ports,
      widthad_a                          => addr_width,
      widthad_b                          => addr_width,
      width_a                            => data_width,
      width_b                            => data_width,
      width_byteena_a                    => 1
      )
    port map (
      clocken0  => clocken0,
      aclr0      => aclr0,
      wren_a    => wren_a,
      rden_b    => rden_b,
      clock0    => clock0,
      address_a => address_a,
      address_b => address_b,
      data_a    => data_a,
      q_b       => q_b
      );
end generate new_ram_gen;

s10_ram_gen : if not USE_OLD_RAM and selected_device_family = "Stratix 10" generate
    s10_ram_component : altera_syncram
    generic map (
      --address_aclr_b                     => "CLEAR0",
      address_reg_b                      => "CLOCK0",
      rdcontrol_reg_b                    => "CLOCK0",
      intended_device_family             => selected_device_family,
      lpm_type                           => "altera_syncram",
      numwords_a                         => numwords,
      numwords_b                         => numwords,
      operation_mode                     => "DUAL_PORT",
      outdata_sclr_b                     => "SCLEAR",
      outdata_reg_b                      => "CLOCK0",
      power_up_uninitialized             => "FALSE",
      ram_block_type                     => ram_block_type,
      read_during_write_mode_mixed_ports => read_during_write_mode_mixed_ports,
      widthad_a                          => addr_width,
      widthad_b                          => addr_width,
      width_a                            => data_width,
      width_b                            => data_width,
      width_byteena_a                    => 1
      )
    port map (
      clocken0  => clocken0,
      sclr      => aclr0,
      wren_a    => wren_a,
      rden_b    => rden_b,
      clock0    => clock0,
      address_a => address_a,
      address_b => address_b,
      data_a    => data_a,
      q_b       => q_b
      );
end generate s10_ram_gen;
end rtl;
