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
-- $RCSfile: auk_dspip_r22sdf_twrom.vhd,v $
-- $Source: /cvs/uksw/dsp_cores/FFT/src/rtl/lib/r22sdf/auk_dspip_r22sdf_twrom.vhd,v $
--
-- $Revision: #1 $
-- $Date: 2017/07/30 $
-- Check in by     : $Author: swbranch $
-- Author   :  kmarks
--
-- Project      :  auk_dspip_r22sdf
--
-- Description : 
--
-- <Brief description of the contents of the file>
-- 
--
-- $Log: auk_dspip_r22sdf_twrom.vhd,v $
-- Revision 1.8  2007/05/04 08:19:38  kmarks
-- working after rearranging stage to have multiplication first.
--
-- Revision 1.7  2007/04/11 10:11:45  kmarks
-- *** empty log message ***
--
-- Revision 1.6.2.1  2007/04/02 14:32:37  kmarks
-- SPR 239567 - twiddle address generation when N= pwr 4, and first block is pwr 2
--
-- Revision 1.6  2007/01/31 12:17:25  kmarks
-- removed some quartus warnings
--
-- Revision 1.5  2007/01/25 12:38:50  kmarks
-- added bit reversal optimisations
--
-- Revision 1.4  2007/01/12 13:33:28  kmarks
-- added architecture for optimizing the memory
--
-- Revision 1.3  2006/08/14 12:08:36  kmarks
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


entity auk_dspip_r22sdf_twrom is
  generic (
    DEVICE_FAMILY_g : string;
    MAX_FFTPTS_g   : natural  := 2048;
    STAGE_g        : natural  := 1;
    REPRESENTATION_g : string := "FIXEDPT";
    TWIDWIDTH_g    : positive := 18;
    OPTIMIZE_MEM_g : natural  := 0;
    INPUT_FORMAT_g :string := "NATURAL";
    REALFILE_g     : string   := "twr.hex";
    IMAGFILE_g     : string   := "twi.hex"
    );
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    enable   : in  std_logic;
    rd_en    : in  std_logic := '1';
    pwr_2    : in  std_logic;
    addr     : in  std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 2*STAGE_g + 1 downto 0);
    realtwid : out std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    imagtwid : out std_logic_vector(TWIDWIDTH_g - 1 downto 0)
    );
end auk_dspip_r22sdf_twrom;

architecture rtl of auk_dspip_r22sdf_twrom is
  constant ONE_CYCLE_DELAY_c : natural := 1;


