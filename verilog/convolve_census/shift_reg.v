/* Shift register for streaming pixel-processing.
   Based on Altera's Recommended HDL Coding Styles, Example 12-37 */
module shift_reg(
	input			clk, 
	input			shift,

	// I/O
	input	[NUM_BITS-1:0]	sr_in,
	output	[NUM_BITS-1:0]	sr_out
);
	parameter NUM_BITS = 8;
	parameter NUM_REGS = 320;

	reg [NUM_BITS-1:0] sr [NUM_REGS-1:0];

	integer n;

	always @ (posedge clk) begin
		// Shift!
		if (shift == 1'b1)	begin
			for (n = NUM_REGS-1; n > 0; n = n-1) begin
				sr[n] <= sr[n-1];
			end

			sr[0] <= sr_in;
		end
	end

	// Shift out value
	assign sr_out = sr[NUM_REGS-1];
	
endmodule