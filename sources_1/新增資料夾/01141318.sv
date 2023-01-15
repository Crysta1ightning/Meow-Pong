package vec3_package;
    parameter WIDTH = 32;
    parameter FBITS = 16;

    // VEC3
    typedef struct {
        int x;
        int y;
        int z;    
    } vec3;
    typedef vec3 color;
    typedef vec3 point;
    task set;
        input int _x, _y, _z;
        output vec3 v; 
        begin
            v.x = _x;
            v.y = _y;
            v.z = _z;
        end
    endtask
    task add;
        input vec3 v1, v2;
        output vec3 v3;
        begin
            set(v1.x+v2.x, v1.y+v2.y, v1.z+v2.z, v3);
        end
    endtask
    task minus;
        input vec3 v1, v2;
        output vec3 v3;
        begin
            set(v1.x-v2.x, v1.y-v2.y, v1.z-v2.z, v3);
        end
    endtask
    task dot;
        input vec3 v1, v2;
        output vec3 v3;
        begin
            automatic int temp_x = (v1.x*v2.x)/65536;
            automatic int temp_y = (v1.y*v2.y)/65536;
            automatic int temp_z = (v1.z*v2.z)/65536;
            set(temp_x, temp_y, temp_z, v3);
        end
    endtask
    task scale;
        input vec3 v_in;
        input int t;
        output vec3 v_out;
        begin
            automatic int temp_x = (v_in.x*t)/65536;
            automatic int temp_y = (v_in.y*t)/65536;
            automatic int temp_z = (v_in.z*t)/65536;
            set(temp_x, temp_y, temp_z, v_out);
        end
    endtask
	task scale_div;
        input vec3 v_in;
        input int t;
        output vec3 v_out;
        begin
            automatic int temp_x = (v_in.x*65536)/t;
            automatic int temp_y = (v_in.y*65536)/t;
            automatic int temp_z = (v_in.z*65536)/t;
            set(temp_x, temp_y, temp_z, v_out);
        end
    endtask
    task length_squared;
        input vec3 v;
        output int length_squared;
        begin
            automatic int temp_x = (v.x*v.x)/65536;
            automatic int temp_y = (v.y*v.y)/65536;
            automatic int temp_z = (v.z*v.z)/65536;
            length_squared = temp_x + temp_y + temp_z;
        end
    endtask
    task set_lower_left;
        input point origin;
        input vec3 horizontal, vertical, focal_vec;
        output point lower_left_corner;
        begin
            // auto lower_left_corner = origin - horizontal/2 - vertical/2 - vec3(0, 0, focal_length);
            automatic int temp_x = origin.x - horizontal.x/2 - vertical.x/2 - focal_vec.x;
            automatic int temp_y = origin.y - horizontal.y/2 - vertical.y/2 - focal_vec.y;
            automatic int temp_z = origin.z - horizontal.z/2 - vertical.z/2 - focal_vec.z;
            set(temp_x, temp_y, temp_z, lower_left_corner);
        end
    endtask
    task to_pixel;
        input color c;
        output [11:0] pixel;
        begin
            automatic int temp_x = c.x/4096;
            automatic int temp_y = c.y/4096;
            automatic int temp_z = c.z/4096;
			pixel[11:8] = temp_x;
			pixel[7:4] = temp_y;
			pixel[3:0] = temp_z;
            // pixel = {temp_x[3:0], temp_y[3:0], temp_z[3:0]};
        end
    endtask
	
    // RAY
    typedef struct{
        point orig;
        vec3 dir;
    } ray;
    task at;
        input ray r;
        input int t;
        output point p;
        begin
            automatic vec3 scaled_dir;
            scale(r.dir, t, scaled_dir);
            add(r.orig, scaled_dir, p);
        end
    endtask
    task set_r;
        input point orig;
        input vec3 dir;
        output ray r;
        begin
            r.orig = orig;
            r.dir = dir;
        end
    endtask
    task ray_color;
        input ray r;
        output color c;
        begin
            
        end
    endtask
