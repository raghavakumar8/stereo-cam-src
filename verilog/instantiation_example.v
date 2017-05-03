/* This is only an example. Don't try to compile this. */

//=======================================================
//  REG/WIRE declarations
//=======================================================

	reg				CLOCK_25;

	wire	[7:0] 	VAL;
	wire	[9:0] 	PIXEL_X;
	wire	[9:0]	PIXEL_Y;

//=======================================================
//  Structural coding
//=======================================================

	// Debugging pins
	assign LEDR[7:0] = GPIO_0[7:0];	//data
	assign LEDR[8] = GPIO_0[28];		//vsync
	assign LEDR[9] = GPIO_0[29];		//href
	
	//assign GPIO_1 = GPIO_0;
	assign GPIO_1[17:10] = VAL;
	assign GPIO_1[25:18] = VGA_R;
	assign GPIO_1[35] = VGA_HS;
	assign GPIO_1[34] = VGA_VS;
	
	// Generate 25 MHz clock
	always @(posedge CLOCK_50) begin
		CLOCK_25 <= ~CLOCK_25;
	end
	
	// Instantiate VGA driver
	VGA_Controller driver(
		.iCursor_RGB_EN(4'b0111),
		.iCursor_X(16'b0),
		.iCursor_Y(16'b0),
		.iCursor_R(8'hFF),
		.iCursor_G(8'd0),
		.iCursor_B(8'd0),
		.oAddress(),
		.oCoord_X(PIXEL_X),
		.oCoord_Y(PIXEL_Y),
		.iRed(VAL),
		.iGreen(8'b0),
		.iBlue(8'hff),
		
		//	VGA Side
		.oVGA_R(VGA_R),
		.oVGA_G(VGA_G),
		.oVGA_B(VGA_B),
		.oVGA_H_SYNC(VGA_HS),
		.oVGA_V_SYNC(VGA_VS),
		.oVGA_SYNC(VGA_SYNC_N),
		.oVGA_BLANK(VGA_BLANK_N),
		
		//	Control Signal
		.iCLK(CLOCK_25),
		.iRST_N(KEY[1])	
	);
	
	/* Camera connections:
	 *  xclk     -- GPIO[26]
	 *  pclk     -- GPIO[27]
	 *  vsync    -- GPIO[28]
	 *  href     -- GPIO[29]
	 *  data     -- GPIO[7:0]
	 *  cam_rst  -- GPIO[30]
	 *  cam_pwdn -- GPIO[31] */
	 
	cam_buffer cam0(
		.clk_50(CLOCK_50),
		.reset(~KEY[0]),
		.xclk(GPIO_0[26]),
		.pclk(GPIO_0[27]),
		.vsync(GPIO_0[28]),
		.href(GPIO_0[29]),
		.data(GPIO_0[7:0]),
		.cam_rst(GPIO_0[30]),
		.cam_pwdn(GPIO_0[31]),
		.rd_clk(CLOCK_25),
		.x_addr(PIXEL_X),
		.y_addr(PIXEL_Y),
		.value(VAL),
		.is_wr_val(GPIO_1[9]),
		.wr_val(GPIO_1[8:0])
	);
	
	/*ov7670 cam0(
		.clk_50(CLOCK_50),
		.reset(~KEY[0]),
		.xclk(GPIO_0[26]),
		.pclk(GPIO_0[27]),
		.vsync(GPIO_0[28]),
		.href(GPIO_0[29]),
		.data(GPIO_0[7:0]),
		.cam_rst(GPIO_0[30]),
		.cam_pwdn(GPIO_0[31]),
		.value(),
		.x_addr(),
		.y_addr(),
		.mem_addr(),
		.is_val()
	);*/