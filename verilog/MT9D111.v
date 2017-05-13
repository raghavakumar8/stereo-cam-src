/* Interfaces with the OV7670 camera module.
 * Assumes the camera is configured for 320*240 output.
 *
 * Notes:
 *  - Drives xclk @25MHz
 *  - Assumes YCbCr 4:2:2 data format
 *  - Output ignores Cb/Cr components,
      resulting in a monochrome image. */
module 	mt9d111(
	input				clk_50,
	input				reset,

	// Camera Interface
	output	wire			xclk,
	input 				pclk,

	input				vsync,
	input				href,

	input		[7:0]	data,

	output	reg			cam_rst,
	output	reg			cam_pwdn,

	// Memory Interface
	output	reg	[7:0]	value,
	output	reg	[10:0]	x_addr,
	output	reg	[10:0]	y_addr,

	output	reg	[18:0]	mem_addr,
	output	reg			is_val
);
	reg 		[7:0]	val_temp;
	reg			[7:0]	val_msb;

	// Draw a white border around the image
	always@ (*) begin
		if (x_addr == 0 || x_addr == 320 || y_addr == 0 || y_addr == 240) begin
			value = 8'hFF;
		end

		else begin
			value = val_temp;
		end
	end
	
assign xclk = clk_50;
	// Drive xclk (25 MHz)
//	always@ (posedge clk_50) begin
//		if (reset == 1'b1) begin
//			xclk <= 1'b0;
//		end
//		else begin
//			xclk <= ~xclk;
//		end
//	end

	// Control reset and power down
	always@ (posedge clk_50) begin
		if (reset == 1'b1) begin
			cam_rst <= 1'b0;	// rst is active low
			cam_pwdn <= 1'b1;	// pwdn is active high
		end
		else begin
			cam_rst <= 1'b1;
			cam_pwdn <= 1'b0;
		end
	end
	
	reg last_href;	// To keep track of href edges
	reg	is_lsb;		// Alternate bytes represent Y (luminance)

	// Deal with data
	always@ (posedge pclk) begin
		// Reset position at the end of frame
		if (vsync == 1'b0 && href == 1'b0 && last_href == 1'b0) begin
			x_addr <= 10'd1023;
			y_addr <= 10'b0;
			mem_addr <= 19'd524287;

			val_temp <= 8'b0;
			is_val <= 1'b0;
			is_lsb <= 1'b0;
		end

		// Frame ongoing
		else begin
			// Write alternate bytes to memory while the frame is ongoing
			if (href == 1'b1) begin
				// Copy only the Y (luminance) component of data
				if (is_lsb) begin
					x_addr <= x_addr + 10'b1;
					y_addr <= y_addr;
					if(x_addr < 320 && y_addr < 240) begin
						mem_addr <= mem_addr + 1;
						is_val <= 1'b1;
					end
					else begin
						is_val <= 1'b0;
					end
					val_temp <= data;
				end
				else begin
					x_addr <= x_addr;
					y_addr <= y_addr;
					mem_addr <= mem_addr;

					val_msb <= data;
					is_val <= 1'b0;
				end

				is_lsb <= ~is_lsb;
			end
			// Invalid line
			else begin
				val_temp <= 8'b0;
				is_val <= 1'b0;
				is_lsb <= 1'b0;

				if (last_href == 1'b1) begin
					x_addr <= 10'd1023;
					y_addr <= y_addr + 10'b1;
					mem_addr <= mem_addr;					
				end
				else begin
					x_addr <= x_addr;
					y_addr <= y_addr;
					mem_addr <= mem_addr;
				end
			end
		end

		last_href <= href;
	end

endmodule