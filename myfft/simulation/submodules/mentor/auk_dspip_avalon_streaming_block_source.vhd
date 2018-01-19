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
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.auk_dspip_lib_pkg.all;
use work.auk_dspip_math_pkg.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity auk_dspip_avalon_streaming_block_source is
  generic (
    MAX_BLK_g : natural := 1024;
    DATAWIDTH_g  : natural := 18;
    HYPER_OPTIMIZATION : natural := 0
    );
  port (
    clk          : in  std_logic;
    reset        : in  std_logic;
    in_blk       : in  std_logic_vector(log2_ceil(MAX_BLK_g) downto 0);
    in_valid     : in  std_logic;
    source_stall : out std_logic;
    in_data      : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    source_valid : out std_logic;
    source_ready : in  std_logic;
    source_sop   : out std_logic;
    source_eop   : out std_logic;
    source_data  : out std_logic_vector(DATAWIDTH_g - 1 downto 0)
    );
end entity auk_dspip_avalon_streaming_block_source;


architecture rtl of auk_dspip_avalon_streaming_block_source is

  -- single-clock FIFO from altera_mf library
  component scfifo
  generic (
           add_ram_output_register: string := "ON";
           allow_rwcycle_when_full: string := "OFF";
           almost_empty_value: natural := 0;
           almost_full_value: natural := 0;
           lpm_numwords: natural;
           lpm_showahead: string := "OFF";
           lpm_width: natural;
           lpm_widthu: natural := 1;
           overflow_checking: string := "ON";
           underflow_checking: string := "ON";
           use_eab: string := "ON";
           lpm_hint: string := "UNUSED";
           lpm_type: string := "scfifo"
           );
  port    (
           aclr: in std_logic := '0';
           almost_empty: out std_logic;
           almost_full: out std_logic;
           clock: in std_logic;
           data: in std_logic_vector(lpm_width-1 downto 0);
           empty: out std_logic;
           full: out std_logic;
           q : out std_logic_vector(lpm_width-1 downto 0);
           rdreq: in std_logic;
           sclr: in std_logic := '0';
           usedw: out std_logic_vector(lpm_widthu-1 downto 0);
           wrreq: in std_logic
           );
  end component;


  -- FIFO connection signals
  constant SOURCE_LPM_NUMWORDS : natural := 32;
  constant SOURCE_ALMOST_FULL : natural := SOURCE_LPM_NUMWORDS - 7 - 5 - 5 - 6; -- default '-7', count the delay of source input and source_stall, and sink output delay
  constant SOURCE_LPM_WIDTHU : natural := log2_ceil_one(SOURCE_LPM_NUMWORDS);
  constant FIFO_DATA_WIDTH : natural := DATAWIDTH_g;
  signal source_fifo_data, source_fifo_q : std_logic_vector (FIFO_DATA_WIDTH-1 downto 0);
  signal source_fifo_empty, source_fifo_almost_full : std_logic;
  signal source_fifo_rdreq, source_fifo_wrreq : std_logic;
  signal source_fifo_usedw : std_logic_vector (SOURCE_LPM_WIDTHU-1 downto 0);
  signal reset_d, reset_pipelined : std_logic;

  -- block data count
  signal data_count : natural range 0 to MAX_BLK_g;

  -- other signals
  signal source_valid_s : std_logic;


  -- hyper optimized counter module
  component counter_module
  generic (COUNTER_WIDTH : natural := 10;
           HYPER_OPTIMIZATION : natural := 0;
           COUNTER_STAGE_WIDTH : natural := 4;
           COUNT_STEP : natural := 1);
  port (clk         : IN std_logic;
        clken       : IN std_logic;
        reset       : IN std_logic;
        reset_c     : IN std_logic;
        reset_value : IN std_logic_vector(COUNTER_WIDTH-1 downto 0);
        counter_max : IN std_logic_vector(COUNTER_WIDTH-1 downto 0);
        counter_out : OUT std_logic_vector(COUNTER_WIDTH-1 downto 0));
  end component;

  signal data_count_s, data_count_max : std_logic_vector (log2_ceil(MAX_BLK_g) downto 0);
  signal data_count_en                : std_logic;

begin

-- in order to optimize for S10, the reset signal to the FIFO is pipelined for one cycle
  gen_normal_reset : if HYPER_OPTIMIZATION /= 1 generate
  begin
    reset_d <= reset;
    reset_pipelined <= reset;
  end generate gen_normal_reset;
  gen_pipeline_reset : if HYPER_OPTIMIZATION = 1 generate
  begin
    reset_pipe : process (clk)
    begin
     if rising_edge(clk) then
        reset_d <= reset;
        reset_pipelined <= reset_d;
      end if;
    end process;
  end generate gen_pipeline_reset;

-- connect the source FIFO
source_FIFO : scfifo
  generic map(
              almost_full_value        => SOURCE_ALMOST_FULL,
              lpm_numwords             => SOURCE_LPM_NUMWORDS,
              lpm_width                => FIFO_DATA_WIDTH,
              lpm_widthu               => SOURCE_LPM_WIDTHU,
              lpm_showahead            => "OFF",
              use_eab                  => "ON" 
             )
  port map(
           clock         => clk,
           data          => source_fifo_data,
           empty         => source_fifo_empty,
           full          => open,
           almost_full   => source_fifo_almost_full,
           almost_empty  => open,
           q             => source_fifo_q,
           rdreq         => source_fifo_rdreq,
           sclr          => reset,
           usedw         => source_fifo_usedw,
           wrreq         => source_fifo_wrreq
          );


-- input data to source fifo
source_fifo_data  <= in_data;
-- output data from source fifo
source_data      <= source_fifo_q;
-- source fifo status signals for internal control
source_stall <= source_fifo_almost_full;


-- fifo control signal
source_fifo_wrreq <= in_valid;

fifo_rd_process : process (source_ready)
begin
  if source_ready = '1' then
    source_fifo_rdreq <= '1';
  else
    source_fifo_rdreq <= '0';
  end if;
end process;


source_valid_s_process : process (clk)
begin
  if rising_edge(clk) then
    if reset = '1' then
      source_valid_s <= '0';
    else
      if source_fifo_rdreq = '1' and source_fifo_empty = '0' then
        source_valid_s <= '1';
      elsif source_fifo_rdreq = '1' and source_fifo_empty = '1' then
        source_valid_s <= '0';
      end if;
    end if;
  end if;
end process;
source_valid <= source_valid_s;



-- sop and eop process, determined by data_count
source_sop <= '1' when data_count = 0 else
              '0';
source_eop <= '1' when data_count = unsigned(in_blk) - 1 else
              '0';


data_count_inst : counter_module
generic map (COUNTER_WIDTH   => log2_ceil(MAX_BLK_g)+1,
         HYPER_OPTIMIZATION  =>  HYPER_OPTIMIZATION,
         COUNTER_STAGE_WIDTH => 4)
port map (clk         => clk,
          clken       => data_count_en,
          reset       => reset,
          reset_c     => '0',
          reset_value => (others=>'0'),
          counter_max => data_count_max,
          counter_out => data_count_s);
data_count <= to_integer(unsigned(data_count_s));
data_count_en <= '1' when (source_valid_s = '1' and source_ready = '1') else
                 '0';
data_count_max <= std_logic_vector(unsigned(in_blk) - 1);


end rtl;

