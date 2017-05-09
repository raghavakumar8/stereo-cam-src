/* Parametrized streaming census windower. Aggregates census bit vectors into a longer vector. */
module census_window #(parameter WNDW_SZ = 3, parameter ROW_SZ = 320, parameter COL_SZ = 240)(
	input		clk,
	input		reset,

	input		[7:0]	in_val,
	input		[9:0]	in_x,
	input		[9:0]	in_y,
	input				is_in_val,

	// Concatenated census vector
	// conv_r @ (i,j) gets placed in out_val[(N*8)+7 : N*8] where N = WNDW_SZ*i + j 
	output		[(WNDW_SZ*WNDW_SZ*8)-1 : 0]	out_val,
	output		[9:0]	out_x,
	output		[9:0]	out_y,
	output				is_out_val
);

	// Census registers represented as a 1D array.
	// register @ (i,j) is conv_r[WNDW_SZ*i + j]
	reg		[7:0] conv_r [(WNDW_SZ*WNDW_SZ)-1 : 0];

	// Wires that loop from the leftmost reg of one row to
	// the rightmost reg of the row above it.
	wire	[7:0] carry_over_wires [WNDW_SZ-2 : 0];

	// Single bit vector representing whether elements in
	// the shift registers are valid or not.
	reg		[(ROW_SZ*WNDW_SZ)-1 : 0] is_buf_val;

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

	// Determine X,Y position of the output pixel based on the X,Y position of the pixel at the input of the buffer
	assign out_x = in_x_reg < (ROW_SZ-(WNDW_SZ/2)-1) ? (in_x_reg + ROW_SZ) - (ROW_SZ-(WNDW_SZ/2)-1) : in_x_reg - (ROW_SZ-(WNDW_SZ/2)-1);
	assign out_y = out_x <= (WNDW_SZ/2) ? (in_y_reg < 1 ? COL_SZ-1 : in_y_reg-1) : (in_y_reg < 2 ? COL_SZ-2+in_y_reg : in_y_reg-2);

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
	assign is_out_val = is_in_val & is_buf_val[ROW_SZ*(WNDW_SZ/2) + (ROW_SZ-WNDW_SZ) + (WNDW_SZ/2)];

	// Generate and hook up shift registers
	genvar i, j;
	generate
	    for (i = 0; i < WNDW_SZ; i = i + 1) begin: SHIFT_BUF
	    	wire [7:0] row_buf_sr_out;

	        // Instantiate M10K shift registers for most of the row
	        if (i == WNDW_SZ-1) begin

	        	shift_reg #(8, ROW_SZ-WNDW_SZ) row_shift_buf(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(in_val),
					.sr_out(row_buf_sr_out)
				);
				
	        end
	        else begin
	        	
	        	shift_reg #(8, ROW_SZ-WNDW_SZ) row_shift_buf(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(carry_over_wires[i]),
					.sr_out(row_buf_sr_out)
				);

	        end

	        // Connect individual registers for the first WNDW_SZ elements
	        for (j = 0; j < WNDW_SZ; j = j + 1) begin: CONV_REGS
	        	// Leftmost registers map to carry over wires
				if (j == 0) begin
					if(i != 0) begin
						assign carry_over_wires[i-1] = conv_r[WNDW_SZ*i + j];
					end

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[WNDW_SZ*i + j] <= conv_r[WNDW_SZ*i + (j+1)];
						end
					end

				end
				// Rightmost registers take input from the row shift buffer
				else if (j == WNDW_SZ-1) begin

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[WNDW_SZ*i + j] <= row_buf_sr_out;
						end
					end

				end
				else begin

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[WNDW_SZ*i + j] <= conv_r[WNDW_SZ*i + (j+1)];
						end
					end

				end
			end
	        
	    end
	endgenerate

	// Determine output by concatenating individual census vectors.
	genvar k, l;
	generate

		for (k = 0; k < WNDW_SZ; k = k + 1) begin: CONCAT_OUTER
			for (l = 0; l < WNDW_SZ; l = l + 1) begin: CONCAT_INNER
				
				assign out_val[((WNDW_SZ*k + l)*8 + 7) : (WNDW_SZ*k + l)*8] = conv_r[WNDW_SZ*k + l];

			end
		end

	endgenerate

endmodule