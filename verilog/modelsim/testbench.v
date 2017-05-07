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

	// Local wires
	wire			pclk;
	wire	[7:0]	cam_val;
	wire	[9:0]	cam_x;
	wire	[9:0]	cam_y;
	wire			is_cam_val;

	cam_sim my_cam(
		.clk(clk),
		.reset(reset),
		.pclk(pclk),
		.value(cam_val),
		.x(cam_x),
		.y(cam_y),
		.is_val(is_cam_val)
	);

	wire	[7:0]	conv_val;
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
		.kernel({8'h01, 8'h02, 8'h01,
				 8'h02, 8'h04, 8'h02,
				 8'h01, 8'h02, 8'h01})
	);

	vga_buf_sim my_vga(
		.pclk(pclk),
		.reset(reset),
		.value(conv_val),
		.x(conv_x),
		.y(conv_y),
		.is_val(is_conv_val)
	);

	// Print statements, etc
	initial begin
		#100
		$display("Yoooooooooo");
	end
endmodule