/* Multiplier taken from Bruce's code */
// out: 12.4 signed number representing the multiplication output
// a: unsigned 8 bit number representing the pixel intensity
// b: 4.4 signed number representing the kernel values
module convolve_mult (out, a, b);
	output	signed	[15:0]	out;
	input 			[7:0] 	a;
	input 	signed	[7:0] 	b;
	
	wire	signed	[15:0]	out;
	wire 	signed	[17:0]	mult_out;
	wire	signed	[8:0]	a_se;
	wire	signed	[8:0]	b_se;

	// Sign extend the inputs to 9 bit signed numbers
	assign a_se = {1'b0, a};
	assign b_se = {b[7], b};

	assign mult_out = a_se * b_se;
	assign out = {mult_out[17], mult_out[14:0]};
endmodule