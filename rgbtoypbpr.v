// Multiplier-based RGB -> YPbPr conversion

// Copyright 2020/2021 by Alastair M. Robinson
// Adjusted for 6-bit input, 6-bit output.

module rgbtoypbpr
(
	input clk,
	input ena,

	input [5:0] red_in,
	input [5:0] green_in,
	input [5:0] blue_in,
	input hs_in,
	input vs_in,
	input cs_in,
	input pixel_in,

	output [5:0] red_out,
	output [5:0] green_out,
	output [5:0] blue_out,
	output reg hs_out,
	output reg vs_out,
	output reg cs_out,
	output reg pixel_out
);

reg [13:0] r_y;
reg [13:0] g_y;
reg [13:0] b_y;

reg [13:0] r_b;
reg [13:0] g_b;
reg [13:0] b_b;

reg [13:0] r_r;
reg [13:0] g_r;
reg [13:0] b_r;

reg [13:0] y;
reg [13:0] b;
reg [13:0] r;

reg hs_d;
reg vs_d;
reg cs_d;
reg pixel_d;

assign red_out = r[13:8];
assign green_out = y[13:8];
assign blue_out = b[13:8];

// Multiply in the first stage...
always @(posedge clk) begin	
	hs_d <= hs_in;		// Register sync, pixel clock, etc
	vs_d <= vs_in;		// so they're delayed the same amount as the incoming video
	cs_d <= cs_in;
	pixel_d <= pixel_in;
		
	if(ena) begin
		// (Y  =  0.299*R + 0.587*G + 0.114*B)
		r_y <= red_in * 8'd76;
		g_y <= green_in * 8'd150;
		b_y <= blue_in * 8'd29;

		// (Pb = -0.169*R - 0.331*G + 0.500*B)
		r_b <= red_in * 8'd43;
		g_b <= green_in * 8'd84;
		b_b <= blue_in * 8'd128;

		// (Pr =  0.500*R - 0.419*G - 0.081*B)
		r_r <= red_in * 8'd128;
		g_r <= green_in * 8'd107;
		b_r <= blue_in * 8'd20;
	end else begin
		r_r[13:8] <= red_in; // Passthrough
		g_y[13:8] <= green_in;
		b_b[13:8] <= blue_in;
	end

end

// Second stage - adding
	
always @(posedge clk) begin	
	hs_out <= hs_d;
	vs_out <= vs_d;
	cs_out <= cs_d;
	pixel_out <= pixel_d;

	if(ena) begin
		y <= r_y + g_y + b_y;
		b <= 14'd8192 + b_b - r_b - g_b;
		r <= 14'd8192 + r_r - g_r - b_r;	
	end else begin
		y <= g_y;	// Passthrough
		b <= b_b;
		r <= r_r;
	end
end

endmodule
