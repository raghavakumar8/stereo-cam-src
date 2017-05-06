/* Reads image from file, emulating a camera. */
module cam_sim(
	input				clk,
	input				reset,

	output				pclk,
	output	reg	[7:0]	value,
	output		[9:0]	x,
	output		[9:0]	y,
	output	reg			is_val
);

	reg [7:0] img [0:76799]; //320* 240 memory block

 	initial begin
 		$readmemh("b.list", img); // Replace filename to load different images
 	end

	assign pclk = clk;

	reg	[16:0]	mem_addr;
	reg			this_time;

	// Output x, y
	assign x = (mem_addr == 17'b0) ? 319 : (mem_addr-1) % 320;
	assign y = (mem_addr == 17'b0) ? 239 : (mem_addr-1) / 320;

	// Output pixels on alternate clock cycles
	always@ (posedge clk) begin
		if (reset == 1'b1) begin
			this_time <= 1'b0;

			value <= 8'b0;
			mem_addr <= 17'd0;
			is_val <= 1'b0;
		end
		else begin
			if (this_time == 1'b1) begin
				value <= img[mem_addr];
				is_val <= 1'b1;

				if (mem_addr < 17'd76799) begin
					mem_addr <= mem_addr + 17'd1;
				end
				else begin
					mem_addr <= 17'd0;
				end
			end
			else begin
				value <= value;
				mem_addr <= mem_addr;
				is_val <= 1'b0;
			end

			this_time <= ~this_time;
		end
	end

endmodule