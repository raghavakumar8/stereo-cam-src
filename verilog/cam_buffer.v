/* Interfaces with the OV7670 camera module and writes to a local
 * frame buffer that can be indexed into and read (to display on 
 * VGA or process further). */
module cam_buffer(
	input				clk_50,
	input				reset,

	// Camera Interface
	output				xclk,
	input 				pclk,

	input				vsync,
	input				href,

	input		[7:0]	data,

	output				cam_rst,
	output				cam_pwdn,

	// External Interface
	input				rd_clk,
	input		[9:0]	x_addr,
	input		[9:0]	y_addr,

	output		[7:0]	value
);

	// Define local wires
	wire		[7:0]	mem_val;
	wire		[7:0]	wr_val;
	wire				is_wr_val;
	wire		[18:0]	wr_addr;
	wire 		[18:0]	rd_addr;

	wire 		[9:0]	x_addr_corr;
	wire 		[9:0]	y_addr_corr;

	// Correct x and y addresses to account for memory delay
	assign x_addr_corr = x_addr;//(x_addr >= 638)? x_addr - 638 : x_addr + 2;
	assign y_addr_corr = y_addr;//(x_addr >= 638)? y_addr + 1 : y_addr;

	// Instantiate camera
/*	ov7670_no_avg cam(
		.clk_50(clk_50),
		.reset(reset),
		.xclk(xclk),
		.pclk(pclk),
		.vsync(vsync),
		.href(href),
		.data(data),
		.cam_rst(cam_rst),
		.cam_pwdn(cam_pwdn),
		.value(wr_val),
		.x_addr(),
		.y_addr(),
		.mem_addr(wr_addr),
		.is_val(is_wr_val)
	);*/
		// Instantiate camera
	mt9d111 cam(
		.clk_50(clk_50),
		.reset(reset),
		.xclk(xclk),
		.pclk(pclk),
		.vsync(vsync),
		.href(href),
		.data(data),
		.cam_rst(cam_rst),
		.cam_pwdn(cam_pwdn),
		.value(wr_val),
		.x_addr(),
		.y_addr(),
		.mem_addr(wr_addr),
		.is_val(is_wr_val)
	);


	// Determine rd_addr using x_addr and y_addr
	assign rd_addr = x_addr_corr + y_addr_corr*800;
	
	// Only output memory value if x_addr < 315
	assign value = (x_addr_corr < 800) ? mem_val : 8'b0;

	dual_clock_ram_800_600 frame_buf(
		.q(mem_val),
		.d(wr_val),
		.write_address(wr_addr[18:0]),
		.read_address(rd_addr[18:0]),
		.we(is_wr_val),
		.clk1(pclk),
		.clk2(rd_clk)
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

/* Adapted from Altera's Recommended HDL Coding Styles Example 12-16 */
module dual_clock_ram_315_240(
	output	reg	[7:0]	q,
	input		[7:0]	d,
	input		[16:0] 	write_address, read_address,
	input 				we, clk1, clk2
);
	reg			[16:0]	read_address_reg;
	reg			[7:0]	mem [75599:0];  // 315*240

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
/* Adapted from Altera's Recommended HDL Coding Styles Example 12-16 */
module dual_clock_ram_800_600(
	output	reg	[7:0]	q,
	input		[7:0]	d,
	input		[18:0] 	write_address, read_address,
	input 				we, clk1, clk2
);
	reg			[18:0]	read_address_reg;
	reg			[7:0]	mem [479999:0];  // 800*600

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