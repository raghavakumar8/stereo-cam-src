/* Reads image from file, emulating a camera. */
module cam_sim #(parameter LR = 0, parameter ROW_SZ = 320, parameter COL_SZ = 240)(
	input				clk,
	input				reset,

	output				pclk,
	output	reg	[7:0]	value,
	output		[9:0]	x,
	output		[9:0]	y,
	output	reg			is_val
);
	
	reg [7:0] img [0:(ROW_SZ)*(COL_SZ)-1];

 	initial begin
 		if (LR == 0) begin
 			$readmemh("cones_l.list", img); // Replace filename to load different images
 		end
 		else begin
 			$readmemh("cones_r.list", img); // Replace filename to load different images
 		end
 	end

	assign pclk = clk;

	reg	[19:0]	mem_addr;
	reg			this_time;

	// Output x, y
	assign x = (mem_addr == 20'b0) ? ROW_SZ-1 : (mem_addr-1) % ROW_SZ;
	assign y = (mem_addr == 20'b0) ? COL_SZ-1 : (mem_addr-1) / ROW_SZ;

	// Output pixels on alternate clock cycles
	always@ (posedge clk) begin
		if (reset == 1'b1) begin
			this_time <= 1'b0;

			value <= 8'b0;
			mem_addr <= 20'd0;
			is_val <= 1'b0;
		end
		else begin
			if (this_time == 1'b1) begin
				value <= img[mem_addr];
				is_val <= 1'b1;

				if (mem_addr < (ROW_SZ)*(COL_SZ)-1) begin
					mem_addr <= mem_addr + 20'd1;
				end
				else begin
					mem_addr <= 20'd0;
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