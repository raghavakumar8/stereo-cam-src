`timescale 1ns/1ns

module testbench();
	reg		clk;
	reg		reset;

	// =================================
	//   RUN STUFF
	// =================================

	reg go;

	// Setup clock, reset
	initial begin
		clk = 1'b0;
		go = 1'b1;
		
		// Keep reset on for a couple of cycles
		reset = 1'b0;
		#10
		reset = 1'b1;
		#30
		reset = 1'b0;
	end

	// Run clock
	always begin
		#10
		clk = !clk;
	end

	localparam row_sz = 450;
	localparam col_sz = 375;

	// Instantiate cameras
	wire			pclk0;
	wire	[7:0]	cam0_val;
	wire	[9:0]	cam0_x;
	wire	[9:0]	cam0_y;
	wire			is_cam0_val;

	cam_sim #(0,row_sz,col_sz) my_cam0(
		.clk(clk),
		.reset(reset),
		.pclk(pclk0),
		.value(cam0_val),
		.x(cam0_x),
		.y(cam0_y),
		.is_val(is_cam0_val)
	);

	wire			pclk1;
	wire	[7:0]	cam1_val;
	wire	[9:0]	cam1_x;
	wire	[9:0]	cam1_y;
	wire			is_cam1_val;

	cam_sim #(1,row_sz,col_sz) my_cam1(
		.clk(clk),
		.reset(reset),
		.pclk(pclk1),
		.value(cam1_val),
		.x(cam1_x),
		.y(cam1_y),
		.is_val(is_cam1_val)
	);

	// Instantiate convolve modules
	/*wire	[7:0]	conv_val;
	wire	[9:0]	conv_x;
	wire	[9:0]	conv_y;
	wire			is_conv_val;

	convolve #(3,320,240) my_convolver(
		.clk(pclk),
		.reset(reset),

		.in_val(cam_val),
		.in_x(cam_x),
		.in_y(cam_y),
		.is_in_val(is_cam_val),

		.out_val(conv_val),
		.out_x(conv_x),
		.out_y(conv_y),
		.is_out_val(is_conv_val),

		// Convolution kernel represented as a single bit vector
		//.kernel({8'h01, 8'h02, 8'h01,
		//		 8'h02, 8'h04, 8'h02,
		//		 8'h01, 8'h02, 8'h01})
		.kernel({8'h00, 8'h00, 8'h00,
				 8'h00, 8'h10, 8'h00,
				 8'h00, 8'h00, 8'h00})
	);*/

	// Instantiate census modules
	wire	[7:0]	cen0_val;
	wire	[9:0]	cen0_x;
	wire	[9:0]	cen0_y;
	wire			is_cen0_val;

	sp_census #(row_sz,col_sz) my_census0(
		.clk(pclk0),
		.reset(reset),
		.in_val(cam0_val),
		.in_x(cam0_x),
		.in_y(cam0_y),
		.is_in_val(is_cam0_val),
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
		.clk(pclk1),
		.reset(reset),
		.in_val(cam1_val),
		.in_x(cam1_x),
		.in_y(cam1_y),
		.is_in_val(is_cam1_val),
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
		.clk(pclk0),
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
		.clk(pclk1),
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
	wire	[9:0]	out_x;
	wire	[9:0]	out_y;
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

		.out_x(out_x),
		.out_y(out_y),
		.disparity_val(is_disp_out_val),
		.disparity(disp_out_val)
	);

	vga_buf_sim my_vga(
		.pclk(pclk0),
		.reset(reset),
		.value({disp_out_val, 2'b00}),
		.x(out_x),
		.y(out_y),
		.is_val(is_disp_out_val)
	);

	// Print statements, etc
	initial begin
		#100
		$display("Yoooooooooo");
	end
endmodule