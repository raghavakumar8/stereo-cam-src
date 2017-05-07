module correlate(
	clk, reset,
	left_bitvec, right_bitvec, bitvec_val,
	input_x, input_y,
	out_x, out_y,
	disparity_val, disparity
);
	// Local parameters
	localparam			disp = 64;		// Number of disparities
	localparam			bv_len = 72;	// Bit vector length
	localparam			F_WIDTH = 320;
	localparam			F_HEIGHT = 240;

	// Inputs and outputs
	input						clk;
	input						reset;

	input		[bv_len-1:0]	left_bitvec;
	input		[bv_len-1:0]	right_bitvec;
	input						bitvec_val;

	input		[9:0]			input_x;
	input		[9:0]			input_y;

	output	reg	[9:0]			out_x;
	output	reg	[9:0]			out_y;

	output	reg					disparity_val;
	output	reg [$clog2(disp)-1:0]	disparity;

	// Registers for the input pixel X and Y coordinates
	reg			[9:0]			input_x_reg;
	reg			[9:0]			input_y_reg;

	// Store the X and Y coordinates of the input pixel so we
	// can calculate the output pixel's X and Y
	always @(posedge clk) begin
		if (bitvec_val) begin
			input_x_reg <= input_x;
			input_y_reg <= input_y;
		end
	end

	// Registers for the bitvec shift buffer
	reg			[bv_len-1:0]	left_buffer[disp-1:0];
	reg			[bv_len-1:0]	right_buffer[disp-1:0];
	reg			[disp-1:0]		buffer_valid;

	// Generate the bitvec shift buffer structure
	// d is the number of disparities
	// [n] represent bitvec for the nth pixel
	// [0] <- [1] <- ... <- [d-1] <- [left or right bitvec]
	genvar i;
	generate
	    for (i = 0; i < disp-1; i = i + 1) begin: SHIFT_BUFFER
	        always @(posedge clk) begin
	    		if (bitvec_val) begin
	            	left_buffer[i] <= left_buffer[i+1];
	            	right_buffer[i] <= right_buffer[i+1];
	            end
	        end
	    end
	endgenerate

	always @(posedge clk) begin
		if (bitvec_val) begin
			left_buffer[disp-1] <= left_bitvec;
			right_buffer[disp-1] <= right_bitvec;
		end

		// We also use a register to keep track of which parts of the buffer
		// contains valid values.
		if (reset) begin
			buffer_valid <= 0;
		end
		else begin
			if (bitvec_val)
				buffer_valid <= (buffer_valid << 1) | 1'b1;
		end
	end

	// Perform the correlation operations when the buffer is filled
	// First perform the XORs and bit sums
	parameter						dval_width = $clog2(bv_len);
	reg			[dval_width-1:0]	disparity_value[disp-1:0];
	reg								xor_sum_valid;
	reg			[9:0]				xor_sum_x;
	reg			[9:0]				xor_sum_y;
	genvar j;
	generate
	    for (j = 0; j < disp; j = j + 1) begin: XOR_AND_ADD
	    	// First XOR the left and right bitvecs
	    	wire 	[bv_len-1:0]	xor_output;
	    	assign xor_output = left_buffer[j] ^ right_buffer[j];

	    	// Then sum up the number of ones in the bitvec
	    	integer i;
	    	reg		[dval_width-1:0]	temp_dval;
			always @(posedge clk) begin
				temp_dval = 0;
				for (i=0; i<bv_len; i=i+1)
					temp_dval = temp_dval + xor_output[i];
				disparity_value[j] <= temp_dval;
			end
	    end
	endgenerate

	// Next find the lowest disparity
	// This is done using a tree based comparison
	// For 64 disparity levels, the tree is 6 levels deep
	// 32 comparisons -> 16 -> 8 -> 4 -> 2 -> 1 comparison
	// Level 1: d/2 comparisons (32)
	reg			[$clog2(disp)-1:0] 	L1_disparity_idx[disp/2-1:0];
	reg			[dval_width-1:0] 	L1_disparity_val[disp/2-1:0];
	reg								L1_disp_valid;
	reg			[9:0]				L1_disp_x;
	reg			[9:0]				L1_disp_y;
	genvar a;
	generate
		for (a = 0; a < disp/2; a = a + 1) begin: COMPARE_LEVEL1
			always @(posedge clk) begin
				if (disparity_value[a*2] < disparity_value[a*2+1]) begin
					L1_disparity_idx[a] <= a*2;
					L1_disparity_val[a] <= disparity_value[a*2];
				end
				else begin
					L1_disparity_idx[a] <= a*2 + 1;
					L1_disparity_val[a] <= disparity_value[a*2+1];
				end
			end
		end
	endgenerate

	// Level 2: d/4 comparisons (16)
	reg			[$clog2(disp)-1:0] 	L2_disparity_idx[disp/4-1:0];
	reg			[dval_width-1:0] 	L2_disparity_val[disp/4-1:0];
	reg								L2_disp_valid;
	reg			[9:0]				L2_disp_x;
	reg			[9:0]				L2_disp_y;
	genvar b;
	generate
		for (b = 0; b < disp/4; b = b + 1) begin: COMPARE_LEVEL2
			always @(posedge clk) begin
				if (L1_disparity_val[b*2] < L1_disparity_val[b*2+1]) begin
					L2_disparity_idx[b] <= L1_disparity_idx[b*2];
					L2_disparity_val[b] <= L1_disparity_val[b*2];
				end
				else begin
					L2_disparity_idx[b] <= L1_disparity_idx[b*2+1];
					L2_disparity_val[b] <= L1_disparity_val[b*2+1];
				end
			end
		end
	endgenerate

	// Level 3: d/8 comparisons (8)
	reg			[$clog2(disp)-1:0] 	L3_disparity_idx[disp/8-1:0];
	reg			[dval_width-1:0] 	L3_disparity_val[disp/8-1:0];
	reg								L3_disp_valid;
	reg			[9:0]				L3_disp_x;
	reg			[9:0]				L3_disp_y;
	genvar c;
	generate
		for (c = 0; c < disp/8; c = c + 1) begin: COMPARE_LEVEL3
			always @(posedge clk) begin
				if (L2_disparity_val[c*2] < L2_disparity_val[c*2+1]) begin
					L3_disparity_idx[c] <= L2_disparity_idx[c*2];
					L3_disparity_val[c] <= L2_disparity_val[c*2];
				end
				else begin
					L3_disparity_idx[c] <= L2_disparity_idx[c*2+1];
					L3_disparity_val[c] <= L2_disparity_val[c*2+1];
				end
			end
		end
	endgenerate

	// Level 4: d/16 comparisons (4)
	reg			[$clog2(disp)-1:0] 	L4_disparity_idx[disp/16-1:0];
	reg			[dval_width-1:0] 	L4_disparity_val[disp/16-1:0];
	reg								L4_disp_valid;
	reg			[9:0]				L4_disp_x;
	reg			[9:0]				L4_disp_y;
	genvar d;
	generate
		for (d = 0; d < disp/16; d = d + 1) begin: COMPARE_LEVEL4
			always @(posedge clk) begin
				if (L3_disparity_val[d*2] < L3_disparity_val[d*2+1]) begin
					L4_disparity_idx[d] <= L3_disparity_idx[d*2];
					L4_disparity_val[d] <= L3_disparity_val[d*2];
				end
				else begin
					L4_disparity_idx[d] <= L3_disparity_idx[d*2+1];
					L4_disparity_val[d] <= L3_disparity_val[d*2+1];
				end
			end
		end
	endgenerate

	// Level 5: d/32 comparisons (2)
	reg			[$clog2(disp)-1:0] 	L5_disparity_idx[disp/32-1:0];
	reg			[dval_width-1:0] 	L5_disparity_val[disp/32-1:0];
	reg								L5_disp_valid;
	reg			[9:0]				L5_disp_x;
	reg			[9:0]				L5_disp_y;
	genvar e;
	generate
		for (e = 0; e < disp/32; e = e + 1) begin: COMPARE_LEVEL5
			always @(posedge clk) begin
				if (L4_disparity_val[e*2] < L4_disparity_val[e*2+1]) begin
					L5_disparity_idx[e] <= L4_disparity_idx[e*2];
					L5_disparity_val[e] <= L4_disparity_val[e*2];
				end
				else begin
					L5_disparity_idx[e] <= L4_disparity_idx[e*2+1];
					L5_disparity_val[e] <= L4_disparity_val[e*2+1];
				end
			end
		end
	endgenerate

	// Level 6: d/64 comparison (1)
	// This is the last comparison so we output to the disparity
	always @(posedge clk) begin
		if (L5_disparity_val[0] < L5_disparity_val[1]) begin
			disparity <= L5_disparity_idx[0];
		end
		else begin
			disparity <= L5_disparity_idx[1];
		end
	end

	// We also propogate the valid bit through the pipeline to indicate
	// whether the outputs of each stage is valid. This will propagate
	// to the disparity output valid bit which is used to indicate whether
	// the output disparity value is valid or not. 
	always @(posedge clk) begin
		if (reset) begin
			xor_sum_valid <= 0;
			L1_disp_valid <= 0;
			L2_disp_valid <= 0;
			L3_disp_valid <= 0;
			L4_disp_valid <= 0;
			L5_disp_valid <= 0;
			disparity_val <= 0;
		end
		else begin
			// The output of the first stage (xor and sum) is valid if all of 
			// the inputs, which are the shift buffers, are valid.
			xor_sum_valid <= &buffer_valid;
			L1_disp_valid <= xor_sum_valid;
			L2_disp_valid <= L1_disp_valid;
			L3_disp_valid <= L2_disp_valid;
			L4_disp_valid <= L3_disp_valid;
			L5_disp_valid <= L4_disp_valid;
			disparity_val <= L5_disp_valid;
		end
	end

	// Also propagate the output X and Y values, similar to the val bit
	always @(posedge clk) begin
		if (reset) begin
			xor_sum_x <= 0;
			xor_sum_y <= 0;
			L1_disp_x <= 0;
			L1_disp_y <= 0;
			L2_disp_x <= 0;
			L2_disp_y <= 0;
			L3_disp_x <= 0;
			L3_disp_y <= 0;
			L4_disp_x <= 0;
			L4_disp_y <= 0;
			L5_disp_x <= 0;
			L5_disp_y <= 0;
			out_x <= 0;
			out_y <= 0;
		end
		else begin
			// Here, we compute the output X and Y values
			// For X, we need to check whether we have wrapped around to a new row (in_x < disp - 1)
			// If so, then we are still outputting on the previous row
			xor_sum_x <= input_x_reg < (disp - 1) ? 
				F_WIDTH - (disp - (input_x_reg + 1)) : input_x_reg - (disp - 1);
			// Similarly for Y, we do the same wrap around check
			// Additionally, we also check if we have wrapped around to a new frame (in_y == 0)
			// If so, then we are still outputting on the previous frame
			xor_sum_y <= input_x_reg < (disp - 1) ? 
				(input_y_reg == 0 ? F_HEIGHT - 1 : input_y_reg - 1) : input_y_reg;
			L1_disp_x <= xor_sum_x;
			L1_disp_y <= xor_sum_y;
			L2_disp_x <= L1_disp_x;
			L2_disp_y <= L1_disp_y;
			L3_disp_x <= L2_disp_x;
			L3_disp_y <= L2_disp_y;
			L4_disp_x <= L3_disp_x;
			L4_disp_y <= L3_disp_y;
			L5_disp_x <= L4_disp_x;
			L5_disp_y <= L4_disp_y;
			out_x <= L5_disp_x;
			out_y <= L5_disp_y;
		end
	end

endmodule