begin

  gen_optimized_memory_delayed : if OPTIMIZE_MEM_g = 1 and ONE_CYCLE_DELAY_c = 1 generate

    constant NUM_GRPS_c : natural := 4;
    type     array_natural_t is array (0 to NUM_GRPS_c - 1) of natural;
  
    function calc_zero_grp return natural is
    begin
      if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
        return 3;
      else
        return 0;
      end if;
    end function calc_zero_grp;

    function calc_increment return array_natural_t is
    begin
      if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
        return (2, 1, 3, 0);
      else
        return (0, 2, 1, 3);
      end if;
    end function calc_increment;

    function calc_2x_increment return array_natural_t is
    begin
      if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
        return (4, 2, 6, 0);
      else
        return (0, 4, 2, 6);
      end if;
    end function calc_2x_increment;

    function calc_invalid_cnt_grp return natural is
    begin
      if INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2" then
        return 3;
      else
        return 0;
      end if;
    end function calc_invalid_cnt_grp;

    function gen_one_representation return std_logic_vector is
    begin
        if REPRESENTATION_g = "FIXEDPT" then
          return '0' & std_logic_vector(to_signed(-1, TWIDWIDTH_g - 1));
        else
          return X"3F800000";
        end if;
    end function gen_one_representation;

    constant MAX_PWR_2_c     : natural := log2_ceil(MAX_FFTPTS_g)rem 2;
    constant ROM_PTS_c   : natural := (MAX_FFTPTS_g)/(4**(STAGE_g-1));  -- number of points in this rom
    constant ADDRWIDTH_c : natural := log2_ceil(ROM_PTS_c/4) + 1;

    constant MAX_INDEX_c : natural := ROM_PTS_c/4 -1;
    constant MAX_GRP_c   : natural := 3;
    constant INVALID_GRP : natural := calc_invalid_cnt_grp;

    constant MEM_DELAY_c : natural := 2;
    constant ZERO_GRP_c : natural :=  calc_zero_grp;--3;  -- grp where W1 should be output
    constant ONE_REPRESENTATION_c : std_logic_vector(TWIDWIDTH_g -1 downto 0) := gen_one_representation;

    signal addr_plus_one : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 2*STAGE_g + 1 downto 0);
    signal addr_plus_two : std_logic_vector(log2_ceil(MAX_FFTPTS_g) - 2*STAGE_g + 1 downto 0);

    --constant K_INCREMENT_c : array_natural_t := (0, 2, 1, 3);
    constant K_INCREMENT_c    : array_natural_t := calc_increment;--(2, 1, 3, 0);
    constant K_2x_INCREMENT_c : array_natural_t := calc_2x_increment;--(4, 2, 6, 0);

    type negate_op_t is array (MEM_DELAY_c downto 0) of natural range 0 to 2;

    type     cnt_grp_delay_t is array (0 to MEM_DELAY_c) of std_logic_vector(log2_ceil_one(MAX_GRP_c) - 1 downto 0);
    signal   cnt_grp_d   : cnt_grp_delay_t;

    --counters
    signal cnt_grp   : std_logic_vector(log2_ceil_one(MAX_GRP_c) - 1 downto 0);
    signal cnt_index : std_logic_vector(log2_ceil_one(MAX_INDEX_c) - 1 downto 0);  --index into grp
    signal cnt_w_k   : unsigned(log2_ceil_one(ROM_PTS_c*3/4) downto 0);  -- k index in W_k^n

    -- addresses
    signal addr_real : unsigned(log2_ceil_one(MAX_INDEX_c) -1 downto 0);
    signal addr_imag : unsigned(log2_ceil_one(ROM_PTS_c/4) downto 0);

    -- std logic vector format of addr_real, addr_imag
    signal addr_real_s : std_logic_vector(ADDRWIDTH_c - 1 downto 0);
    signal addr_imag_s : std_logic_vector(ADDRWIDTH_c - 1 downto 0);


    --oeprations
    signal swap_op_addr : std_logic_vector(log2_ceil_one(MAX_INDEX_c) - 1 downto 0);
    signal negate_op_d  : negate_op_t;

    signal realtwid_s   : std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    signal imagtwid_s   : std_logic_vector(TWIDWIDTH_g - 1 downto 0);
    signal mem_enable   : std_logic;
    signal mem_enable_d : std_logic_vector(MEM_DELAY_c downto 0);

    signal set_imag_zero_d : std_logic_vector(MEM_DELAY_c+5 downto 0);

    signal start : std_logic;


    -- hyper optimization parameters
    signal cnt_w_k_en, cnt_w_k_reset_c, cnt_w_k_sel : std_logic;
    type cnt_w_k_array_type is array (3 downto 0) of std_logic_vector (cnt_w_k'high downto cnt_w_k'low);
    signal cnt_w_k_array, cnt_w_k_array_x2, cnt_w_k_max : cnt_w_k_array_type;
    
  begin  -- architecture rtl2 

    mem_enable <= enable;
    -- flag if this is the first block
    start_p : process (clk)
    begin  -- process start_p
      if rising_edge(clk) then 
        if reset = '1' then  
          start <= '1';
        elsif enable = '1' and rd_en = '1' then  
          start <= '0';
        end if;
      end if;
    end process start_p;

    gen_cnt_grp_natural_order: if (INPUT_FORMAT_g = "NATURAL_ORDER" or INPUT_FORMAT_g = "-N/2_to_N/2") and MAX_PWR_2_c = 0 generate
      -- start group required to be /= 0 for first frame in the natural order
      -- core otherwise cnt_grp will increment once too many times in the first
      -- frame
      cnt_grp <= std_logic_vector(to_unsigned(MAX_GRP_c, cnt_grp'length)) when start = '1' else
                -- std_logic_vector(to_unsigned(ZERO_GRP_c, cnt_grp'length)) when (unsigned(addr) = 0 and rd_en = '0') else
                 std_logic_vector(to_unsigned(ZERO_GRP_c, cnt_grp'length)) when (rd_en = '0') else
                 addr(addr'high downto (addr'length - cnt_grp'length));
      
    end generate gen_cnt_grp_natural_order;

    gen_cnt_grp_bit_reverse_order: if INPUT_FORMAT_g = "BIT_REVERSED" or MAX_PWR_2_c = 1  generate
      cnt_grp <=  std_logic_vector(to_unsigned(ZERO_GRP_c, cnt_grp'length)) when (unsigned(addr) = 0 and rd_en = '0') else
                addr(addr'high downto (addr'length - cnt_grp'length));
    end generate gen_cnt_grp_bit_reverse_order;
    cnt_index <= addr(cnt_index'length - 1 downto 0);



    gen_max_pwr_2 : if MAX_PWR_2_c = 1 generate
      signal rd_en_d : std_logic;
    begin

      rd_en_p : process (clk)
      begin  -- process rd_en_p
        if rising_edge(clk) then
          if reset = '1' then
            rd_en_d <= '0';
          elsif enable = '1' then
            rd_en_d <= rd_en;
          end if;
        end if;
      end process rd_en_p;

      cnt_w_k_en <= mem_enable;
      cnt_w_k_reset_c <= '1' when (unsigned(cnt_index) = MAX_INDEX_c and pwr_2 = '1') or
                         (unsigned(cnt_index) = MAX_INDEX_c - 1 and pwr_2 = '0') or
                         (rd_en_d = '0') or 
                         (unsigned(cnt_grp) = INVALID_GRP) else
                         '0';
      cnt_w_k_sel_proc : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            cnt_w_k_sel <= '0'; 
          elsif cnt_w_k_en = '1' then
            cnt_w_k_sel <= pwr_2;
          end if;
        end if;
      end process;
      cnt_array_gen : for j in 0 to MAX_GRP_c generate -- generate an array of counters with various step sizes
      begin
        cnt_w_k_max(j) <= std_logic_vector(to_unsigned(ROM_PTS_c*3/4 - K_INCREMENT_c(j),cnt_w_k'length));
        cnt_w_k_inst : counter_module
        generic map (COUNTER_WIDTH   => log2_ceil_one(ROM_PTS_c*3/4)+1,
                 COUNTER_STAGE_WIDTH => 4,
                 COUNT_STEP          => K_INCREMENT_c(j))
        port map (clk         => clk,
                  clken       => cnt_w_k_en,
                  reset       => reset,
                  reset_c     => cnt_w_k_reset_c,
                  reset_value => (others=>'0'),
                  counter_max => cnt_w_k_max(j),
                  counter_out => cnt_w_k_array(j));
        cnt_w_k_array_x2(j) <= cnt_w_k_array(j)(cnt_w_k'high-1 downto 0) & '0'; -- the increment x2 version of the counter
      end generate cnt_array_gen;
      --cnt_w_k <= unsigned(cnt_w_k_array_x2(to_integer(unsigned(cnt_grp)))) when cnt_w_k_sel = '0' else
      --             unsigned(cnt_w_k_array(to_integer(unsigned(cnt_grp))));
    cnt_reg_proc : process (clk)
    begin
      if rising_edge(clk) then
        if cnt_w_k_en = '1' then
          if cnt_w_k_sel = '0' then
            cnt_w_k <= unsigned(cnt_w_k_array_x2(to_integer(unsigned(cnt_grp))));
          else
            cnt_w_k <= unsigned(cnt_w_k_array(to_integer(unsigned(cnt_grp))));
          end if;
        end if;
      end if;
    end process;
    end generate gen_max_pwr_2;





    gen_non_pwr_2 : if MAX_PWR_2_c = 0 generate
    begin
      cnt_w_k_en <= mem_enable;
      cnt_w_k_reset_c <= '1' when (unsigned(cnt_index) = MAX_INDEX_c and pwr_2 = '0') or
                         (unsigned(cnt_index) = MAX_INDEX_c - 1 and pwr_2 = '1') or 
                         (unsigned(cnt_grp) = INVALID_GRP) else
                         '0';
      cnt_w_k_sel_proc : process (clk)
      begin
        if rising_edge(clk) then
          if reset = '1' then
            cnt_w_k_sel <= '0'; 
          elsif cnt_w_k_en = '1' then
            cnt_w_k_sel <= pwr_2;
          end if;
        end if;
      end process;
      cnt_array_gen : for j in 0 to MAX_GRP_c generate -- generate an array of counters with various step sizes
      begin
        cnt_w_k_max(j) <= std_logic_vector(to_unsigned(ROM_PTS_c*3/4 - K_INCREMENT_c(j),cnt_w_k'length));
        cnt_w_k_inst : counter_module
        generic map (COUNTER_WIDTH   => log2_ceil_one(ROM_PTS_c*3/4)+1,
                 COUNTER_STAGE_WIDTH => 4,
                 COUNT_STEP          => K_INCREMENT_c(j))
        port map (clk         => clk,
                  clken       => cnt_w_k_en,
                  reset       => reset,
                  reset_c     => cnt_w_k_reset_c,
                  reset_value => (others=>'0'),
                  counter_max => cnt_w_k_max(j),
                  counter_out => cnt_w_k_array(j));
        cnt_w_k_array_x2(j) <= cnt_w_k_array(j)(cnt_w_k'high-1 downto 0) & '0'; -- the increment x2 version of the counter
      end generate cnt_array_gen;
      --cnt_w_k <= unsigned(cnt_w_k_array_x2(to_integer(unsigned(cnt_grp)))) when cnt_w_k_sel = '1' else
      --             unsigned(cnt_w_k_array(to_integer(unsigned(cnt_grp))));
    cnt_reg_proc : process (clk)
    begin
      if rising_edge(clk) then
        if cnt_w_k_en = '1' then
          if cnt_w_k_sel = '1' then
            cnt_w_k <= unsigned(cnt_w_k_array_x2(to_integer(unsigned(cnt_grp))));
          else
            cnt_w_k <= unsigned(cnt_w_k_array(to_integer(unsigned(cnt_grp))));
          end if;
        end if;
      end if;
    end process;
      
    end generate gen_non_pwr_2;



    -- create the real and imag addresses from the counters
    -- addr_real is calculated by cnt_w_k rem MAX_INDEX
    addr_real <= resize(cnt_w_k, log2_ceil_one(MAX_INDEX_c));

    --addr_imag is calculated by (ROM_PTS_c/4 - addr_real)rem(ROM_PTS_c/4)
    addr_imag <= (ROM_PTS_c/4 - resize(addr_real, addr_imag'length));

    -- set imaginary data to 0, when addr_imag is ROM_PTS/4
    set_imag_zero_p : process (clk)
    begin  -- process set_imag_zero_p
      if rising_edge(clk) then
        if reset = '1' then
          set_imag_zero_d <= (others => '0');
        elsif mem_enable = '1' then
          if addr_real = 0 then
            set_imag_zero_d <= set_imag_zero_d(set_imag_zero_d'high - 1 downto 0) & '1';
          else
            set_imag_zero_d <= set_imag_zero_d(set_imag_zero_d'high - 1 downto 0) & '0';
          end if;
        end if;
      end if;
    end process set_imag_zero_p;



    -- indicates whether to swap the real and imaginary addresses
    swap_op_addr <= std_logic_vector(resize(cnt_w_k/(MAX_INDEX_c+1),log2_ceil_one(MAX_INDEX_c)));

    addr_real_s <= std_logic_vector(resize(addr_real, ADDRWIDTH_c)) when swap_op_addr(0) = '0' else
                   std_logic_vector(resize(addr_imag, ADDRWIDTH_c));
    addr_imag_s <= std_logic_vector(resize(addr_imag, ADDRWIDTH_c)) when swap_op_addr(0) = '0' else
                   std_logic_vector(resize(addr_real, ADDRWIDTH_c));


    single_port_rom_component_real : altera_fft_single_port_rom
      generic map (
        selected_device_family    => DEVICE_FAMILY_g,
        init_file                 => REALFILE_g,
        numwords                  => ROM_PTS_c/4 + 1,
        addr_width                => ADDRWIDTH_c,
        data_width                => TWIDWIDTH_g
        )
      port map (
        clocken0  => mem_enable,
        clock0    => clk,
        address_a => addr_real_s,
        q_a       => realtwid_s
        );
    single_port_rom_component_imag : altera_fft_single_port_rom
      generic map (
        selected_device_family    => DEVICE_FAMILY_g,
        init_file                 => REALFILE_g,
        numwords                  => ROM_PTS_c/4 + 1,
        addr_width                => ADDRWIDTH_c,
        data_width                => TWIDWIDTH_g
        )
      port map (
        clocken0  => mem_enable,
        clock0    => clk,
        address_a => addr_imag_s,
        q_a       => imagtwid_s
        );
    
    operations_p : process (clk)
    begin  -- process operations_p
      if rising_edge(clk) then
        if reset = '1' then
          negate_op_d <= (others => 0);
          cnt_grp_d   <= (others => (others => '0'));
        elsif mem_enable = '1' then
          negate_op_d(0) <= to_integer(cnt_w_k/(MAX_INDEX_c+1));
          cnt_grp_d(0)   <= cnt_grp;
          -- delay by 1
          for i in 1 to 1 loop
            negate_op_d(i) <= negate_op_d(i-1);
          end loop;  -- i
          for j in 1 to MEM_DELAY_c loop
            cnt_grp_d(j) <= cnt_grp_d(j-1);
          end loop;
        end if;
      end if;
    end process operations_p;

    -- perform operations on data from memory
    -- negate
    reg_negate_op : process (clk)
    begin  -- process reg_negate_op
      if rising_edge(clk) then
        if reset = '1' then
          realtwid <= (others => '0');
          imagtwid <= (others => '0');
        elsif mem_enable = '1' then
          if unsigned(cnt_grp_d(MEM_DELAY_c)) = ZERO_GRP_c then
            realtwid <= ONE_REPRESENTATION_c;
          elsif (negate_op_d(1) = 1 or negate_op_d(1) = 2) then
            if REPRESENTATION_g = "FIXEDPT" then
              realtwid <= std_logic_vector(resize(-1*signed(realtwid_s), realtwid'length));
            else
              realtwid <=  '1' & realtwid_s(30 downto 0);
            end if;
          else
            realtwid <= realtwid_s;
          end if;
          if unsigned(cnt_grp_d(MEM_DELAY_c)) = ZERO_GRP_c then
            imagtwid <= (others => '0');
          elsif (negate_op_d(1) = 0 or negate_op_d(1) = 1) then
           if REPRESENTATION_g = "FIXEDPT" then
             imagtwid <= std_logic_vector(resize(-1*signed(imagtwid_s), imagtwid'length));
           else
              imagtwid <=  '1' & imagtwid_s(30 downto 0);
            end if;
          else
            imagtwid <= imagtwid_s;
          end if;
        end if;
      end if;
    end process reg_negate_op;

  end generate gen_optimized_memory_delayed;



  
end rtl;
