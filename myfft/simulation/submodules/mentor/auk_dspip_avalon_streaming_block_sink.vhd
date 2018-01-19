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
use work.auk_dspip_math_pkg.all;


entity auk_dspip_avalon_streaming_block_sink is
  generic (
    FFT_ARCH  : string := "R22";
    MAX_BLK_g : natural := 1024;
    STALL_g      : natural := 1;
    DATAWIDTH_g  : natural := 16;
    -- this generic is specific for the FFT.
    NUM_STAGES_g : natural := 5;
    HYPER_OPTIMIZATION : natural := 1
     );
  port (
    clk            : in  std_logic;
    reset          : in  std_logic;
    in_blk         : in  std_logic_vector(log2_ceil(MAX_BLK_g) downto 0);
    in_sop         : in  std_logic;
    in_eop         : in  std_logic;
    in_inverse     : in  std_logic;
    sink_valid     : in  std_logic;
    sink_ready     : out std_logic;
    source_stall   : in  std_logic;
    in_data        : in  std_logic_vector(DATAWIDTH_g - 1 downto 0);
    processing     : in  std_logic;
    in_error       : in  std_logic_vector(1 downto 0);
    out_error      : out std_logic_vector(1 downto 0);
    out_valid      : out std_logic;
    out_sop        : out std_logic;
    out_eop        : out std_logic;
    out_data       : out std_logic_vector(DATAWIDTH_g - 1 downto 0);
    curr_blk       : out std_logic_vector(log2_ceil(MAX_BLK_g) downto 0);
    -- these are specific to the FFT, no effort has been made to optimize! 
    curr_pwr_2     : out std_logic;
    curr_inverse   : out std_logic;
    curr_input_sel : out std_logic_vector(NUM_STAGES_g - 1 downto 0)
    );
end entity auk_dspip_avalon_streaming_block_sink;


