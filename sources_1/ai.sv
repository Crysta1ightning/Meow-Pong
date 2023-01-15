import object_package::*;

module ai(
	input logic clk,
	input logic rst,
	input logic en, // !gameover && en && start && valid
    input logic [7:0] rnum,
    input object wall1,
    input object wall2,
    input object wall3,
    input object wall4,
    input object wall5,
    input object wall6,
    input object ball1,
    input object ball2,
    output object paddle_left
);   

	parameter [WIDTH-1:0] SCREEN_WIDTH = 640<<FBITS, SCREEN_HEIGHT = 480<<FBITS; // floating
	parameter [WIDTH-1:0] paddle_width = 8<<FBITS, paddle_height = 100<<FBITS; // floating
    logic c;
	object next_paddle_left, temp1, temp2;
    

	// AI paddle
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			paddle_left.x <= SCREEN_WIDTH/8 - paddle_width/2;
			paddle_left.y <= SCREEN_HEIGHT/2 - paddle_height/2;
			paddle_left.width <= paddle_width;
			paddle_left.height <= paddle_height;
			paddle_left.vx <= 12;
			paddle_left.vy <= 12;
			paddle_left.x_sign <= 0;
			paddle_left.y_sign <= 0;
		end else begin
			if (en) paddle_left <= next_paddle_left; 
			else paddle_left <= paddle_left;
		end
	end
	always_comb begin
		if (rst) begin
			set_movable(
				.x(SCREEN_WIDTH/8 - paddle_width/2),
				.y(SCREEN_HEIGHT/2 - paddle_height/2),
				.width(paddle_width),
				.height(paddle_height),
				.vx(12),
				.vy(12),
				.x_sign(0),
				.y_sign(0),
				.o(next_paddle_left)
			);
		end else begin
			predict_move(paddle_left, ball1, ball2, rnum[5:4], temp1);
			collide_wall(temp1, wall1, wall2, wall3, wall4, wall5, wall6, c, temp2);
			if (!c) next_paddle_left = temp1;
			else next_paddle_left = paddle_left;
		end 
	end
	

endmodule
