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


library ieee;
library work;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library altera_lnsim;
use altera_lnsim.altera_lnsim_components.all;
library work;
use work.auk_dspip_math_pkg.all;
use work.auk_dspip_lib_pkg.all;
use work.auk_dspip_r22sdf_lib_pkg.all;


entity auk_dspip_r22sdf_cma_fp is
  generic (
    DEVICE_FAMILY_g  : string  := "Arria 10";
    INPUT_FORMAT_g   : string  := "NATURAL_ORDER";
    PIPELINE_g       : natural := 4;    -- this should match the number of
                                        -- cyles latency through the mult block
                                        -- adds extra pipeline stage
                                        -- through adder block.
    MAX_FFTPTS_g     : natural := 1024
    );
  port (
    clk         : in  std_logic;
    reset       : in  std_logic;
    enable      : in  std_logic;
    in_sop      : in  std_logic;
    in_eop      : in  std_logic;
    in_inverse  : in  std_logic;
    in_valid    : in  std_logic;
    in_fftpts   : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) downto 0);
    in_radix_2  : in  std_logic;
    in_control  : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g)-1 downto 0);
    in_real     : in  std_logic_vector(31 downto 0);
    in_imag     : in  std_logic_vector(31 downto 0);
    realtwid    : in  std_logic_vector(31 downto 0);
    imagtwid    : in  std_logic_vector(31 downto 0);
    twidaddr    : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
    out_real    : out std_logic_vector(31 downto 0);
    out_imag    : out std_logic_vector(31 downto 0);
    out_control : out std_logic_vector(log2_ceil(MAX_FFTPTS_g) -1 downto 0);
    out_inverse : out std_logic;
    out_sop     : out std_logic;
    out_eop     : out std_logic;
    out_valid   : out std_logic
    );
end auk_dspip_r22sdf_cma_fp;


architecture rtl of auk_dspip_r22sdf_cma_fp is
  
  COMPONENT twentynm_fp_mac
  generic (
  operation_mode  : string  :=  "SP_MULT_ADD";
  use_chainin : string  :=  "false";
  adder_subtract  : string  :=  "false";
  ax_clock  : string  :=  "none";
        ay_clock  : string  :=  "none";
        az_clock  : string  :=  "none";
  output_clock  : string  :=  "none";
  accumulate_clock  : string  :=  "none";
  accum_pipeline_clock  : string  :=  "none";
  accum_adder_clock : string  :=  "none";
  ax_chainin_pl_clock : string  :=  "none";
  mult_pipeline_clock : string  :=  "none";
  adder_input_clock : string  :=  "none";
  lpm_type  : string  :=  "twentynm_fp_mac"
    );
    port (
      ax  : in std_logic_vector(31 downto 0)  := (others => '0');
        ay  : in std_logic_vector(31 downto 0)  := (others => '0');
  az  : in std_logic_vector(31 downto 0)  := (others => '0');
  chainin : in std_logic_vector(31 downto 0)  := (others => '0');
  chainin_overflow  : in std_logic  := '0';
  chainin_underflow : in std_logic  := '0';
  chainin_inexact : in std_logic  := '0';
  chainin_invalid : in std_logic  := '0';
  accumulate  : in std_logic  := '0';
  clk : in std_logic_vector(2 downto 0) := (others => '0');
  ena : in std_logic_vector(2 downto 0) := (others => '1');
        aclr  : in std_logic_vector(1 downto 0) := (others => '0');
  resulta : out std_logic_vector(31 downto 0);
  overflow  : out std_logic;
  underflow : out std_logic;
  inexact : out std_logic;
  invalid : out std_logic;
  chainout  : out std_logic_vector(31 downto 0);
  chainout_overflow : out std_logic;
  chainout_underflow  : out std_logic;
  chainout_inexact  : out std_logic;
  chainout_invalid  : out std_logic;
  dftout  : out std_logic
    );
  END COMPONENT;

  constant DATAWIDTH_g : natural := 32;
  constant TWIDWIDTH_g : natural := 32;

  -- converted to bit vector and back to supress warnings
  signal in_real_del,in_real_del_2  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_del,in_imag_del_2  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_real_std  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal in_imag_std  : std_logic_vector(DATAWIDTH_g - 1 downto 0);
  signal realtwid_std : std_logic_vector(TWIDWIDTH_g - 1 downto 0);
  signal imagtwid_std : std_logic_vector(TWIDWIDTH_g - 1 downto 0);

  -- shift register to delay the enable signal by the latency throuhg this block
  type control_t is array (PIPELINE_g - 1 downto 0) of
    std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);
  signal out_valid_d    : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_sop_d      : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_eop_d      : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_inverse_d  : std_logic_vector(PIPELINE_g - 1 downto 0);
  signal out_control_d  : control_t;
  signal in_control_tmp : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 1 downto 0);

  signal in_real_sync, in_imag_sync : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal in_real_sync_1, in_imag_sync_1 : std_logic_vector(DATAWIDTH_g-1 downto 0);

  signal dr_del_0 : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal di_del_0 : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal tr_del_0 : std_logic_vector(TWIDWIDTH_g-1 downto 0);
  signal ti_del_0 : std_logic_vector(TWIDWIDTH_g-1 downto 0);
  signal real_result,real_res     : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal imag_result,imag_res     : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal dr_tr, dr_ti, di_tr, di_ti     : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal dr_tr_del, dr_ti_del, di_tr_del, di_ti_del     : std_logic_vector(DATAWIDTH_g-1 downto 0);
  signal real_in_a, real_in_b, imag_in_a, imag_in_b : std_logic_vector(DATAWIDTH_g-1 downto 0);

  signal clk_ext, ena_ext : std_logic_vector (2 downto 0);  -- in order to use the hard fp DSP block
  signal reset_ext : std_logic_vector (1 downto 0);         -- we need these control signals in 3-bit 
                                                            -- format, each bit is a seperate signal
