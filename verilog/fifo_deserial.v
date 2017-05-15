module fifo_deserial(
	input				clk,
	input				reset,
	input		[31:0]	data_in,
	input				fifo_empty,
	input				outfifo_full,
	output				fifo_rdreq,

	output	reg	[9:0]	img_in_x,
	output	reg	[9:0]	img_in_y,
	output	reg	[7:0]	img_in_left,	
	output	reg	[7:0]	img_in_right,
	output				img_is_val,

	input		[9:0]	debug_in,
	output		[5:0]	debug_out
);

	// Read from the FIFO when the FIFO is not empty
	assign fifo_rdreq = ~fifo_empty & ~outfifo_full;
	// The data becomes valid on the cycle after rdreq is asserted
	reg					in_is_val;
	always @(posedge clk) begin
		if (fifo_rdreq) begin
			in_is_val <= 1;
		end
		else begin
			in_is_val <= 0;
		end
	end


	reg					coord_is_val;
	reg					pix_is_val;
	reg					read_next_packet;
	always @(posedge clk) begin
		if (reset) begin
			coord_is_val <= 0;
			pix_is_val <= 0;
			read_next_packet <= 1;
		end
		else begin
			if (read_next_packet) begin
				// We don't have valid coord yet, so wait to receive
				// the coordinates
				// Now that we have sent a full valid coordinate and
				// pixel values, deassert the valid signals so that
				// we can receive the next values
				pix_is_val <= 0;
				if (!data_in[31] && in_is_val) begin
					// MSB is 0, so we are receiving coord
					img_in_x <= data_in[9:0];
					img_in_y <= data_in[25:16];
					coord_is_val <= 1;

					// We are now reading the current packet
					// Need to now read the pixel values
					read_next_packet <= 0;
				end
				else begin
					coord_is_val <= 0;
					read_next_packet <= 1;
				end
			end
			else begin
				// We now have valid coord, so wait for pix values
				if (data_in[31] && in_is_val) begin
					// MSB is 1, so we are receiving pix values
					img_in_left <= data_in[15:8];
					img_in_right <= data_in[7:0];
					pix_is_val <= 1;

					// We have received a full packet
					// Now read the next packet
					read_next_packet <= 1;
				end
				else begin
					pix_is_val <= 0;
					read_next_packet <= 0;
				end
			end
		end
	end

	// The output is valid only if we have stored valid
	// coordinates and image pixel values
	assign img_is_val = coord_is_val & pix_is_val;

	assign debug_out[0] = pix_is_val;
	assign debug_out[1] = coord_is_val;
	assign debug_out[2] = fifo_rdreq;
	assign debug_out[3] = in_is_val;
	assign debug_out[4] = read_next_packet;
	assign debug_out[5] = data_in[31];
endmodule