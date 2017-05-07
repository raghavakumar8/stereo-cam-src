/* Writes incoming pixels to a file, simulating the VGA buffer. */
module vga_buf_sim(
	input				pclk,
	input				reset,

	input		[7:0]	value,
	input		[9:0]	x,
	input		[9:0]	y,
	input				is_val
);

	integer fid, err;

	// Open output file
	initial begin
		fid = $fopen("out.list","w");
		$display("File opened!");
	end

	// Write to file as values are received
	always@ (posedge pclk) begin
		if (is_val) begin

			// Start writing from the beginning
			if (x == 10'b0 && y == 10'b0) begin
				err = $fseek(fid, 0, 0);
				$display("Starting new frame");
			end
			
			$fwrite(fid,"%h\n", value);
			
		end
	end

endmodule