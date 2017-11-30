
module DE2_115_SOPC (
	audio_global_signals_export_adcdata,
	audio_global_signals_export_adclrc,
	audio_global_signals_export_bclk,
	audio_global_signals_export_fft_clk,
	audio_global_signals_export_debug,
	altpll_sys,
	altpll_io,
	clk_50,
	reset_n,
	LCD_RS_from_the_lcd,
	LCD_RW_from_the_lcd,
	LCD_data_to_and_from_the_lcd,
	LCD_E_from_the_lcd,
	altpll_sdram,
	altpll_25,
	locked_from_the_pll,
	zs_addr_from_the_sdram,
	zs_ba_from_the_sdram,
	zs_cas_n_from_the_sdram,
	zs_cke_from_the_sdram,
	zs_cs_n_from_the_sdram,
	zs_dq_to_and_from_the_sdram,
	zs_dqm_from_the_sdram,
	zs_ras_n_from_the_sdram,
	zs_we_n_from_the_sdram,
	SRAM_DQ_to_and_from_the_sram,
	SRAM_ADDR_from_the_sram,
	SRAM_UB_n_from_the_sram,
	SRAM_LB_n_from_the_sram,
	SRAM_WE_n_from_the_sram,
	SRAM_CE_n_from_the_sram,
	SRAM_OE_n_from_the_sram,
	avs_s1_export_VGA_R_from_the_vpg,
	avs_s1_export_VGA_G_from_the_vpg,
	avs_s1_export_VGA_B_from_the_vpg,
	avs_s1_export_VGA_HS_from_the_vpg,
	avs_s1_export_VGA_VS_from_the_vpg,
	avs_s1_export_VGA_SYNC_from_the_vpg,
	avs_s1_export_VGA_BLANK_from_the_vpg,
	avs_s1_export_VGA_CLK_from_the_vpg,
	avs_s1_export_iCLK_25_to_the_vpg);	

	input		audio_global_signals_export_adcdata;
	input		audio_global_signals_export_adclrc;
	input		audio_global_signals_export_bclk;
	input		audio_global_signals_export_fft_clk;
	output	[9:0]	audio_global_signals_export_debug;
	output		altpll_sys;
	output		altpll_io;
	input		clk_50;
	input		reset_n;
	output		LCD_RS_from_the_lcd;
	output		LCD_RW_from_the_lcd;
	inout	[7:0]	LCD_data_to_and_from_the_lcd;
	output		LCD_E_from_the_lcd;
	output		altpll_sdram;
	output		altpll_25;
	output		locked_from_the_pll;
	output	[12:0]	zs_addr_from_the_sdram;
	output	[1:0]	zs_ba_from_the_sdram;
	output		zs_cas_n_from_the_sdram;
	output		zs_cke_from_the_sdram;
	output		zs_cs_n_from_the_sdram;
	inout	[31:0]	zs_dq_to_and_from_the_sdram;
	output	[3:0]	zs_dqm_from_the_sdram;
	output		zs_ras_n_from_the_sdram;
	output		zs_we_n_from_the_sdram;
	inout	[15:0]	SRAM_DQ_to_and_from_the_sram;
	output	[19:0]	SRAM_ADDR_from_the_sram;
	output		SRAM_UB_n_from_the_sram;
	output		SRAM_LB_n_from_the_sram;
	output		SRAM_WE_n_from_the_sram;
	output		SRAM_CE_n_from_the_sram;
	output		SRAM_OE_n_from_the_sram;
	output	[9:0]	avs_s1_export_VGA_R_from_the_vpg;
	output	[9:0]	avs_s1_export_VGA_G_from_the_vpg;
	output	[9:0]	avs_s1_export_VGA_B_from_the_vpg;
	output		avs_s1_export_VGA_HS_from_the_vpg;
	output		avs_s1_export_VGA_VS_from_the_vpg;
	output		avs_s1_export_VGA_SYNC_from_the_vpg;
	output		avs_s1_export_VGA_BLANK_from_the_vpg;
	output		avs_s1_export_VGA_CLK_from_the_vpg;
	input		avs_s1_export_iCLK_25_to_the_vpg;
endmodule
