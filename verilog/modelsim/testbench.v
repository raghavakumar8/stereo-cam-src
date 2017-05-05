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
	wire	[7:0]	value;
	wire	[9:0]	x;
	wire	[9:0]	y;
	wire			is_val;

	cam_sim my_cam(
		.clk(clk),
		.reset(reset),
		.pclk(pclk),
		.value(value),
		.x(x),
		.y(y),
		.is_val(is_val)
	);

	vga_buf_sim my_vga(
		.pclk(pclk),
		.reset(reset),
		.value(value),
		.x(x),
		.y(y),
		.is_val(is_val)
	);

	// Print statements, etc
	initial begin
		#100
		$display("Yoooooooooo");
	end
endmodule