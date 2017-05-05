/* Parametrized streaming convolution kernel. */
module convolve(
	input		clk,
	input		reset,

	input		[7:0]	in_val,
	input		[9:0]	in_x,
	input		[9:0]	in_y,
	input				is_in_val,

	output		[7:0]	out_val,
	output		[9:0]	out_x,
	output		[9:0]	out_y,
	output				is_out_val,

	// Convolution kernel represented as a single bit vector.
	// Representation example: {8'dA, 8'dB, .. 8'dH, 8'dI} => 
	//      [A B C]
	//      [D E F]
	//      [G H I]
	input [KRNL_SZ*KRNL_SZ*8-1 : 0] kernel
);
	parameter KRNL_SZ = 5;

	// Wires that loop from the leftmost reg of one row to
	// the rightmost reg of the row above it.
	wire	[7:0] carry_over_wires [KRNL_SZ-2 : 0];

	// Convolution registers represented as a 1D array.
	// register @ (i,j) is conv_r[KRNL_SZ*i + j]
	reg		[7:0] conv_r [KRNL_SZ*KRNL_SZ-1 : 0];

	// Generate and hook up shift registers
	genvar i, j;
	generate
	    for (i = 0; i < KRNL_SZ; i = i + 1) begin: SHIFT_REGS
	    	wire [7:0] row_reg_sr_out;

	        if (i == 0) begin

	        	shift_reg #(8, 320-KRNL_SZ) row_reg(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(in_val),
					.sr_out(row_reg_sr_out)
				);
				
	        end
	        else begin
	        	
	        	shift_reg #(8, 320-KRNL_SZ) row_reg(
					.clk(clk), 
					.shift(is_in_val),
					.sr_in(carry_over_wires[i-1]),
					.sr_out(row_reg_sr_out)
				);

	        end

	        for (j = 0; j < KRNL_SZ; j = j + 1) begin: CONV_REGS
				if (j == 0) begin
					
				end
			end
	        
	    end
	endgenerate


endmodule