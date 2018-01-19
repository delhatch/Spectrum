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


--complex multiplication using 3 multipliers
--(a+j*b)*(c+j*d) = (c-d)*a+(a-b)*d+j*((c+d)*b+(a-b)*d))

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity apn_fft_mult_can is  
    generic (
        mpr		: integer := 25;
        twr		: integer := 18
	 );
    port (
    	clk     : in  std_logic;
      reset   : in  std_logic;
    	global_clock_enable : in  std_logic;
    	a       : in  std_logic_vector(mpr-1 downto 0);
    	b       : in  std_logic_vector(mpr-1 downto 0);
    	c       : in  std_logic_vector(twr-1 downto 0);
    	d       : in  std_logic_vector(twr-1 downto 0);
    	rout    : out std_logic_vector(mpr+twr downto 0);
    	iout    : out std_logic_vector(mpr+twr downto 0)
    );
end apn_fft_mult_can;

architecture rtl of apn_fft_mult_can is

    signal a_reg : signed(mpr-1 downto 0);
    signal b_reg : signed(mpr-1 downto 0);
    signal c_reg : signed(twr-1 downto 0);
    signal d_reg : signed(twr-1 downto 0);
	 signal p1    : signed(mpr downto 0);
	 signal p2    : signed(twr downto 0);
	 signal p3    : signed(twr downto 0);
	 signal m1    : signed(mpr+twr downto 0);
	 signal m2    : signed(mpr+twr downto 0);
	 signal m3    : signed(mpr+twr downto 0);
	 signal m1_reg: signed(mpr+twr downto 0);
	 signal m2_reg: signed(mpr+twr downto 0);
	 signal m3_reg: signed(mpr+twr downto 0);
    signal rout_sig  : signed(mpr+twr downto 0);
    signal iout_sig  : signed(mpr+twr downto 0);

begin

    p1 <= resize(a_reg,p1'length) - resize(b_reg,p1'length);
	 m1 <= p1 * d_reg;
	 p2 <= resize(c_reg,p2'length) - resize(d_reg,p2'length);
	 m2 <= p2 * a_reg;
	 p3 <= resize(c_reg,p3'length) + resize(d_reg,p3'length);
	 m3 <= p3 * b_reg;
	 
	 process (clk, global_clock_enable, reset)
    begin
        if reset = '1' then
            a_reg <= (others => '0');
            b_reg <= (others => '0');
            c_reg <= (others => '0');
            d_reg <= (others => '0');
            m1_reg <= (others => '0');
            m2_reg <= (others => '0');
            m3_reg <= (others => '0');
            rout_sig   <= (others => '0');
            iout_sig   <= (others => '0');
        elsif clk'event and clk = '1' and global_clock_enable = '1' then
            a_reg <= signed(a);
            b_reg <= signed(b);
            c_reg <= signed(c);
            d_reg <= signed(d);
            m1_reg <= signed(m1);
            m2_reg <= signed(m2);
            m3_reg <= signed(m3);
	    rout_sig   <= resize(m1_reg,rout_sig'length) + resize(m2_reg,rout_sig'length);
            iout_sig   <= resize(m1_reg,iout_sig'length) + resize(m3_reg,iout_sig'length);
	    end if;
    end process;

    rout <= std_logic_vector(rout_sig);
    iout <= std_logic_vector(iout_sig);

end rtl;

