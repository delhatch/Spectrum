	myfft u0 (
		.clk          (<connected-to-clk>),          //    clk.clk
		.reset_n      (<connected-to-reset_n>),      //    rst.reset_n
		.sink_valid   (<connected-to-sink_valid>),   //   sink.sink_valid
		.sink_ready   (<connected-to-sink_ready>),   //       .sink_ready
		.sink_error   (<connected-to-sink_error>),   //       .sink_error
		.sink_sop     (<connected-to-sink_sop>),     //       .sink_sop
		.sink_eop     (<connected-to-sink_eop>),     //       .sink_eop
		.sink_real    (<connected-to-sink_real>),    //       .sink_real
		.sink_imag    (<connected-to-sink_imag>),    //       .sink_imag
		.fftpts_in    (<connected-to-fftpts_in>),    //       .fftpts_in
		.inverse      (<connected-to-inverse>),      //       .inverse
		.source_valid (<connected-to-source_valid>), // source.source_valid
		.source_ready (<connected-to-source_ready>), //       .source_ready
		.source_error (<connected-to-source_error>), //       .source_error
		.source_sop   (<connected-to-source_sop>),   //       .source_sop
		.source_eop   (<connected-to-source_eop>),   //       .source_eop
		.source_real  (<connected-to-source_real>),  //       .source_real
		.source_imag  (<connected-to-source_imag>),  //       .source_imag
		.fftpts_out   (<connected-to-fftpts_out>)    //       .fftpts_out
	);

