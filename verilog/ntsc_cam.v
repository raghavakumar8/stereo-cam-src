module 	NTSC_Cam(
	// NTSC Inputs and outputs
	input				ntsc_clk,
	input				reset,

	input		[7:0]	Y,
	input		[7:0]	Cb, // Don't really need Cb and Cr because
	input		[7:0]	Cr, // we only do grayscale

	output	reg			request,
	output	reg [10:0]	req_x,
	output	reg [10:0]	req_y,

	// Simulated dual cam outputs
	output				cam_clk,
	output	reg [9:0]	out_x,
	output	reg [9:0]	out_y,
	output	reg [7:0]	out_left,
	output	reg [7:0]	out_right,
	output	reg			out_is_val
);
	localparam XSTART	= 0;
	localparam XSEP		= 320; // Where the right image starts
	localparam XEND		= 639; 
	localparam HBLANK	= 160;
	localparam YSTART	= 0;
	localparam YEND		= 479; 
	localparam VBLANK	= 44; 

	localparam TOPBORD	= 0;  // Location of top border
	localparam BOTBORD	= 0;  // Location of bottom border
	localparam LEFBORD	= 57; // Location of left border
	localparam RIGBORD	= 591;// Location of right border

	assign cam_clk = ntsc_clk;

	wire		[7:0]	Y_bord; // Y with border
	assign Y_bord = Y; // No border implemented

	// Shift register for buffering the row from the right "cam"
	wire		[7:0]	right_buf_out;
	shift_reg #(8, XSEP - XSTART - LEFBORD) row_shift_buf(
		.clk(ntsc_clk), 
		.shift(1'b1),
		.sr_in(Y_bord),
		.sr_out(right_buf_out)
	);

	reg			[9:0]	hb_count;
	reg			[7:0]	vb_count;

	always @(posedge ntsc_clk) begin
		if (reset) begin
			request <= 0;
			req_x <= 0;
			req_y <= 0;
			out_x <= 0;
			out_y <= 0;
			out_is_val <= 0;

			hb_count <= 0;
			vb_count <= 0;
		end
		else begin
			if (request) begin
				// Request all pixels from the NTSC frame buffer
				if (req_x < XEND) begin
					req_x <= req_x + 1;
				end
				else begin
					request <= 0;
					req_x <= XSTART;
					if (req_y < YEND) begin
						req_y <= req_y + 1;
					end
					else begin
						req_y <= YSTART;
					end
				end

				// Generate the camera outputs
				// Buffer the left half of the row
				if (req_x < XSEP) begin
					// Buffer the left "cam" section
					out_is_val <= 0;
				end
				else begin
					out_x <= req_x - XSEP;
					out_y <= req_y;
					out_left <= Y_bord;
					if (out_x < XSEP - LEFBORD) begin
						out_right <= right_buf_out;
					end
					else begin
						out_right <= 8'h00;
					end
					out_is_val <= 1;
				end
			end
			else begin
				// Perform some simulated blanking
				if (req_y == 0) begin 
					// Perform VBlanking by skipping VBLANK number of rows
					if (hb_count < XEND + HBLANK) begin
						hb_count <= hb_count + 1;
						request <= 0;
					end
					else begin
						hb_count <= 0;
						if (vb_count < VBLANK) begin
							vb_count <= vb_count + 1;
							request <= 0;
						end
						else begin
							vb_count <= 0;
							request <= 1;
						end
					end
				end
				else begin
					// Perform only HBlanking
					if (hb_count < HBLANK - 1) begin
						hb_count <= hb_count + 1;
						request <= 0;
					end
					else begin
						hb_count <= 0;
						request <= 1;
					end
				end
				out_is_val <= 0;
			end
		end
	end
endmodule