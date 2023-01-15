`include "object_package.sv"
import object_package::*;
parameter WIDTH = 32;
parameter FBITS = 16;

module pixel_gen(
	input clk,
	input rst,
	input en,
	input absorb,
	input [9:0] h_cnt,
	input [9:0] v_cnt,
	input btnU,
	input btnD,
	input btnL,
	input btnR,
	input valid,
	output logic [3:0] vgaRed,
	output logic [3:0] vgaGreen,
	output logic [3:0] vgaBlue
);   

	parameter [WIDTH-1:0] SCREEN_WIDTH = 640<<FBITS, SCREEN_HEIGHT = 480<<FBITS; // floating

	// color 
	parameter [11:0] ball_color [4:0] = {12'h57f, 12'hf57, 12'h7f5, 12'hf22, 12'hfd2};
	parameter [11:0] wall_color = 12'hf0f, paddle_color = 12'hfff, mid_line_color = 12'h333, score_color = 12'hfff, word_color = 12'hfff;

	// objects
	object ball1, ball2;
	object wall1, wall2, wall3, wall4, wall5, wall6;
	object paddle_left, paddle_right, next_paddle_left, next_paddle_right;
	object mid_line, left_line, right_line;
		
	// start game after some cycles so that the ball doesn't move so quick
	logic [20:0] game_start_counter, next_game_start_counter;
	wire start;

	// random number
    logic [7:0] rnum;
	random_number_generator rng0 (clk, rnum);
	
	// score
	object score1, score2;
	logic [2:0]	s1, s2, next_s1, next_s2;
	
	// gameover
	object w1, w2;
	logic gameover, next_gameover;

	// pictures
	logic [7:0][7:0] ball_pic;
	logic [7:0][7:0] s1_pic;
	logic [7:0][7:0] s2_pic;
	logic [7:0][15:0] win_pic;
	picture_gen pg0 (.id(4'd8), .pic(ball_pic));
	picture_gen pg1 (.id(s1), .pic(s1_pic));
	picture_gen pg2 (.id(s2), .pic(s2_pic));
	picture_gen #(.WIDTH(16)) pg3 (.id(4'd9), .pic(win_pic));

	// picture display
	assign in_ball1 = (ball1.x>>FBITS <= h_cnt && (ball1.x + ball1.width)>>FBITS > h_cnt && ball1.y>>FBITS <= v_cnt && (ball1.y + ball1.height)>>FBITS >= v_cnt &&
					  ball_pic[7-(v_cnt-(ball1.y>>FBITS))/2][7-(h_cnt-(ball1.x>>FBITS))/2] == 1'b1);
	assign in_ball2 = (ball2.x>>FBITS <= h_cnt && (ball2.x + ball2.width)>>FBITS > h_cnt && ball2.y>>FBITS <= v_cnt && (ball2.y + ball2.height)>>FBITS >= v_cnt &&
					  ball_pic[7-(v_cnt-(ball2.y>>FBITS))/2][7-(h_cnt-(ball2.x>>FBITS))/2] == 1'b1);
	assign in_wall1 = (wall1.x>>FBITS <= h_cnt && (wall1.x + wall1.width)>>FBITS > h_cnt && wall1.y>>FBITS <= v_cnt && (wall1.y + wall1.height)>>FBITS > v_cnt);
	assign in_wall2 = (wall2.x>>FBITS <= h_cnt && (wall2.x + wall2.width)>>FBITS > h_cnt && wall2.y>>FBITS <= v_cnt && (wall2.y + wall2.height)>>FBITS > v_cnt);
	assign in_wall3 = (wall3.x>>FBITS <= h_cnt && (wall3.x + wall3.width)>>FBITS > h_cnt && wall3.y>>FBITS <= v_cnt && (wall3.y + wall3.height)>>FBITS > v_cnt);
	assign in_wall4 = (wall4.x>>FBITS <= h_cnt && (wall4.x + wall4.width)>>FBITS > h_cnt && wall4.y>>FBITS <= v_cnt && (wall4.y + wall4.height)>>FBITS > v_cnt);
	assign in_wall5 = (wall5.x>>FBITS <= h_cnt && (wall5.x + wall5.width)>>FBITS > h_cnt && wall5.y>>FBITS <= v_cnt && (wall5.y + wall5.height)>>FBITS > v_cnt);
	assign in_wall6 = (wall6.x>>FBITS <= h_cnt && (wall6.x + wall6.width)>>FBITS > h_cnt && wall6.y>>FBITS <= v_cnt && (wall6.y + wall6.height)>>FBITS > v_cnt);
	assign in_wall = (in_wall1 | in_wall2 | in_wall3 | in_wall4 | in_wall5 | in_wall6);
	assign in_paddle_left = (paddle_left.x>>FBITS <= h_cnt && (paddle_left.x + paddle_left.width)>>FBITS > h_cnt && paddle_left.y>>FBITS <= v_cnt && (paddle_left.y + paddle_left.height)>>FBITS > v_cnt);
	assign in_paddle_right = (paddle_right.x>>FBITS <= h_cnt && (paddle_right.x + paddle_right.width)>>FBITS > h_cnt && paddle_right.y>>FBITS <= v_cnt && (paddle_right.y + paddle_right.height)>>FBITS > v_cnt);
	assign in_mid_line = (v_cnt%30 > 10 && v_cnt%30 < 20) && (mid_line.x>>FBITS <= h_cnt && (mid_line.x + mid_line.width)>>FBITS > h_cnt && mid_line.y>>FBITS <= v_cnt && (mid_line.y + mid_line.height)>>FBITS > v_cnt);
	int length = (h_cnt - (SCREEN_WIDTH>>FBITS)/2)*(h_cnt - (SCREEN_WIDTH>>FBITS)/2) + (v_cnt - (SCREEN_HEIGHT>>FBITS)/2)*(v_cnt - (SCREEN_HEIGHT>>FBITS)/2);
	assign in_circle = (length > 1000 && length < 1100) || (length > 3000 && length < 3200);
	assign in_score1 = (score1.x>>FBITS <= h_cnt && (score1.x + score1.width)>>FBITS > h_cnt && score1.y>>FBITS <= v_cnt && (score1.y + score1.height)>>FBITS > v_cnt && 
					   s1_pic[7-(v_cnt-(score1.y>>FBITS))/8][7-(h_cnt-(score1.x>>FBITS))/8] == 1'b1);
	assign in_score2 = (score2.x>>FBITS <= h_cnt && (score2.x + score2.width)>>FBITS > h_cnt && score2.y>>FBITS <= v_cnt && (score2.y + score2.height)>>FBITS > v_cnt && 
					   s2_pic[7-(v_cnt-(score2.y>>FBITS))/8][7-(h_cnt-(score2.x>>FBITS))/8] == 1'b1);
	assign in_w1 = (gameover && s1 == 3'd7 && w1.x>>FBITS <= h_cnt && (w1.x + w1.width)>>FBITS > h_cnt && w1.y>>FBITS <= v_cnt && (w1.y + w1.height)>>FBITS > v_cnt && 
					   win_pic[7-(v_cnt-(w1.y>>FBITS))/8][15-(h_cnt-(w1.x>>FBITS))/8] == 1'b1);
	assign in_w2 = (gameover && s2 == 3'd7 && w2.x>>FBITS <= h_cnt && (w2.x + w2.width)>>FBITS > h_cnt && w2.y>>FBITS <= v_cnt && (w2.y + w2.height)>>FBITS > v_cnt && 
					   win_pic[7-(v_cnt-(w2.y>>FBITS))/8][15-(h_cnt-(w2.x>>FBITS))/8] == 1'b1);

	stage st (.wall1(wall1), .wall2(wall2), .wall3(wall3), .wall4(wall4), .wall5(wall5), .wall6(wall6), .mid_line(mid_line));

	ball b(.clk(clk), .rst(rst), .en(!gameover && en && start && valid), .absorb(absorb), .rnum(rnum), .paddle_left(paddle_left), .paddle_right(paddle_right),
		   .wall1(wall1), .wall2(wall2), .wall3(wall3), .wall4(wall4), .wall5(wall5), .wall6(wall6), .ball1(ball1), .ball2(ball2));

	user u (.clk(clk), .rst(rst), .en(!gameover && en && start && valid), .btnU(btnU), .btnD(btnD), .btnL(btnL), .btnR(btnR),
			.wall1(wall1), .wall2(wall2), .wall3(wall3), .wall4(wall4), .wall5(wall5), .wall6(wall6), .paddle_right(paddle_right));

	ai a (.clk(clk), .rst(rst), .en(!gameover && en && start && valid), .rnum(rnum), .ball1(ball1), .ball2(ball2),
		  .wall1(wall1), .wall2(wall2), .wall3(wall3), .wall4(wall4), .wall5(wall5), .wall6(wall6), .paddle_left(paddle_left));
	
	gameover_score gs (.clk(clk), .rst(rst), .ball1(ball1), .ball2(ball2), .score1(score1), .score2(score2), .w1(w1), .w2(w2), .s1(s1), .s2(s2), .gameover(gameover));

	// wait for some time before start
	always_ff @(posedge clk, posedge rst) begin
		if (rst) game_start_counter <= 21'd0;
		else game_start_counter <= next_game_start_counter;
	end
	always_comb begin
		if (rst) next_game_start_counter = 21'd0;
		else if (game_start_counter < 21'd2097151) begin
			next_game_start_counter = game_start_counter+1;
		end else next_game_start_counter = 21'd2097151;
	end
	assign start = (game_start_counter == 21'd2097151);

	// output image
	always_comb begin
		if (!valid) begin
			{vgaRed, vgaGreen, vgaBlue} = 12'h0;
		end else begin
			if (in_w1 | in_w2) begin
				{vgaRed, vgaGreen, vgaBlue} = word_color;
			end else if (in_score1 | in_score2) begin
				{vgaRed, vgaGreen, vgaBlue} = score_color;
			end else if (in_ball1) begin
				{vgaRed, vgaGreen, vgaBlue} = ball_color[ball1.color_choice];
			end else if (in_ball2) begin
				{vgaRed, vgaGreen, vgaBlue} = ball_color[ball2.color_choice];
			end else if (in_paddle_left | in_paddle_right) begin
				{vgaRed, vgaGreen, vgaBlue} = paddle_color;
			end  else if (in_wall) begin
				{vgaRed, vgaGreen, vgaBlue} = wall_color;
			end else if (in_mid_line | in_circle) begin
				{vgaRed, vgaGreen, vgaBlue} = mid_line_color;
			end else begin
				{vgaRed, vgaGreen, vgaBlue} = 12'h0;
			end 
			
			if (gameover) begin
				vgaRed = 15-vgaRed;
				vgaGreen = 15-vgaGreen;
				vgaBlue = 15-vgaBlue;
			end
		end
	end
	   

endmodule