endpackage

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
	parameter int H_DIV = 102; // 1/640
	parameter int V_DIV = 137; // 1/480
	int _x, _y, _z; 
	int u, v, t; 
	// logic [WIDTH*2-1:0] temp1, temp2, temp3, temp4;
	vec3 temp1, temp2, temp3, temp4;
	color pixel_color;

	// Camera
	parameter int viewport_height = 131072; // 2.0
	parameter int viewport_width = 174763; // 2.66666666
	parameter int focal_length = 65536; // 1.0

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
	reg sqrt_rst, next_sqrt_rst;
	int dir_length_squared, dir_length, rem;
	vec3 unit_direction;
	reg sqrt_valid;

	sqrt #(.WIDTH(WIDTH), .FBITS(FBITS)) sqrt_inst (.clk(clk), .rst(sqrt_rst), .valid(sqrt_valid), .rad(dir_length_squared), .root(dir_length), .rem(rem));


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
				if (sqrt_valid) begin
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
			else if (h_now == 319 && v_now == 239 && sqrt_valid) begin
				next_image_ready = 1;
			end else next_image_ready = 0;
		end
	end

	// get image
	always_comb begin
		if (rst) begin
			{vgaRed, vgaGreen, vgaBlue} = 12'hfff;
		end else begin
			if (!valid) begin
				{vgaRed, vgaGreen, vgaBlue} = 12'h000;
			end else if (image_ready) begin
				// if (h_cnt > 630) {vgaRed, vgaGreen, vgaBlue} = 12'hf00;
				// else 
				{vgaRed, vgaGreen, vgaBlue} = pixel_bf;
			end else begin
				{vgaRed, vgaGreen, vgaBlue} = 12'hfff;
			end
		end
	end

			
	always_ff @(posedge clk, posedge rst) begin
		if (rst) sqrt_rst <= 0;
		else sqrt_rst <= next_sqrt_rst;
	end
	// store image
	always_comb begin // next_pixel
		if (rst) begin
			set(0, 0, 0, origin);
			set(viewport_width, 0, 0, horizontal);
			set(0, viewport_height, 0, vertical);
			set(0, 0, focal_length, focal_vec);
			set_lower_left(origin, horizontal, vertical, focal_vec, lower_left_corner);
			next_pixel = 12'h000;
			
			// do h_now = 0, v_now = 0
			v = (V_DIV * (479));
			u = (H_DIV * 0);
			// ray r(origin, lower_left_corner + u*horizontal + v*vertical - origin);
			scale(horizontal, u, temp1);
			scale(vertical, v, temp2); 
			add(lower_left_corner, temp1, temp3);
			minus(temp2, origin, temp4);
			add(temp3, temp4, temp1);
			set_r(origin, temp1, r);
			length_squared(r.dir, dir_length_squared);
			next_sqrt_rst = 1;
		end else begin
			if (image_ready) next_pixel = 12'h00f; // don't care
			else begin
				if (sqrt_valid) begin
					// store image
					// scale_div(r.dir, dir_length, unit_direction);
					scale_div(r.dir, dir_length, unit_direction);
					t = (unit_direction.y + 65535)/2;
					set(65535, 65535, 65535, temp1); // 1,1,1
					set(32768, 45875, 65535, temp2); // 0.5,0.7,1
					scale(temp1, 65535-t, temp3); // (1-t)*color(1,1,1)
					scale(temp2, t, temp4); // t*color(0.5,0.7,1)
					add(temp3, temp4, temp1);
					// temp1.x = 0;
					// temp1.y = 0;
					// set(temp1.x>>(FBITS-4), temp1.y>>(FBITS-4), temp1.z>>(FBITS-4), temp2);
					
					// next_pixel = {temp2.x[3:0], temp2.y[3:0], temp2.z[3:0]};
					to_pixel(temp1, next_pixel);

					// do next
					v = (V_DIV * (479-v_now));
					u = (H_DIV * h_now);

					// ray r(origin, lower_left_corner + u*horizontal + v*vertical - origin);
					scale(horizontal, u, temp1);
					scale(vertical, v, temp2); 
					add(lower_left_corner, temp1, temp3);
					minus(temp2, origin, temp4);
					add(temp3, temp4, temp1);
					set_r(origin, temp1, r);
					length_squared(r.dir, dir_length_squared);
					next_sqrt_rst = 1; 
				end else begin
					next_pixel = 12'h00f; // Blue
					next_sqrt_rst = 0;
				end
			end
		end
	end

endmodule
