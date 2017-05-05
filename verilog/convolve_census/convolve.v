/* Parametrized streaming convolution kernel. */
module convolve(
	input		clk,
	input		reset,

	input		[7:0]	in_val,
	input		[9:0]	in_x,
	input		[9:0]	in_y,
	input				is_in_val,

	output	reg	[7:0]	out_val,
	output		[9:0]	out_x,
	output		[9:0]	out_y,
	output				is_out_val,

	// Convolution kernel represented as a single bit vector.
	// kernel value @ (i,j) is kernel[(N*8)+7 : N*8] where N = KRNL_SZ*i + j
	input [(KRNL_SZ*KRNL_SZ*8)-1 : 0] kernel
);
	parameter KRNL_SZ = 5;
	parameter ROW_SZ = 320; // # of elements in a row
	parameter COL_SZ = 240; // # of elements in a column

	// Convolution registers represented as a 1D array.
	// register @ (i,j) is conv_r[KRNL_SZ*i + j]
	reg		[7:0] conv_r [(KRNL_SZ*KRNL_SZ)-1 : 0];

	// Wires that loop from the leftmost reg of one row to
	// the rightmost reg of the row above it.
	wire	[7:0] carry_over_wires [KRNL_SZ-2 : 0];

	// Single bit vector representing whether elements in
	// the shift registers are valid or not.
	reg		[(ROW_SZ*KRNL_SZ)-1 : 0] is_buf_val;

	// Registers to maintain address at the input of the buffer
	// (These are used to calculate out_x and out_y)
	reg		[7:0] in_x_reg;
	reg		[7:0] in_y_reg;

	always@ (posedge clk) begin
		if (is_in_val) begin
			in_x_reg <= in_x;
			in_y_reg <= in_y;
		end
	end

	// Determine X,Y position of the output pixel based on the X,Y position of the pixel at the input of the buffer
	assign out_x = in_x_reg < (ROW_SZ-(KRNL_SZ/2)-1) ? (in_x_reg + ROW_SZ) - (ROW_SZ-(KRNL_SZ/2)-1) : in_x_reg - (ROW_SZ-(KRNL_SZ/2)-1);
	assign out_y = out_x <= (KRNL_SZ/2) ? (in_y_reg < 1 ? COL_SZ-1 : in_y_reg-1) : (in_y_reg < 2 ? COL_SZ-2+in_y_reg : in_y_reg-2);

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

	// Output is valid if the center of the convolution kernel is valid.
	assign out_val = is_buf_val[ROW_SZ*(KRNL_SZ/2) + (ROW_SZ-KRNL_SZ) + (KRNL_SZ/2) + 1];

	// Generate and hook up shift registers
	genvar i, j;
	generate
	    for (i = 0; i < KRNL_SZ; i = i + 1) begin: SHIFT_BUF
	    	wire [7:0] row_buf_sr_out;

	        // Instantiate M10K shift registers for most of the row
	        if (i == KRNL_SZ-1) begin

	        	shift_reg #(8, ROW_SZ-KRNL_SZ) row_shift_buf(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(in_val),
					.sr_out(row_buf_sr_out)
				);
				
	        end
	        else begin
	        	
	        	shift_reg #(8, ROW_SZ-KRNL_SZ) row_shift_buf(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(carry_over_wires[i]),
					.sr_out(row_buf_sr_out)
				);

	        end

	        // Connect individual registers for the first KRNL_SZ elements
	        for (j = 0; j < KRNL_SZ; j = j + 1) begin: CONV_REGS
	        	// Leftmost registers map to carry over wires
				if (j == 0) begin
					if(i != 0) begin
						assign carry_over_wires[i-1] = conv_r[KRNL_SZ*i + j];
					end

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[KRNL_SZ*i + j] <= conv_r[KRNL_SZ*i + (j+1)];
						end
					end

				end
				// Rightmost registers take input from the row shift buffer
				else if (j == KRNL_SZ-1) begin

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[KRNL_SZ*i + j] <= row_buf_sr_out;
						end
					end

				end
				else begin

					always@ (posedge clk) begin
						if (is_in_val) begin
							conv_r[KRNL_SZ*i + j] <= conv_r[KRNL_SZ*i + (j+1)];
						end
					end

				end
			end
	        
	    end
	endgenerate

	// Determine output by multiplying conv_r with kernel and summing things up
	// multiply result @ (i,j) is conv_r[KRNL_SZ*i + j]
	wire	[7:0] mult [(KRNL_SZ*KRNL_SZ)-1 : 0];
	genvar k, l;
	generate

		for (k = 0; k < KRNL_SZ; k = k + 1) begin: MULT_OUTER
			for (l = 0; l < KRNL_SZ; l = l + 1) begin: MULT_INNER
				mult[KRNL_SZ*i + j] = conv_r[KRNL_SZ*i + j]; // TODO: Change this to a multiply
			end
		end

	endgenerate

	integer sum_i;

	always@ (*) begin
	 	out_val = 8'b0;
		for(sum_i = 0; sum_i < (KRNL_SZ*KRNL_SZ); sum_i = sum_i + 1) begin
			out_val = out_val + (mult[sum_i] >> 3);
		end
	end


endmodule