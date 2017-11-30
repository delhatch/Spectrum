	component myfft is
		port (
			clk          : in  std_logic                     := 'X';             -- clk
			reset_n      : in  std_logic                     := 'X';             -- reset_n
			sink_valid   : in  std_logic                     := 'X';             -- sink_valid
			sink_ready   : out std_logic;                                        -- sink_ready
			sink_error   : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- sink_error
			sink_sop     : in  std_logic                     := 'X';             -- sink_sop
			sink_eop     : in  std_logic                     := 'X';             -- sink_eop
			sink_real    : in  std_logic_vector(15 downto 0) := (others => 'X'); -- sink_real
			sink_imag    : in  std_logic_vector(15 downto 0) := (others => 'X'); -- sink_imag
			fftpts_in    : in  std_logic_vector(9 downto 0)  := (others => 'X'); -- fftpts_in
			inverse      : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- inverse
			source_valid : out std_logic;                                        -- source_valid
			source_ready : in  std_logic                     := 'X';             -- source_ready
			source_error : out std_logic_vector(1 downto 0);                     -- source_error
			source_sop   : out std_logic;                                        -- source_sop
			source_eop   : out std_logic;                                        -- source_eop
			source_real  : out std_logic_vector(15 downto 0);                    -- source_real
			source_imag  : out std_logic_vector(15 downto 0);                    -- source_imag
			fftpts_out   : out std_logic_vector(9 downto 0)                      -- fftpts_out
		);
	end component myfft;

	u0 : component myfft
		port map (
			clk          => CONNECTED_TO_clk,          --    clk.clk
			reset_n      => CONNECTED_TO_reset_n,      --    rst.reset_n
			sink_valid   => CONNECTED_TO_sink_valid,   --   sink.sink_valid
			sink_ready   => CONNECTED_TO_sink_ready,   --       .sink_ready
			sink_error   => CONNECTED_TO_sink_error,   --       .sink_error
			sink_sop     => CONNECTED_TO_sink_sop,     --       .sink_sop
			sink_eop     => CONNECTED_TO_sink_eop,     --       .sink_eop
			sink_real    => CONNECTED_TO_sink_real,    --       .sink_real
			sink_imag    => CONNECTED_TO_sink_imag,    --       .sink_imag
			fftpts_in    => CONNECTED_TO_fftpts_in,    --       .fftpts_in
			inverse      => CONNECTED_TO_inverse,      --       .inverse
			source_valid => CONNECTED_TO_source_valid, -- source.source_valid
			source_ready => CONNECTED_TO_source_ready, --       .source_ready
			source_error => CONNECTED_TO_source_error, --       .source_error
			source_sop   => CONNECTED_TO_source_sop,   --       .source_sop
			source_eop   => CONNECTED_TO_source_eop,   --       .source_eop
			source_real  => CONNECTED_TO_source_real,  --       .source_real
			source_imag  => CONNECTED_TO_source_imag,  --       .source_imag
			fftpts_out   => CONNECTED_TO_fftpts_out    --       .fftpts_out
		);

