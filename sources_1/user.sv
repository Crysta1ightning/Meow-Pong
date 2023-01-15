import object_package::*;

module user(
	input logic clk,
	input logic rst,
	input logic en, // !gameover && en && start && valid
	input logic btnU,
	input logic btnD,
	input logic btnL,
	input logic btnR,
    input object wall1,
    input object wall2,
    input object wall3,
    input object wall4,
    input object wall5,
    input object wall6,
    output object paddle_right
);   

	parameter [WIDTH-1:0] SCREEN_WIDTH = 640<<FBITS, SCREEN_HEIGHT = 480<<FBITS; // floating
	parameter [WIDTH-1:0] paddle_width = 8<<FBITS, paddle_height = 100<<FBITS; // floating
    logic c;
	object next_paddle_right, temp1, temp2;
    
	// User paddle
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			paddle_right.x <= SCREEN_WIDTH*7/8 - paddle_width/2;
			paddle_right.y <= SCREEN_HEIGHT/2 - paddle_height/2;
			paddle_right.width <= paddle_width;
			paddle_right.height <= paddle_height;
			paddle_right.vx <= 12;
			paddle_right.vy <= 12;
			paddle_right.x_sign <= 0;
			paddle_right.y_sign <= 0;
			paddle_right.movable <= 1; 
		end else begin
			if (en) paddle_right <= next_paddle_right;
			else paddle_right <= paddle_right;
		end 
	end
	always_comb begin
		if (rst) begin
			set_movable(
				.x(SCREEN_WIDTH*7/8 - paddle_width/2),
				.y(SCREEN_HEIGHT/2 - paddle_height/2),
				.width(paddle_width),
				.height(paddle_height),
				.vx(12),
				.vy(12),
				.x_sign(0),
				.y_sign(0),
				.o(next_paddle_right)
			);
		end else begin
			temp1 = paddle_right;
			if (btnU) begin
				temp1.y = paddle_right.y - paddle_right.vy;
			end else if (btnD) begin
				temp1.y = paddle_right.y + paddle_right.vy;
			end 
			if (btnL) begin
				if (paddle_right.x - paddle_right.vx > SCREEN_WIDTH/2) temp1.x = paddle_right.x - paddle_right.vx;
			end else if (btnR) begin
				if (paddle_right.x + paddle_right.vx < SCREEN_WIDTH-paddle_right.width) temp1.x = paddle_right.x + paddle_right.vx;
			end
			collide_wall(temp1, wall1, wall2, wall3, wall4, wall5, wall6, c, temp2);
			if (!c) next_paddle_right = temp1;
			else next_paddle_right = paddle_right;
		end
	end

endmodule
