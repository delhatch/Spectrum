	component DE2_115_SOPC is
		port (
			audio_global_signals_export_adcdata  : in    std_logic                     := 'X';             -- export_adcdata
			audio_global_signals_export_adclrc   : in    std_logic                     := 'X';             -- export_adclrc
			audio_global_signals_export_bclk     : in    std_logic                     := 'X';             -- export_bclk
			audio_global_signals_export_fft_clk  : in    std_logic                     := 'X';             -- export_fft_clk
			audio_global_signals_export_debug    : out   std_logic_vector(9 downto 0);                     -- export_debug
			altpll_sys                           : out   std_logic;                                        -- clk
			altpll_io                            : out   std_logic;                                        -- clk
			clk_50                               : in    std_logic                     := 'X';             -- clk
			reset_n                              : in    std_logic                     := 'X';             -- reset_n
			LCD_RS_from_the_lcd                  : out   std_logic;                                        -- RS
			LCD_RW_from_the_lcd                  : out   std_logic;                                        -- RW
			LCD_data_to_and_from_the_lcd         : inout std_logic_vector(7 downto 0)  := (others => 'X'); -- data
			LCD_E_from_the_lcd                   : out   std_logic;                                        -- E
			altpll_sdram                         : out   std_logic;                                        -- clk
			altpll_25                            : out   std_logic;                                        -- clk
			locked_from_the_pll                  : out   std_logic;                                        -- export
			zs_addr_from_the_sdram               : out   std_logic_vector(12 downto 0);                    -- addr
			zs_ba_from_the_sdram                 : out   std_logic_vector(1 downto 0);                     -- ba
			zs_cas_n_from_the_sdram              : out   std_logic;                                        -- cas_n
			zs_cke_from_the_sdram                : out   std_logic;                                        -- cke
			zs_cs_n_from_the_sdram               : out   std_logic;                                        -- cs_n
			zs_dq_to_and_from_the_sdram          : inout std_logic_vector(31 downto 0) := (others => 'X'); -- dq
			zs_dqm_from_the_sdram                : out   std_logic_vector(3 downto 0);                     -- dqm
			zs_ras_n_from_the_sdram              : out   std_logic;                                        -- ras_n
			zs_we_n_from_the_sdram               : out   std_logic;                                        -- we_n
			SRAM_DQ_to_and_from_the_sram         : inout std_logic_vector(15 downto 0) := (others => 'X'); -- DQ
			SRAM_ADDR_from_the_sram              : out   std_logic_vector(19 downto 0);                    -- ADDR
			SRAM_UB_n_from_the_sram              : out   std_logic;                                        -- UB_n
			SRAM_LB_n_from_the_sram              : out   std_logic;                                        -- LB_n
			SRAM_WE_n_from_the_sram              : out   std_logic;                                        -- WE_n
			SRAM_CE_n_from_the_sram              : out   std_logic;                                        -- CE_n
			SRAM_OE_n_from_the_sram              : out   std_logic;                                        -- OE_n
			avs_s1_export_VGA_R_from_the_vpg     : out   std_logic_vector(9 downto 0);                     -- VGA_R
			avs_s1_export_VGA_G_from_the_vpg     : out   std_logic_vector(9 downto 0);                     -- VGA_G
			avs_s1_export_VGA_B_from_the_vpg     : out   std_logic_vector(9 downto 0);                     -- VGA_B
			avs_s1_export_VGA_HS_from_the_vpg    : out   std_logic;                                        -- VGA_HS
			avs_s1_export_VGA_VS_from_the_vpg    : out   std_logic;                                        -- VGA_VS
			avs_s1_export_VGA_SYNC_from_the_vpg  : out   std_logic;                                        -- VGA_SYNC
			avs_s1_export_VGA_BLANK_from_the_vpg : out   std_logic;                                        -- VGA_BLANK
			avs_s1_export_VGA_CLK_from_the_vpg   : out   std_logic;                                        -- VGA_CLK
			avs_s1_export_iCLK_25_to_the_vpg     : in    std_logic                     := 'X'              -- iCLK_25
		);
	end component DE2_115_SOPC;

	u0 : component DE2_115_SOPC
		port map (
			audio_global_signals_export_adcdata  => CONNECTED_TO_audio_global_signals_export_adcdata,  --      audio_global_signals.export_adcdata
			audio_global_signals_export_adclrc   => CONNECTED_TO_audio_global_signals_export_adclrc,   --                          .export_adclrc
			audio_global_signals_export_bclk     => CONNECTED_TO_audio_global_signals_export_bclk,     --                          .export_bclk
			audio_global_signals_export_fft_clk  => CONNECTED_TO_audio_global_signals_export_fft_clk,  --                          .export_fft_clk
			audio_global_signals_export_debug    => CONNECTED_TO_audio_global_signals_export_debug,    --                          .export_debug
			altpll_sys                           => CONNECTED_TO_altpll_sys,                           --                c0_out_clk.clk
			altpll_io                            => CONNECTED_TO_altpll_io,                            --                c2_out_clk.clk
			clk_50                               => CONNECTED_TO_clk_50,                               --             clk_50_clk_in.clk
			reset_n                              => CONNECTED_TO_reset_n,                              --       clk_50_clk_in_reset.reset_n
			LCD_RS_from_the_lcd                  => CONNECTED_TO_LCD_RS_from_the_lcd,                  --              lcd_external.RS
			LCD_RW_from_the_lcd                  => CONNECTED_TO_LCD_RW_from_the_lcd,                  --                          .RW
			LCD_data_to_and_from_the_lcd         => CONNECTED_TO_LCD_data_to_and_from_the_lcd,         --                          .data
			LCD_E_from_the_lcd                   => CONNECTED_TO_LCD_E_from_the_lcd,                   --                          .E
			altpll_sdram                         => CONNECTED_TO_altpll_sdram,                         --                    pll_c1.clk
			altpll_25                            => CONNECTED_TO_altpll_25,                            --                    pll_c3.clk
			locked_from_the_pll                  => CONNECTED_TO_locked_from_the_pll,                  --        pll_locked_conduit.export
			zs_addr_from_the_sdram               => CONNECTED_TO_zs_addr_from_the_sdram,               --                sdram_wire.addr
			zs_ba_from_the_sdram                 => CONNECTED_TO_zs_ba_from_the_sdram,                 --                          .ba
			zs_cas_n_from_the_sdram              => CONNECTED_TO_zs_cas_n_from_the_sdram,              --                          .cas_n
			zs_cke_from_the_sdram                => CONNECTED_TO_zs_cke_from_the_sdram,                --                          .cke
			zs_cs_n_from_the_sdram               => CONNECTED_TO_zs_cs_n_from_the_sdram,               --                          .cs_n
			zs_dq_to_and_from_the_sdram          => CONNECTED_TO_zs_dq_to_and_from_the_sdram,          --                          .dq
			zs_dqm_from_the_sdram                => CONNECTED_TO_zs_dqm_from_the_sdram,                --                          .dqm
			zs_ras_n_from_the_sdram              => CONNECTED_TO_zs_ras_n_from_the_sdram,              --                          .ras_n
			zs_we_n_from_the_sdram               => CONNECTED_TO_zs_we_n_from_the_sdram,               --                          .we_n
			SRAM_DQ_to_and_from_the_sram         => CONNECTED_TO_SRAM_DQ_to_and_from_the_sram,         --          sram_conduit_end.DQ
			SRAM_ADDR_from_the_sram              => CONNECTED_TO_SRAM_ADDR_from_the_sram,              --                          .ADDR
			SRAM_UB_n_from_the_sram              => CONNECTED_TO_SRAM_UB_n_from_the_sram,              --                          .UB_n
			SRAM_LB_n_from_the_sram              => CONNECTED_TO_SRAM_LB_n_from_the_sram,              --                          .LB_n
			SRAM_WE_n_from_the_sram              => CONNECTED_TO_SRAM_WE_n_from_the_sram,              --                          .WE_n
			SRAM_CE_n_from_the_sram              => CONNECTED_TO_SRAM_CE_n_from_the_sram,              --                          .CE_n
			SRAM_OE_n_from_the_sram              => CONNECTED_TO_SRAM_OE_n_from_the_sram,              --                          .OE_n
			avs_s1_export_VGA_R_from_the_vpg     => CONNECTED_TO_avs_s1_export_VGA_R_from_the_vpg,     -- vpg_global_signals_export.VGA_R
			avs_s1_export_VGA_G_from_the_vpg     => CONNECTED_TO_avs_s1_export_VGA_G_from_the_vpg,     --                          .VGA_G
			avs_s1_export_VGA_B_from_the_vpg     => CONNECTED_TO_avs_s1_export_VGA_B_from_the_vpg,     --                          .VGA_B
			avs_s1_export_VGA_HS_from_the_vpg    => CONNECTED_TO_avs_s1_export_VGA_HS_from_the_vpg,    --                          .VGA_HS
			avs_s1_export_VGA_VS_from_the_vpg    => CONNECTED_TO_avs_s1_export_VGA_VS_from_the_vpg,    --                          .VGA_VS
			avs_s1_export_VGA_SYNC_from_the_vpg  => CONNECTED_TO_avs_s1_export_VGA_SYNC_from_the_vpg,  --                          .VGA_SYNC
			avs_s1_export_VGA_BLANK_from_the_vpg => CONNECTED_TO_avs_s1_export_VGA_BLANK_from_the_vpg, --                          .VGA_BLANK
			avs_s1_export_VGA_CLK_from_the_vpg   => CONNECTED_TO_avs_s1_export_VGA_CLK_from_the_vpg,   --                          .VGA_CLK
			avs_s1_export_iCLK_25_to_the_vpg     => CONNECTED_TO_avs_s1_export_iCLK_25_to_the_vpg      --                          .iCLK_25
		);

