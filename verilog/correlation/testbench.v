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

	// Generate a bitvec that goes from all bits are different to all bits are same
	reg	signed	[71:0]	right_bitvec;
	reg	signed	[71:0]	left_bitvec;
	reg					bitvec_val;
	reg					clk_div;
	reg					test_finished;
	always @(posedge clk) begin
		if (reset) begin
			//right_bitvec <= 72'hFF_FFFF_FFFF_FFFF_FFFF;
			right_bitvec <= 72'h00_0000_0000_0000_0000;
			left_bitvec <= 72'd0;
			bitvec_val <= 0;
			clk_div <= 0;
			test_finished <= 0;
		end
		else begin
			if (right_bitvec == 72'hFF_FFFF_FFFF_FFFF_FFFF || test_finished) begin
				bitvec_val <= 0;
				test_finished <= 1;
			end
			else begin
				if (clk_div) begin
					right_bitvec <= (right_bitvec >>> 1) | 72'h80_0000_0000_0000_0000;
					left_bitvec <= 72'd0;
					bitvec_val <= 1;
					clk_div <= 0;
				end
				else begin
					right_bitvec <= right_bitvec;
					left_bitvec <= 72'd0;
					bitvec_val <= 0;
					clk_div <= 1;
				end
				test_finished <= 0;
			end
		end
	end

	wire		[5:0]	disparity;
	wire				disparity_valid;
	correlate my_corr(
		.clk(clk),
		.reset(reset),
		.left_bitvec(left_bitvec),
		.right_bitvec(right_bitvec),
		.bitvec_val(bitvec_val),
		.pixel_x(),
		.pixel_y(),
		.disparity_val(disparity_valid),
		.disparity(disparity)
	);

	// Print statements, etc
	initial begin
		#100
		$display("Yoooooooooo");
	end
endmodule