architecture rtl of auk_dspip_avalon_streaming_block_sink is

  constant MAX_PWR_2_c : natural := log2_ceil(MAX_BLK_g) rem 2;

  -- input registers
  signal in_inverse_reg, in_sop_reg, in_eop_reg, sink_valid_reg : std_logic;
  signal in_blk_reg, prev_blk                                   : std_logic_vector (log2_ceil(MAX_BLK_g) downto 0);
  signal in_data_reg                                            : std_logic_vector (DATAWIDTH_g-1 downto 0);

  -- fifo output signals
  signal curr_pwr_2_q, curr_inverse_q, out_sop_q, out_eop_q, blk_change_q : std_logic;
  signal curr_input_sel_q : std_logic_vector (NUM_STAGES_g - 1 downto 0);
  signal out_data_q : std_logic_vector (DATAWIDTH_g-1 downto 0);
  signal curr_blk_q : std_logic_vector (log2_ceil(MAX_BLK_g) downto 0);
  
  signal curr_pwr_2_s, curr_inverse_s, out_sop_s, out_eop_s, blk_change_s : std_logic;
  signal curr_input_sel_s : std_logic_vector (NUM_STAGES_g - 1 downto 0);
  signal out_data_s : std_logic_vector (DATAWIDTH_g-1 downto 0);
  signal curr_blk_s : std_logic_vector (log2_ceil(MAX_BLK_g) downto 0);

  -- stall signals
  signal stall_s, pre_stall            : std_logic;
  signal start              : std_logic;

  signal stg_input_sel   : std_logic_vector(NUM_STAGES_g - 1 downto 0);
  signal in_blk_pwr_2    : std_logic_vector(log2_ceil(MAX_BLK_g) downto 0);
  signal in_pwr_2        : std_logic;
  signal blk_change      : std_logic;

  -- control signals
  signal out_valid_s, out_valid_q  : std_logic;
  signal sink_ready_s : std_logic;

  -- error signals
  signal out_error_s    : std_logic_vector(1 downto 0);


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
  constant SINK_LPM_NUMWORDS : natural := 7;
  constant SINK_ALMOST_FULL : natural := SINK_LPM_NUMWORDS - 3; 
  constant SINK_LPM_WIDTHU : natural := log2_ceil_one(SINK_LPM_NUMWORDS);
  constant FIFO_DATA_WIDTH : natural := 6 + NUM_STAGES_g + log2_ceil(MAX_BLK_g) + DATAWIDTH_g;
  signal sink_fifo_data, sink_fifo_q : std_logic_vector (FIFO_DATA_WIDTH-1 downto 0);
  signal sink_fifo_empty, sink_fifo_almost_full : std_logic;
  signal sink_fifo_rdreq, sink_fifo_wrreq : std_logic;
  signal sink_fifo_usedw : std_logic_vector (SINK_LPM_WIDTHU-1 downto 0);
  signal reset_d, reset_pipelined : std_logic;


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
  

  -- connect the sink FIFO
  sink_FIFO : scfifo
  generic map(
              almost_full_value        => SINK_ALMOST_FULL,
              lpm_numwords             => SINK_LPM_NUMWORDS,
              lpm_width                => FIFO_DATA_WIDTH,
              lpm_widthu               => SINK_LPM_WIDTHU,
              lpm_showahead            => "OFF",
              use_eab                  => "ON" 
             )
  port map(
           clock         => clk,
           data          => sink_fifo_data,
           empty         => sink_fifo_empty,
           full          => open,
           almost_full   => sink_fifo_almost_full,
           almost_empty  => open,
           q             => sink_fifo_q,
           rdreq         => sink_fifo_rdreq,
           sclr          => reset,
           usedw         => sink_fifo_usedw,
           wrreq         => sink_fifo_wrreq
          );



  -- output signals assignment
  out_error      <= out_error_s; -- directly output to port
  output_register : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_valid      <= '0';
      elsif stall_s = '0' then
        out_valid      <= out_valid_q;
        curr_pwr_2     <= curr_pwr_2_q;
        curr_blk       <= curr_blk_q;
        curr_inverse   <= curr_inverse_q;
        curr_input_sel <= curr_input_sel_q;
        out_eop        <= out_eop_q;
        out_sop        <= out_sop_q;
        out_data       <= out_data_q;
      else
        out_valid      <= '0';
      end if;
    end if;
  end process;
  
  -- fifo output read
  sink_fifo_rdreq <= not(stall_s);

  fifo_output_valid : process (clk)
  begin
    if rising_edge(clk) then
      if reset =  '1' then
        out_valid_s <= '0';
      elsif sink_fifo_rdreq = '1' then
        if sink_fifo_empty = '0' then
          out_valid_s <= '1';
        elsif sink_fifo_empty = '1' then
          out_valid_s <= '0';
        end if;
      end if;
    end if;
  end process;
  
  curr_pwr_2_s     <= sink_fifo_q(FIFO_DATA_WIDTH-2);
  curr_blk_s       <= sink_fifo_q(DATAWIDTH_g+2+log2_ceil(MAX_BLK_g) downto DATAWIDTH_g+2);
  curr_inverse_s   <= sink_fifo_q(FIFO_DATA_WIDTH-1);
  curr_input_sel_s <= sink_fifo_q(FIFO_DATA_WIDTH-3 downto FIFO_DATA_WIDTH-2-NUM_STAGES_g);
  out_eop_s        <= sink_fifo_q(DATAWIDTH_g);
  out_sop_s        <= sink_fifo_q(DATAWIDTH_g+1);
  out_data_s       <= sink_fifo_q(DATAWIDTH_g-1 downto 0);
  blk_change_s     <= sink_fifo_q(DATAWIDTH_g+3+log2_ceil(MAX_BLK_g));
  
  fifo_out_register : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        out_valid_q <= '0';
      elsif stall_s = '0'then
        curr_pwr_2_q     <= curr_pwr_2_s;
        curr_blk_q       <= curr_blk_s;
        curr_inverse_q   <= curr_inverse_s;
        curr_input_sel_q <= curr_input_sel_s;
        out_eop_q        <= out_eop_s;
        out_sop_q        <= out_sop_s;
        out_data_q       <= out_data_s;
        blk_change_q     <= blk_change_s;
        out_valid_q      <= out_valid_s;
      end if;
   end if;
  end process;
  
  
  
  
  
  

  -- error code control
  out_error_s <= (others=>'0');


  -- take and process the input data, organize into a single data bus to the FIFO
  -- input data bus: 
  --                 -- in_inverse_reg (MSB)  width: 1
  --                 -- in_pwr_2              width: 1
  --                 -- stg_input_sel         width: NUM_STAGES_g
  --                 -- blk_change            width: 1
  --                 -- in_blk_reg            width: log2_ceil(MAX_BLK_g) + 1
  --                 -- in_sop_reg            width: 1
  --                 -- in_eop_reg            width: 1
  --                 -- in_data_reg (LSB)     width: DATAWIDTH_g
  -- FIFO_DATA_WIDTH = 6 + NUM_STAGES_g + log2_ceil(MAX_BLK_g) + DATAWIDTH_g

  sink_ready <= sink_ready_s;
  
  -- fifo input write
  fifo_in_process : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sink_ready_s    <= '0'; 
        sink_fifo_wrreq <= '0';
      else
        sink_ready_s    <= not(sink_fifo_almost_full); 
        sink_fifo_wrreq <= sink_valid_reg;
      end if;
      sink_fifo_data  <= (in_inverse_reg & in_pwr_2 & stg_input_sel & blk_change & in_blk_reg & in_sop_reg & in_eop_reg & in_data_reg);
    end if;
  end process;

  

  -- input data processing
  input_register : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        sink_valid_reg <= '0';
      elsif sink_ready_s = '1' then -- i.e. elsif sink_ready = '1' then
        in_inverse_reg <= in_inverse;
        in_blk_reg <= in_blk;
        prev_blk <= in_blk_reg;
        in_sop_reg <= in_sop;
        in_eop_reg <= in_eop;
        in_data_reg <= in_data;
        sink_valid_reg <= sink_valid;
      else
        sink_valid_reg <= '0';
      end if;
    end if;
  end process;

  stg_input_sel_p : process (in_blk_reg)
  begin
    stg_input_sel <= (others => '0');
    for i in (NUM_STAGES_g*2 - MAX_PWR_2_c) downto 1 loop
      if (i mod 2) = 0 then
        if in_blk_reg(i) = '1' and FFT_ARCH /= "MR42" then -- R22
          stg_input_sel(NUM_STAGES_g - (i)/2 - MAX_PWR_2_c) <= '1';
        elsif in_blk_reg(i) = '1' and FFT_ARCH = "MR42" then -- MR42
          stg_input_sel(NUM_STAGES_g - (i)/2) <= '1';
        end if;
      else
        if in_blk_reg(i) = '1' then
          stg_input_sel(NUM_STAGES_g - (i)/2 - 1) <= '1';
        end if;
      end if;
    end loop;
  end process;

  blk_change <= '1' when (in_blk_reg /= prev_blk) else
                '0';
  in_pwr_2_p : process (in_blk_reg)
  begin
    in_blk_pwr_2 <= (others => '0');
    for i in 0 to (log2_ceil(MAX_BLK_g) + MAX_PWR_2_c) - 1 loop
      if (i mod 2) = 1 then
        if in_blk_reg(i) = '1' then
          in_blk_pwr_2(i/2) <= '1';
        else
          in_blk_pwr_2(i/2) <= '0';
        end if;
      end if;
    end loop;
  end process in_pwr_2_p;
  in_pwr_2 <= or_reduce(in_blk_pwr_2);




  -- stall control
  gen_no_stall : if STALL_g = 0 generate
    stall_s     <= '0';
  end generate gen_no_stall;

  gen_stall : if STALL_g = 1 generate
    stall_s <= '1' when (pre_stall = '1' and processing = '1') or (source_stall = '1') else
               '0';
  end generate gen_stall;
  
  pre_stall_proc : process (clk)
  begin
    if rising_edge(clk) then
      if stall_s = '0' then
        pre_stall <= out_sop_s and blk_change_s and not(start);
      end if;
    end if;
  end process;


  -- indicates the first ever packet is being transmitted. blk_change only takes effect after that
  start_p : process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        start <= '1';
      elsif out_eop_s = '1' then
        start <= '0';
      end if;
    end if;
  end process start_p;





end rtl;

