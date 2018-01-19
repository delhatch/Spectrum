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

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

LIBRARY altera_lnsim;
USE altera_lnsim.altera_lnsim_components.all;

entity altera_fft_dual_port_rom is
   generic (
      selected_device_family : string;
      ram_block_type         : string := "AUTO";
      init_file              : string;
      numwords               : natural;
      addr_width             : natural;
      data_width             : natural
           );
   port (
        clocken0  : in std_logic;
        aclr0     : in std_logic;
        clock0    : in std_logic;
        address_a : in std_logic_vector(addr_width-1 downto 0);
        address_b : in std_logic_vector(addr_width-1 downto 0);
        q_a       : out std_logic_vector(data_width-1 downto 0);
        q_b       : out std_logic_vector(data_width-1 downto 0) 
     );
end altera_fft_dual_port_rom;

architecture rtl of altera_fft_dual_port_rom is 
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
        address_reg_b             => "CLOCK0",
        clock_enable_input_a      => "NORMAL",
        clock_enable_input_b      => "NORMAL",
        clock_enable_output_a     => "NORMAL",
        clock_enable_output_b     => "NORMAL",
        indata_reg_b              => "CLOCK0",
        init_file                 => init_file,
        intended_device_family    => selected_device_family,
        lpm_type                  => "altsyncram",
        numwords_a                => numwords,
        numwords_b                => numwords,
        operation_mode            => "BIDIR_DUAL_PORT",
        outdata_aclr_a            => "CLEAR0",
        outdata_aclr_b            => "CLEAR0",
        outdata_reg_a             => "CLOCK0",
        outdata_reg_b             => "CLOCK0",
        power_up_uninitialized    => "FALSE",
        ram_block_type            => ram_block_type,
        widthad_a                 => addr_width,
        widthad_b                 => addr_width,
        width_a                   => data_width,
        width_b                   => data_width,
        width_byteena_a           => 1,
        width_byteena_b           => 1,
        wrcontrol_wraddress_reg_b => "CLOCK0"
        )
      port map (
        clocken0  => clocken0,
        wren_a    => '0',
        wren_b    => '0',
        aclr0     => aclr0,
        clock0    => clock0,
        address_a => address_a,
        address_b => address_b,
        data_a    => (others => '0'),
        data_b    => (others => '0'),
        q_a       => q_a,
        q_b       => q_b
        );
end generate old_ram_gen;

new_ram_gen : if not USE_OLD_RAM generate
    new_ram_component : altera_syncram
      generic map (
        address_reg_b             => "CLOCK0",
        clock_enable_input_a      => "NORMAL",
        clock_enable_input_b      => "NORMAL",
        clock_enable_output_a     => "NORMAL",
        clock_enable_output_b     => "NORMAL",
        indata_reg_b              => "CLOCK0",
        init_file                 => init_file,
        intended_device_family    => selected_device_family,
        lpm_type                  => "altsyncram",
        numwords_a                => numwords,
        numwords_b                => numwords,
        operation_mode            => "BIDIR_DUAL_PORT",
        outdata_aclr_a            => "CLEAR0",
        outdata_aclr_b            => "CLEAR0",
        outdata_reg_a             => "CLOCK0",
        outdata_reg_b             => "CLOCK0",
        power_up_uninitialized    => "FALSE",
        ram_block_type            => ram_block_type,
        widthad_a                 => addr_width,
        widthad_b                 => addr_width,
        width_a                   => data_width,
        width_b                   => data_width,
        width_byteena_a           => 1,
        width_byteena_b           => 1
        )
      port map (
        clocken0  => clocken0,
        wren_a    => '0',
        wren_b    => '0',
        aclr0     => aclr0,
        clock0    => clock0,
        address_a => address_a,
        address_b => address_b,
        data_a    => (others => '0'),
        data_b    => (others => '0'),
        q_a       => q_a,
        q_b       => q_b
        );
end generate new_ram_gen;
end rtl;
