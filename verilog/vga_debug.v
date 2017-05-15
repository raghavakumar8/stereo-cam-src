module vga_stereo_debug #(parameter ROW_SZ = 320, parameter COL_SZ = 240)(
	input				clk,
	input				reset,
	input		[9:0]	in_x,
	input		[9:0]	in_y,
	input		[7:0]	in_val,
	input				in_is_val,

	// Interface for the VGA contrller
	input				vga_clk,
	input		[9:0]	pixel_x,
	input		[9:0]	pixel_y,
	output		[7:0]	pixel_val
);

	wire		[7:0]	wr_val;
	wire		[18:0]	wr_addr;
	wire 		[18:0]	rd_addr;

	assign wr_addr = in_y*ROW_SZ + in_x;
	assign rd_addr = pixel_y*640 + pixel_x;

	dual_clock_ram_640_480 frame_buf(
		.q(pixel_val),
		.d(in_val),
		.write_address(wr_addr),
		.read_address(rd_addr),
		.we(in_is_val),
		.clk1(clk),
		.clk2(vga_clk)
	);

endmodule

/* Adapted from Altera's Recommended HDL Coding Styles Example 12-16 */
module dual_clock_ram_640_480(
	output	reg	[7:0]	q,
	input		[7:0]	d,
	input		[18:0] 	write_address, read_address,
	input 				we, clk1, clk2
);
	reg			[18:0]	read_address_reg;
	reg			[7:0]	mem [307199:0];  // 640*480

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