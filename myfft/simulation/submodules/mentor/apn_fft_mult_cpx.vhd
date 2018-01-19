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


--complex multiplication
--(a+j*b)*(c+j*d) = (a*c-b*d)+j*(a*d+b*c)

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity apn_fft_mult_cpx is  
    generic (
        mpr		: integer := 27;
        twr		: integer := 25
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
end apn_fft_mult_cpx;

architecture rtl of apn_fft_mult_cpx is

    signal a_reg : signed(mpr-1 downto 0);
    signal b_reg : signed(mpr-1 downto 0);
    signal c_reg : signed(twr-1 downto 0);
    signal d_reg : signed(twr-1 downto 0);
    signal rout_sig  : signed(mpr+twr downto 0);
    signal iout_sig  : signed(mpr+twr downto 0);
    signal rout_sig2 : signed(mpr+twr downto 0);
    signal iout_sig2 : signed(mpr+twr downto 0);

begin

    process (clk, global_clock_enable, reset)
    begin
        if reset = '1' then
            a_reg <= (others => '0');
            b_reg <= (others => '0');
            c_reg <= (others => '0');
            d_reg <= (others => '0');
            rout_sig   <= (others => '0');
            iout_sig   <= (others => '0');
            rout_sig2  <= (others => '0');
            iout_sig2  <= (others => '0');
        elsif clk'event and clk = '1' and global_clock_enable = '1' then
            a_reg <= signed(a);
            b_reg <= signed(b);
            c_reg <= signed(c);
            d_reg <= signed(d);
            rout_sig   <= resize((a_reg*c_reg),rout_sig'length) - resize((b_reg*d_reg),rout_sig'length);
            iout_sig   <= resize((a_reg*d_reg),iout_sig'length) + resize((b_reg*c_reg),iout_sig'length);
            rout_sig2  <= rout_sig;
            iout_sig2  <= iout_sig;
	    end if;
    end process;

    rout <= std_logic_vector(rout_sig2);
    iout <= std_logic_vector(iout_sig2);

end rtl;

