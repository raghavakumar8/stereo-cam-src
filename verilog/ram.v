/* Adapted from Altera's Recommended HDL Coding Styles Example 12-16 */
module dual_clock_ram #(parameter W = 8, parameter SZ = 307200)(
	output	reg	[W-1:0]	q,
	input		[W-1:0]	d,
	input		[$clog2(SZ)-1:0] 	write_address, read_address,
	input 				we, clk1, clk2
);
	reg			[$clog2(SZ)-1:0]	read_address_reg;
	reg			[W-1:0]	mem [SZ-1:0];

	always @ (posedge clk1)
	begin
		if (we)
			mem[write_address] <= d;
 	end

	always @ (posedge clk2) begin
		q <= mem[read_address_reg];
		read_address_reg <= read_address;
	end

endmodule