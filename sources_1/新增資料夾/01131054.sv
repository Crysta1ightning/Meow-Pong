import vec3_package::*;
parameter WIDTH = 32;
parameter FBITS = 16;

module pixel_gen(
	input reg clk,
	input reg rst,
	input [9:0] h_cnt,
	input [9:0] v_cnt,
	input valid,
	output reg [3:0] vgaRed,
	output reg [3:0] vgaGreen,
	output reg [3:0] vgaBlue
);   
	parameter [WIDTH-1:0] H_DIV = 32'd1638; // 15.9999 * 1/640
	parameter [WIDTH-1:0] V_DIV = 32'd2184; // 15.9999 * 1/480
	parameter [WIDTH-1:0] ONE_FOURTH = 32'd262142; // 15.9999 * 0.25
	logic [WIDTH-1:0] _x, _y, _z; 
	logic [WIDTH-1:0] u, v; 
	// logic [WIDTH*2-1:0] temp1, temp2, temp3, temp4;
	vec3 temp1, temp2, temp3, temp4;
	color pixel_color;

	// Image
	parameter [WIDTH-1:0] aspect_ratio = 640 / 480;
	parameter [WIDTH-1:0] image_width = 640;
	parameter [WIDTH-1:0] image_height = 480;

	// Camera
	parameter [WIDTH-1:0] viewport_height = 32'd131072; // 2.0
	parameter [WIDTH-1:0] viewport_width = 32'd174763; // 2.66666666
	parameter [WIDTH-1:0] focal_length = 32'd65536; // 1.0

	// To Store the image
	// (Use blk_mem_gen_0 instead) reg [239:0] image [319:0][11:0]; // 240*320*12
	reg image_ready, next_image_ready;
	reg [8:0] h_now, v_now, next_h_now, next_v_now; // 320, 240
	reg [11:0] next_pixel;
	reg [11:0] pixel_bf;
	wire [16:0] pixel_addr = (image_ready)? 320*(v_cnt>>1) + (h_cnt>>1) : 320*v_now + h_now;
	wire rw = ~image_ready; // 0 for read, 1 for write

	blk_mem_gen_0 blk_mem_gen_0_inst(
        .clka(clk),
        .wea(rw), // 0: read 1: write 
        .addra(pixel_addr), // address
        .dina(next_pixel), // what to write in 
        .douta(pixel_bf) // rgb
    );



	point origin;
	vec3 horizontal;
	vec3 vertical;
	vec3 focal_vec;
	vec3 lower_left_corner;
	ray r;
	reg [1:0] fake_cycle, next_fake_cycle; // takes 4 clk to generate a pixel


	// store image
	always_comb begin // next_pixel
		if (rst) begin
			set(0, 0, 0, origin);
			set(viewport_width, 0, 0, horizontal);
			set(0, viewport_height, 0, vertical);
			set(0, 0, focal_length, focal_vec);
			set_lower_left(origin, horizontal, vertical, focal_vec, lower_left_corner);
			next_pixel = 12'b0000_0000_0000;
		end else begin
			if (image_ready) next_pixel = 12'b0000_0000_0000;
			else begin
				if (fake_cycle == 2'b11) begin
					next_pixel = 12'b0000_1111_1111; // Aqua
				end else begin
					next_pixel = 12'b0000_0000_1111; // Bllue
				end
			end
		end
	end
	always_ff @(posedge clk, posedge rst) begin // h_now, v_now
		if (rst) begin
			h_now <= 0;
			v_now <= 0;
		end else begin
			h_now <= next_h_now;
			v_now <= next_v_now;
		end
	end
	always_comb begin 
		if (rst) begin
			next_h_now = 0;
			next_v_now = 0;
		end else begin
			if (image_ready) begin
				next_h_now = h_now;
				next_v_now = v_now;
			end else begin
				if (fake_cycle == 2'b11) begin
					if (h_now == 319) begin
						next_h_now = 0;
						next_v_now = v_now+1;
					end else begin
						next_h_now = h_now+1;
						next_v_now = v_now;
					end
				end else begin
					next_h_now = h_now;
					next_v_now = v_now;
				end
			end
		end
	end
	always_ff @(posedge clk, posedge rst) begin // image_ready
		if (rst) image_ready <= 0;
		else image_ready <= next_image_ready;
	end
	always_comb begin
		if (rst) begin
			next_image_ready = 0;
		end else begin
			if (image_ready) next_image_ready = 1;
			else if (h_now == 319 && v_now == 239 && fake_cycle == 2'b11) begin
				next_image_ready = 1;
			end else next_image_ready = 0;
		end
	end
	always_ff @(posedge clk, posedge rst) begin
		if (rst) fake_cycle <= 0;
		else fake_cycle <= next_fake_cycle;
	end
	always_comb begin
		if (rst) next_fake_cycle = 0;
		else next_fake_cycle = fake_cycle+1;
	end

	// get image
	always_comb begin
		if (rst) begin
			{vgaRed, vgaGreen, vgaBlue} = 12'b0000_0000_0000;
		end else begin
			if (!valid) begin
				{vgaRed, vgaGreen, vgaBlue} = 12'b0000_0000_0000;
			end else if (image_ready) begin
				if (h_cnt < 45) {vgaRed, vgaGreen, vgaBlue} = 12'b1111_0000_0000;
				else {vgaRed, vgaGreen, vgaBlue} = pixel_bf;
			end else begin
				{vgaRed, vgaGreen, vgaBlue} = 12'b0000_1111_0011;
			end
		end
	end

	
		
	// always_comb begin
	// 	if (rst) begin
	// 		{vgaRed, vgaGreen, vgaBlue} = 12'h0;
	// 	end else begin
	// 		if(!valid) begin
	// 			{vgaRed, vgaGreen, vgaBlue} = 12'h0;
	// 		end else begin
				
	// 			u = (V_DIV * (480-v_cnt)) >> FBITS;
	// 			v = (H_DIV * h_cnt) >> FBITS;

	// 			// ray r(origin, lower_left_corner + u*horizontal + v*vertical - origin);
	// 			scale(horizontal, u, temp1);
	// 			scale(vertical, v, temp2); 
	// 			add(lower_left_corner, temp1, temp1);
	// 			minus(temp2, origin, temp2);
	// 			add(temp1, temp2, temp1);
	// 			set_r(origin, temp1, r);
	// 			// r.orig = origin;
	// 			// r.dir = temp1;

	// 			// // set _x, _y, _z by r
	// 			// set(_x, _y, _z, pixel_color);
	// 			// vgaRed = pixel_color.x;
	// 			// vgaGreen = pixel_color.y;
	// 			// vgaBlue = pixel_color.z;
	// 		end
	// 	end
	// end
endmodule
