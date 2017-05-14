/* Streaming census transform. */
module sp_census #(parameter ROW_SZ = 320, parameter COL_SZ = 240)(
	input		clk,
	input		reset,
	input		[7:0]	thresh,

	input		[7:0]	in_val,
	input		[9:0]	in_x,
	input		[9:0]	in_y,
	input				is_in_val,

	output		[7:0]	out_val,
	output		[9:0]	out_x,
	output		[9:0]	out_y,
	output				is_out_val
);
	// Don't change this.
	localparam CEN_SZ = 5;

	// Census registers represented as a 1D array.
	// register @ (i,j) is conv_r[CEN_SZ*i + j]
	reg		[7:0] conv_r [(CEN_SZ*CEN_SZ)-1 : 0];

	// Wires that loop from the leftmost reg of one row to
	// the rightmost reg of the row above it.
	wire	[7:0] carry_over_wires [CEN_SZ-2 : 0];

	// Single bit vector representing whether elements in
	// the shift registers are valid or not.
	reg		[(ROW_SZ*CEN_SZ)-1 : 0] is_buf_val;

	// Registers to maintain address at the input of the buffer
	// (These are used to calculate out_x and out_y)
	reg		[9:0] in_x_reg;
	reg		[9:0] in_y_reg;

	always@ (posedge clk) begin
		if (is_in_val) begin
			in_x_reg <= in_x;
			in_y_reg <= in_y;
		end
	end

	// Threshold for improve performance with camera noise
	reg		[7:0] threshold;
	always @(posedge clk) begin
		threshold <= thresh;
	end

	// Determine X,Y position of the output pixel based on the X,Y position of the pixel at the input of the buffer
	assign out_x = in_x_reg < (ROW_SZ-(CEN_SZ/2)-1) ? (in_x_reg + ROW_SZ) - (ROW_SZ-(CEN_SZ/2)-1) : in_x_reg - (ROW_SZ-(CEN_SZ/2)-1);
	assign out_y = out_x <= (CEN_SZ/2) ? (in_y_reg < 1 ? COL_SZ-1 : in_y_reg-1) : (in_y_reg < 2 ? COL_SZ-2+in_y_reg : in_y_reg-2);

	// Shift validity to the left as bits stream in
	always@ (posedge clk) begin
		if (reset) begin
			is_buf_val <= 0;
		end
		else begin
			if (is_in_val) begin
				is_buf_val <= (is_buf_val << 1) |  1'b1;
			end
		end
	end

	// Output is valid for a single cycle if the center of the census region is valid.
	assign is_out_val = is_in_val & is_buf_val[ROW_SZ*(CEN_SZ/2) + (ROW_SZ-CEN_SZ) + (CEN_SZ/2)];

	// Generate and hook up shift registers
	genvar i, j;
	generate
	    for (i = 0; i < CEN_SZ; i = i + 1) begin: SHIFT_BUF
	    	wire [7:0] row_buf_sr_out;

	        // Instantiate M10K shift registers for most of the row
	        if (i == CEN_SZ-1) begin

	        	shift_reg #(8, ROW_SZ-CEN_SZ) row_shift_buf(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(in_val),
					.sr_out(row_buf_sr_out)
				);
				
	        end
	        else begin
	        	
	        	shift_reg #(8, ROW_SZ-CEN_SZ) row_shift_buf(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(carry_over_wires[i]),
					.sr_out(row_buf_sr_out)
				);

	        end

	        // Connect individual registers for the first CEN_SZ elements
	        for (j = 0; j < CEN_SZ; j = j + 1) begin: CONV_REGS
	        	// Leftmost registers map to carry over wires
				if (j == 0) begin
					if(i != 0) begin
						assign carry_over_wires[i-1] = conv_r[CEN_SZ*i + j];
					end

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[CEN_SZ*i + j] <= conv_r[CEN_SZ*i + (j+1)];
						end
					end

				end
				// Rightmost registers take input from the row shift buffer
				else if (j == CEN_SZ-1) begin

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[CEN_SZ*i + j] <= row_buf_sr_out;
						end
					end

				end
				else begin

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[CEN_SZ*i + j] <= conv_r[CEN_SZ*i + (j+1)];
						end
					end

				end
			end
	        
	    end
	endgenerate

	// Determine output by calculating a 8-point sparse census in the census region.
	assign out_val[0] = (conv_r[CEN_SZ*0 + 0] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[1] = (conv_r[CEN_SZ*0 + 2] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[2] = (conv_r[CEN_SZ*0 + 4] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[3] = (conv_r[CEN_SZ*2 + 0] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[4] = (conv_r[CEN_SZ*2 + 4] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[5] = (conv_r[CEN_SZ*4 + 0] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[6] = (conv_r[CEN_SZ*4 + 2] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;
	assign out_val[7] = (conv_r[CEN_SZ*4 + 4] < conv_r[CEN_SZ*2 + 2] - threshold) ? 1'b1 : 1'b0;

endmodule