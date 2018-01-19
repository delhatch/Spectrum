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

entity altera_fft_single_port_rom is
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
        clock0    : in std_logic;
        address_a : in std_logic_vector(addr_width-1 downto 0);
        q_a       : out std_logic_vector(data_width-1 downto 0)
     );
end altera_fft_single_port_rom;

architecture rtl of altera_fft_single_port_rom is
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
  GENERIC MAP (
		         address_aclr_a => "NONE",
		         init_file => init_file,
               intended_device_family => selected_device_family,
		         lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		         lpm_type => "altsyncram",
		         numwords_a => numwords,
		         operation_mode => "ROM",
		         outdata_aclr_a => "NONE",
		         outdata_reg_a => "CLOCK0",
               ram_block_type => ram_block_type,
		         widthad_a => addr_width,
		         width_a => data_width,
		         width_byteena_a => 1
	           )
  PORT MAP (
		      clocken0 => clocken0,
		      clock0 => clock0,
		      address_a => address_a,
		      q_a => q_a
	        );
end generate old_ram_gen;

new_ram_gen : if not USE_OLD_RAM generate
  new_ram_component : altera_syncram
  GENERIC MAP (
		         address_aclr_a => "NONE",
		         init_file => init_file,
               intended_device_family => selected_device_family,
		         lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		         lpm_type => "altsyncram",
		         numwords_a => numwords,
		         operation_mode => "ROM",
		         outdata_aclr_a => "NONE",
		         outdata_reg_a => "CLOCK0",
               ram_block_type => ram_block_type,
		         widthad_a => addr_width,
		         width_a => data_width,
		         width_byteena_a => 1
	           )
  PORT MAP (
		      clocken0 => clocken0,
		      clock0 => clock0,
		      address_a => address_a,
		      q_a => q_a
	        );
end generate new_ram_gen;
end rtl;
