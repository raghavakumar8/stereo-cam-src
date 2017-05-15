module stereo(
	input				clk,
	input				reset,
	input		[7:0] 	census_thresh,
	input		[9:0]	in_x,
	input		[9:0]	in_y,
	input		[7:0]	in_left,
	input		[7:0]	in_right,
	input				in_is_val,

	output		[9:0]	out_x,
	output		[9:0]	out_y,
	output		[7:0]	out_stereo,
	output				out_is_val,

	// Debug and demo interfaces (connects to VGA)
	input		[1:0]	debug_selector,
	output		[9:0]	debug_out_x,
	output		[9:0]	debug_out_y,
	output		[7:0]	debug_out,
	output				debug_out_is_val
);
	localparam row_sz = 447;
	localparam col_sz = 370;

	// Instantiate convolve modules
	wire	[7:0]	conv0_val;
	wire	[9:0]	conv0_x;
	wire	[9:0]	conv0_y;
	wire			is_conv0_val;

	convolve #(3,row_sz,col_sz) my_convolver0(
		.clk(clk),
		.reset(reset),

		.in_val(in_left),
		.in_x(in_x),
		.in_y(in_y),
		.is_in_val(in_is_val),

		.out_val(conv0_val),
		.out_x(conv0_x),
		.out_y(conv0_y),
		.is_out_val(is_conv0_val),

		// Convolution kernel represented as a single bit vector
		.kernel({8'h01, 8'h02, 8'h01,
				 8'h02, 8'h04, 8'h02,
				 8'h01, 8'h02, 8'h01})
	);

	wire	[7:0]	conv1_val;
	wire	[9:0]	conv1_x;
	wire	[9:0]	conv1_y;
	wire			is_conv1_val;

	convolve #(3,row_sz,col_sz) my_convolver1(
		.clk(clk),
		.reset(reset),

		.in_val(in_right),
		.in_x(in_x),
		.in_y(in_y),
		.is_in_val(in_is_val),

		.out_val(conv1_val),
		.out_x(conv1_x),
		.out_y(conv1_y),
		.is_out_val(is_conv1_val),

		// Convolution kernel represented as a single bit vector
		.kernel({8'h01, 8'h02, 8'h01,
				 8'h02, 8'h04, 8'h02,
				 8'h01, 8'h02, 8'h01})
	);

	// Instantiate census modules
	wire	[7:0]	cen0_val;
	wire	[9:0]	cen0_x;
	wire	[9:0]	cen0_y;
	wire			is_cen0_val;

	sp_census #(row_sz,col_sz) my_census0(
		.clk(clk),
		.reset(reset),
		.thresh(census_thresh),
		.in_val(conv0_val),
		.in_x(conv0_x),
		.in_y(conv0_y),
		.is_in_val(is_conv0_val),
		.out_val(cen0_val),
		.out_x(cen0_x),
		.out_y(cen0_y),
		.is_out_val(is_cen0_val)
	);

	wire	[7:0]	cen1_val;
	wire	[9:0]	cen1_x;
	wire	[9:0]	cen1_y;
	wire			is_cen1_val;

	sp_census #(row_sz,col_sz) my_census1(
		.clk(clk),
		.reset(reset),
		.thresh(census_thresh),
		.in_val(conv1_val),
		.in_x(conv1_x),
		.in_y(conv1_y),
		.is_in_val(is_conv1_val),
		.out_val(cen1_val),
		.out_x(cen1_x),
		.out_y(cen1_y),
		.is_out_val(is_cen1_val)
	);

	// Instantiate windowing modules
	wire	[71:0]	wdw0_val;
	wire	[9:0]	wdw0_x;
	wire	[9:0]	wdw0_y;
	wire			is_wdw0_val;

	census_window #(3,row_sz,col_sz) my_wdw0(
		.clk(clk),
		.reset(reset),

		.in_val(cen0_val),
		.in_x(cen0_x),
		.in_y(cen0_y),
		.is_in_val(is_cen0_val),

		.out_val(wdw0_val),
		.out_x(wdw0_x),
		.out_y(wdw0_y),
		.is_out_val(is_wdw0_val)
	);

	wire	[71:0]	wdw1_val;
	wire	[9:0]	wdw1_x;
	wire	[9:0]	wdw1_y;
	wire			is_wdw1_val;

	census_window #(3,row_sz,col_sz) my_wdw1(
		.clk(clk),
		.reset(reset),

		.in_val(cen1_val),
		.in_x(cen1_x),
		.in_y(cen1_y),
		.is_in_val(is_cen1_val),

		.out_val(wdw1_val),
		.out_x(wdw1_x),
		.out_y(wdw1_y),
		.is_out_val(is_wdw1_val)
	);

	// Instantiate correlation module
	wire	[9:0]	corr_out_x;
	wire	[9:0]	corr_out_y;
	wire	[5:0]	disp_out_val;
	wire			is_disp_out_val;
	correlate #(row_sz, col_sz) my_corr(
		.clk(clk),
		.reset(reset),

		.left_bitvec(wdw0_val),
		.right_bitvec(wdw1_val),
		.bitvec_val(is_wdw0_val & is_wdw1_val),

		.input_x(wdw0_x),
		.input_y(wdw0_y),

		.out_x(corr_out_x),
		.out_y(corr_out_y),
		.disparity_val(is_disp_out_val),
		.disparity(disp_out_val)
	);

	assign out_x 		= corr_out_x;
	assign out_y 		= corr_out_y;
	assign out_stereo	= {disp_out_val, 2'b0};
	assign out_is_val	= is_disp_out_val;

	// Debugging outputs
	reg		[9:0]	debug_out_x_reg;
	reg		[9:0]	debug_out_y_reg;
	reg		[7:0]	debug_out_reg;
	reg				debug_out_is_val_reg;

	assign debug_out_x 		= debug_out_x_reg;
	assign debug_out_y 		= debug_out_y_reg;
	assign debug_out		= debug_out_reg;
	assign debug_out_is_val	= debug_out_is_val_reg;

	always @(*) begin
		case (debug_selector)
			2'd0: begin
				debug_out_x_reg 		= in_x;
				debug_out_y_reg 		= in_y;
				debug_out_reg 			= in_right;
				debug_out_is_val_reg	= in_is_val;
			end
			2'd1: begin
				debug_out_x_reg 		= conv1_x;
				debug_out_y_reg 		= conv1_y;
				debug_out_reg 			= conv1_val;
				debug_out_is_val_reg	= is_conv1_val;
			end
			2'd2: begin
				debug_out_x_reg 		= cen1_x;
				debug_out_y_reg 		= cen1_y;
				debug_out_reg 			= cen1_val;
				debug_out_is_val_reg	= is_cen1_val;
			end
			2'd3: begin
				debug_out_x_reg 		= corr_out_x;
				debug_out_y_reg 		= corr_out_y;
				debug_out_reg 			= {disp_out_val, 2'b0};
				debug_out_is_val_reg	= is_disp_out_val;
			end
			default: begin
				debug_out_x_reg 		= corr_out_x;
				debug_out_y_reg 		= corr_out_y;
				debug_out_reg 			= {disp_out_val, 2'b0};
				debug_out_is_val_reg	= is_disp_out_val;
			end
		endcase
	end
endmodule