begin

  clk_ext <= "00" & clk;
  ena_ext <= "00" & enable;
  reset_ext <= '0' & reset;


  -- convert to bit vector and back to convert X to 0, and reduce number of
  -- warnings in modelsim

  delay_input_proc : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        in_real_std <= (others=>'0');
        in_imag_std <= (others=>'0');
      elsif enable = '1' then
        in_real_std <= to_stdLogicVector(to_bitVector(in_real));
        in_imag_std <= to_stdLogicVector(to_bitVector(in_imag));
      end if;
    end if;
  end process;

  realtwid_std <= to_stdLogicVector(to_bitVector(realtwid));
  imagtwid_std <= to_stdLogicVector(to_bitVector(imagtwid));



  bf_counter_inst : auk_dspip_r22sdf_counter
    generic map (
      MAX_FFTPTS_g => MAX_FFTPTS_g,
      INPUT_FORMAT_g => INPUT_FORMAT_g)
    port map (
      clk         => clk,
      reset       => reset,
      -- start/stop processing
      enable      => enable,
      in_sop      => in_sop,
      in_eop      => in_eop,
      in_valid    => in_valid,
      --number of points in the fft
      in_fftpts   => in_fftpts,
      in_radix_2  => in_radix_2,
      in_control  => in_control_tmp,
      -- array of control signals to the stages.
      out_control => twidaddr);     



  in_control_reg_proc : process (clk)
  begin
    if rising_edge(clk) then
      if in_radix_2 = '0' then
        in_control_tmp <= std_logic_vector(unsigned(in_control) + 1);
      else
        in_control_tmp <= std_logic_vector(unsigned(in_control) + 2);
      end if;
    end if;
  end process;



      twiddle_delay : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            in_real_sync <= (others => '0');
            in_imag_sync <= (others => '0');
            in_real_sync_1 <= (others => '0');
            in_imag_sync_1 <= (others => '0');
          elsif enable = '1' then
            in_real_sync_1 <= in_real_std;
            in_imag_sync_1 <= in_imag_std;
            in_real_sync <= in_real_sync_1;
            in_imag_sync <= in_imag_sync_1;

          end if;
        end if;
      end process twiddle_delay;



      separate_proc : process( clk )
      begin
        if(rising_edge(clk)) then
          if enable = '1' then
            
            tr_del_0 <= realtwid_std;
            ti_del_0 <= imagtwid_std;
            dr_del_0 <= in_real_sync;
            di_del_0 <= in_imag_sync;

            dr_tr_del <= dr_tr;
            dr_ti_del <= dr_ti;
            di_tr_del <= di_tr;
            di_ti_del <= di_ti;

            real_result <= real_res;
            imag_result <= imag_res;

          end if;
        end if; 
      end process ; -- separate_proc



      -- A total of four multipliers
      first_ma : component twentynm_fp_mac
      generic map (ax_clock => "NONE",
                   ay_clock => "0",
                   az_clock => "0",
                   output_clock => "0",
                   accumulate_clock => "NONE",
                   ax_chainin_pl_clock => "NONE",
                   accum_pipeline_clock => "NONE",
                   mult_pipeline_clock => "0",
                   adder_input_clock => "0",
                   accum_adder_clock => "NONE",
                   use_chainin => "false",
                   operation_mode => "sp_mult",
                   adder_subtract => "false")
      port map (clk => clk_ext,
                ena => ena_ext,
                aclr => reset_ext,
                ay => dr_del_0,
                az => tr_del_0,
                chainin => (others=>'0'),
                resulta => dr_tr,
                chainout => open
                );


      
      second_ma : component twentynm_fp_mac
      generic map (ax_clock => "NONE",
                   ay_clock => "0",
                   az_clock => "0",
                   output_clock => "0",
                   accumulate_clock => "NONE",
                   ax_chainin_pl_clock => "NONE",
                   accum_pipeline_clock => "NONE",
                   mult_pipeline_clock => "0",
                   adder_input_clock => "0",
                   accum_adder_clock => "NONE",
                   use_chainin => "false",
                   operation_mode => "sp_mult",
                   adder_subtract => "false")
      port map (clk => clk_ext,
                ena => ena_ext,
                aclr => reset_ext,
                ay => di_del_0,
                az => ti_del_0,
                chainin => (others=>'0'),
                resulta => di_ti,
                chainout => open
                );
      

      third_ma : component twentynm_fp_mac
      generic map (ax_clock => "NONE",
                   ay_clock => "0",
                   az_clock => "0",
                   output_clock => "0",
                   accumulate_clock => "NONE",
                   ax_chainin_pl_clock => "NONE",
                   accum_pipeline_clock => "NONE",
                   mult_pipeline_clock => "0",
                   adder_input_clock => "0",
                   accum_adder_clock => "NONE",
                   use_chainin => "false",
                   operation_mode => "sp_mult",
                   adder_subtract => "false")
      port map (clk => clk_ext,
                ena => ena_ext,
                aclr => reset_ext,
                ay => dr_del_0,
                az => ti_del_0,
                chainin => (others=>'0'),
                resulta => dr_ti,
                chainout => open
                );
      

      fourth_ma : component twentynm_fp_mac
      generic map (ax_clock => "NONE",
                   ay_clock => "0",
                   az_clock => "0",
                   output_clock => "0",
                   accumulate_clock => "NONE",
                   ax_chainin_pl_clock => "NONE",
                   accum_pipeline_clock => "NONE",
                   mult_pipeline_clock => "0",
                   adder_input_clock => "0",
                   accum_adder_clock => "NONE",
                   use_chainin => "false",
                   operation_mode => "sp_mult",
                   adder_subtract => "false")
      port map (clk => clk_ext,
                ena => ena_ext,
                aclr => reset_ext,
                ay => di_del_0,
                az => tr_del_0,
                chainin => (others=>'0'),
                resulta => di_tr,
                chainout => open
                );
      

      real_in_a <= dr_tr_del;
      real_in_b <= di_ti_del;
      imag_in_a <= di_tr_del;
      imag_in_b <= dr_ti_del;


      real_sum : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g,
          REPRESENTATION_g => "FLOATPT",
          PIPELINE_g  => 0,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '0',
          dataa  => real_in_a,
          datab  => real_in_b,
          result => real_res);

      imag_sum : auk_dspip_r22sdf_addsub
        generic map (
          DATAWIDTH_g => DATAWIDTH_g,
          REPRESENTATION_g => "FLOATPT",
          PIPELINE_g  => 0,
          GROW_g      => 0)
        port map (
          clk    => clk,
          reset  => reset,
          clken  => enable,
          add    => '1',
          dataa  => imag_in_a,
          datab  => imag_in_b,
          result => imag_res);


  out_real <= real_result;
  out_imag <= imag_result;


  -----------------------------------------------------------------------------
  -- CONTROL SIGNALS
  -----------------------------------------------------------------------------
  -- delay control by the latency
  delay_control_p : process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_control_d <= (others => (others => '0'));
      elsif enable = '1'then
        out_control_d(0) <= in_control;
        for i in 1 to PIPELINE_g - 1 loop
          out_control_d(i) <= out_control_d(i-1);
        end loop;  -- i
      end if;
    end if;
  end process delay_control_p;


  -- delay valid by latency
  delay_valid_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_valid_d <= (others => '0');
      elsif enable = '1' then
        out_valid_d(0) <= in_valid;
        for i in 1 to PIPELINE_g - 1 loop
          out_valid_d(i) <= out_valid_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_valid_p;


  -- delay sop by latency
  delay_sop_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_sop_d <= (others => '0');
      elsif enable = '1' then
        out_sop_d(0) <= in_sop;
        for i in 1 to PIPELINE_g - 1 loop
          out_sop_d(i) <= out_sop_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_sop_p;
  -- delay eop by latency
  delay_eop_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_eop_d <= (others => '0');
      elsif enable = '1' then
        out_eop_d(0) <= in_eop;
        for i in 1 to PIPELINE_g - 1 loop
          out_eop_d(i) <= out_eop_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_eop_p;

-- delay inverse by latency
  delay_inv_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_inverse_d <= (others => '0');
      elsif enable = '1' then
        out_inverse_d(0) <= in_inverse;
        for i in 1 to PIPELINE_g - 1 loop
          out_inverse_d(i) <= out_inverse_d(i-1);
        end loop;
      end if;
    end if;
  end process delay_inv_p;

  out_inverse <= out_inverse_d(PIPELINE_g - 1);
  out_sop     <= out_sop_d(PIPELINE_g - 1);
  out_eop     <= out_eop_d(PIPELINE_g - 1);
  out_valid   <= out_valid_d(PIPELINE_g - 1);
  out_control <= out_control_d(PIPELINE_g - 1);
  
end rtl;

