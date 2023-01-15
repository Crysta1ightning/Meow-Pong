import object_package::*;

module ball (
    input logic clk,
    input logic rst,
    input logic en, // !gameover && en && start && valid
    input logic absorb, 
    input logic [7:0] rnum,
    input object paddle_left,
    input object paddle_right,
    input object wall1,
    input object wall2,
    input object wall3,
    input object wall4,
    input object wall5, 
    input object wall6,
	output object ball1, 
    output object ball2
);   
    logic c;
    object next_ball1, next_ball2, temp1;
	parameter [WIDTH-1:0] SCREEN_WIDTH = 640<<FBITS, SCREEN_HEIGHT = 480<<FBITS; // floating
    parameter [WIDTH-1:0] ball_width = 16<<FBITS, ball_height = 16<<FBITS; // floating
    logic [20:0] absorb_counter, next_absorb_counter;
    logic [1:0] collide_counter, next_collide_counter;

    always_ff @(posedge clk, posedge rst) begin
        if (rst) absorb_counter <= 0;
        else absorb_counter <= next_absorb_counter;
    end
    always_ff @(posedge clk, posedge rst) begin
        if (rst)  collide_counter <= 0;
        else collide_counter <= next_collide_counter;
    end 
    always_comb begin
        if (rst) next_absorb_counter = 0;
        else if (absorb) begin
            if (absorb_counter < 21'd2097151) next_absorb_counter = absorb_counter + 1;
            else next_absorb_counter = 21'd2097151;
        end else next_absorb_counter = 0;
    end

    assign should_absorb = (absorb && absorb_counter < 21'd2097151);

	// ball
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			ball1.x <= SCREEN_WIDTH/2 - ball_width/2;
			ball1.y <= SCREEN_HEIGHT/2 - ball_height/2 - (32<<FBITS);
			ball1.width <= ball_width;
			ball1.height <= ball_height;
			ball1.vx <= rnum[2:0];
			ball1.vy <= rnum[4:2];
			ball1.x_sign <= rnum[0];
			ball1.y_sign <= rnum[1];
			ball1.movable <= 1;
			ball1.color_choice <= rnum[6:4] % 5;

			ball2.x <= SCREEN_WIDTH/2 - ball_width/2;
			ball2.y <= SCREEN_HEIGHT/2 - ball_height/2 + (32<<FBITS);
			ball2.width <= ball_width;
			ball2.height <= ball_height;
			ball2.vx <= 7-rnum[2:0];
			ball2.vy <= 7-rnum[4:2];
			ball2.x_sign <= rnum[1];
			ball2.y_sign <= rnum[0];
			ball2.movable <= 1;
			ball2.color_choice <= rnum[7:5] % 5;
		end else begin
			if (en) begin
				ball1 <= next_ball1;
				ball2 <= next_ball2;
			end
			else begin
				ball1 <= ball1;
				ball2 <= ball2;
			end
		end
	end
	always_comb begin 
		if (rst) begin
			set_movable(
				.x(SCREEN_WIDTH/2 - ball_width/2),
				.y(SCREEN_HEIGHT/2 - ball_height/2),
				.width(ball_width),
				.height(ball_height),
				.vx(rnum[2:0]), 
				.vy(rnum[4:2]),
				.x_sign(rnum[0]),
				.y_sign(rnum[1]),
				.o(next_ball1)
			);
			set_movable(
				.x(SCREEN_WIDTH/2 - ball_width/2),
				.y(SCREEN_HEIGHT/2 - ball_height/2),
				.width(ball_width),
				.height(ball_height),
				.vx(7-rnum[2:0]),
				.vy(7-rnum[4:2]),
				.x_sign(rnum[1]),
				.y_sign(rnum[0]),
				.o(next_ball2)
			);
			next_ball1.color_choice = rnum[6:4] % 5;
			next_ball2.color_choice = rnum[7:5] % 5;
            next_collide_counter = 0;
		end else begin
			if (ball1.x > SCREEN_WIDTH) begin
				set_movable(
					.x(SCREEN_WIDTH/2 - ball_width/2),
					.y(SCREEN_HEIGHT/2 - ball_height/2 - (32<<FBITS)),
					.width(ball_width),
					.height(ball_height),
					.vx(rnum[2:0]),
					.vy(rnum[4:2]),
					.x_sign(rnum[0]),
					.y_sign(rnum[1]),
					.o(next_ball1)
				);
				next_ball1.color_choice = rnum[6:4] % 5;
			end else begin
                if (should_absorb) begin
                    next_ball1 = ball1;
                    if (ball1.x+ball1.width/2 > paddle_right.x+paddle_right.width/2) begin
                        if (ball1.x+ball1.width/2 - (paddle_right.x+paddle_right.width/2) > (30<<FBITS)) next_ball1.x = ball1.x - 8;
                        else next_ball1.x = ball1.x + 1;
                    end
                    else if ((ball1.x+ball1.width/2) < paddle_right.x+paddle_right.width/2) begin
                        if ((paddle_right.x+paddle_right.width/2) - (ball1.x+ball1.width/2) > (30<<FBITS)) next_ball1.x = ball1.x + 8;
                        else next_ball1.x = ball1.x - 1;
                    end 
                    else next_ball1.x = ball1.x + 1;

                    if (ball1.y+ball1.height/2 > paddle_right.y+paddle_right.height/2) begin
                        if (ball1.y+ball1.height/2 - (paddle_right.y+paddle_right.height/2) > (30<<FBITS)) next_ball1.y = ball1.y - 8;
                        else next_ball1.y = ball1.y + 1;
                    end 
                    else if ((ball1.y+ball1.height/2) < paddle_right.y+paddle_right.height/2) begin
                        if ((paddle_right.y+paddle_right.height/2) - (ball1.y+ball1.height/2) > (30<<FBITS)) next_ball1.y = ball1.y + 8;
                        else next_ball1.y = ball1.y - 1;
                    end
                    else next_ball1.y = ball1.y + 1;
                end else begin
                    move(ball1, next_ball1);
                    collide_paddle(next_ball1, paddle_left, paddle_right, rnum[5:3], c, temp1);
                    if (c) next_ball1 = temp1;
                    else begin
                        collide_wall(next_ball1, wall1, wall2, wall3, wall4, wall5, wall6, c, temp1);
                        if (c) next_ball1 = temp1;
                    end
                end
            end
			if (ball2.x > SCREEN_WIDTH) begin
				set_movable(
					.x(SCREEN_WIDTH/2 - ball_width/2),
					.y(SCREEN_HEIGHT/2 - ball_height/2 + (32<<FBITS)),
					.width(ball_width),
					.height(ball_height),
					.vx(7-rnum[2:0]),
					.vy(7-rnum[4:2]),
					.x_sign(rnum[1]),
					.y_sign(rnum[0]),
					.o(next_ball2)
				);
				next_ball2.color_choice = rnum[7:5] % 5;
			end else begin
                if (should_absorb) begin
                    next_ball2 = ball2;
                    if (ball2.x+ball2.width/2 > paddle_right.x+paddle_right.width/2) begin
                        if (ball2.x+ball2.width/2 - (paddle_right.x+paddle_right.width/2) > (30<<FBITS)) next_ball2.x = ball2.x - 8;
                        else next_ball2.x = ball2.x + 1;
                    end
                    else if ((ball2.x+ball2.width/2) < paddle_right.x+paddle_right.width/2) begin
                        if ((paddle_right.x+paddle_right.width/2) - (ball2.x+ball2.width/2) > (30<<FBITS)) next_ball2.x = ball2.x + 8;
                        else next_ball2.x = ball2.x - 1;
                    end 
                    else next_ball2.x = ball2.x + 1;

                    if (ball2.y+ball2.height/2 > paddle_right.y+paddle_right.height/2) begin
                        if (ball2.y+ball2.height/2 - (paddle_right.y+paddle_right.height/2) > (30<<FBITS)) next_ball2.y = ball2.y - 8;
                        else next_ball2.y = ball2.y + 1;
                    end 
                    else if ((ball2.y+ball2.height/2) < paddle_right.y+paddle_right.height/2) begin
                        if ((paddle_right.y+paddle_right.height/2) - (ball2.y+ball2.height/2) > (30<<FBITS)) next_ball2.y = ball2.y + 8;
                        else next_ball2.y = ball2.y - 1;
                    end
                    else next_ball2.y = ball2.y + 1;
                end else begin
                    move(ball2, next_ball2);
                    collide_paddle(next_ball2, paddle_left, paddle_right, rnum[5:3], c, temp1);
                    if (c) next_ball2 = temp1;
                    else begin
                        collide_wall(next_ball2, wall1, wall2, wall3, wall4, wall5, wall6, c, temp1);
                        if (c) next_ball2 = temp1;
                    end
                end
			end
			collide_ball(next_ball1, next_ball2, c, next_ball1, next_ball2);
            if (c) begin
                if (collide_counter != 3) next_collide_counter = collide_counter + 1;
                else begin
                    next_collide_counter = 3;
                    if (next_ball1.y > next_ball2.y) begin
                        next_ball1.y = next_ball1.y + 8;
                        next_ball2.y = next_ball2.y - 8;
                    end else begin
                        next_ball1.y = next_ball1.y - 8;
                        next_ball2.y = next_ball2.y + 8;
                    end 
                    if (next_ball1.x > next_ball2.x) begin
                        next_ball1.x = next_ball1.x + 8;
                        next_ball2.x = next_ball2.x - 8;
                    end else begin
                        next_ball1.x = next_ball1.x - 8;
                        next_ball2.x = next_ball2.x + 8;
                    end 
                end
            end else next_collide_counter = 0;
		end
    end
endmodule