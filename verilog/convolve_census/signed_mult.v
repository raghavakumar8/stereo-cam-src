/* Multiplier taken from Bruce's code */
module signed_mult (out, a, b);
	output	signed	[8:0]	out;
	input 	signed	[8:0] 	a;
	input 	signed	[8:0] 	b;
	
	wire	signed	[8:0]	out;
	wire 	signed	[17:0]	mult_out;

	assign mult_out = a * b;
	assign out = {mult_out[17], mult_out[15:8]};
endmodule