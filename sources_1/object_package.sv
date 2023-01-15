package object_package;
    parameter WIDTH = 32;
    parameter FBITS = 16;

    // OBJECT
    typedef struct {
        logic [WIDTH-1:0] x; // indicating the top left corner
        logic [WIDTH-1:0] y;
        logic x_sign; // 0 for positive 1 for negative
		logic y_sign;
		logic [WIDTH-1:0] width;
		logic [WIDTH-1:0] height;
		logic [WIDTH-1:0] vx;
		logic [WIDTH-1:0] vy;
		logic movable;
		logic [2:0] color_choice; // 0~4
	} object;

    task set;
        input logic [WIDTH-1:0] x, y;
		input logic [WIDTH-1:0] width, height;
        output object o;
		begin
			o.x = x;
			o.y = y;
			o.width = width;
			o.height = height;
			o.vx = 0;
			o.vy = 0;
			o.x_sign = 0;
			o.y_sign = 0;
			o.movable = 0;
        end
	endtask
	task set_movable;
        input logic [WIDTH-1:0] x, y, width, height, vx, vy;
		input logic x_sign, y_sign; 
        output object o;
		begin
			o.x = x;
			o.y = y;
			o.width = width;
			o.height = height;
			o.vx = vx;
			o.vy = vy;
			o.x_sign = x_sign;
			o.y_sign = y_sign;
			o.movable = 1;
        end
	endtask
	task move;
		input object o_in;
		output object o_out;
		o_out = o_in;
		// don't worry about overflow, that is handeled else where
		if (o_in.movable) begin
			if (o_in.x_sign) begin 
				o_out.x = o_in.x - o_in.vx; 
			end else begin 
				o_out.x = o_in.x + o_in.vx; 
			end
			if (o_in.y_sign) begin
				o_out.y = o_in.y - o_in.vy; 
			end else begin
				o_out.y = o_in.y + o_in.vy; 
			end
		end 
	endtask
	task collide;
		input object o1, o2;
		output logic c; // 1 for collided 0 for not collided
		// output logic [1:0] dir; // where o2 is collided 00:up, 01:down, 10:left, 11:right
		output object o3; // o1 changed direction
		
		automatic logic in_x_range = (o1.x <= o2.x && o1.x+o1.width >= o2.x) || (o1.x >= o2.x && o1.x+o1.width <= o2.x+o2.width) || (o1.x <= o2.x+o2.width && o1.x+o1.width >= o2.x+o2.width);
		automatic logic in_y_range = (o1.y <= o2.y && o1.y+o1.height >= o2.y) || (o1.y >= o2.y && o1.y+o1.height <= o2.y+o2.height) || (o1.y <= o2.y+o2.height && o1.y+o1.height >= o2.y+o2.height);  
		
		o3 = o1;
		c = 1'b0;

		if (in_x_range && o1.y <= o2.y && o1.y+o1.height >= o2.y) begin // up
			o3.y_sign = 1;
			// dir = 2'b00;
			c = 1'b1;
		end else if (in_x_range && o1.y <= o2.y+o2.height && o1.y+o1.height >= o2.y+o2.height) begin // down
			o3.y_sign = 0;
			// dir = 2'b01;
			c = 1'b1;
		end
		if (in_y_range && o1.x <= o2.x && o1.x+o1.width >= o2.x) begin // left 
			o3.x_sign = 1;
			// dir = 2'b10;
			c = 1'b1;
		end else if (in_y_range && o1.x <= o2.x+o2.width && o1.x+o1.width >= o2.x+o2.width) begin // right
			o3.x_sign = 0;
			// dir = 2'b11;
			c = 1'b1;
		end
	endtask
	task collide_paddle;
		input object o_in;
		input object paddle_left, paddle_right;
		input logic [2:0] rnum;
		output logic c;
		output object o_out;
		collide(o_in, paddle_left, c, o_out);
		if (!c) begin
			collide(o_in, paddle_right, c, o_out);
		end
		if (c) begin
			if (o_in.vx < 10) o_out.vx = o_in.vx + 1;
			else if (o_in.vx < 20) o_out.vx = o_in.vx + o_in.vx/10;
			else o_out.vx = o_in.vx; 
			if (o_in.vy < 10) o_out.vy = o_in.vy + 1;
			else if (o_in.vy < 20) o_out.vy = o_in.vy + o_in.vy/10;
			else o_out.vy = o_in.vy;
			if (rnum[2] && o_out.vx > rnum[1:0] && o_out.vy < 20) begin
			    o_out.vx = o_out.vx - rnum[1:0];
				o_out.vy = o_out.vy + rnum[1:0];
			end else if (o_out.vy > rnum[1:0] && o_out.vx < 20) begin
			    o_out.vy = o_out.vy - rnum[1:0];
				o_out.vx = o_out.vx + rnum[1:0];
			end
		end
	endtask
	task collide_wall;
		input object o_in;
		input object wall1, wall2, wall3, wall4, wall5, wall6;
		output logic c;
		output object o_out;
		collide(o_in, wall1, c, o_out);
		if (!c) begin
			collide(o_in, wall2, c, o_out);
			if (!c) begin
				collide(o_in, wall3, c, o_out);
				if (!c) begin
					collide(o_in, wall4, c, o_out);
					if (!c) begin
						collide(o_in, wall5, c, o_out);
						if (!c) begin
							collide(o_in, wall6, c, o_out);
						end
					end
				end
			end
		end
	endtask
	task collide_ball;
		input object ball1, ball2;
		output logic c;
		output object ball3, ball4;
		automatic object o;
		collide(ball1, ball2, c, o);
		ball3 = ball1;
		ball4 = ball2;
		if (c) begin
			ball3.vx = ball2.vx;
			ball4.vx = ball1.vx;
			ball3.vy = ball2.vy;
			ball4.vy = ball1.vy;
			ball3.x_sign = ball2.x_sign;
			ball4.x_sign = ball1.x_sign;
			ball3.y_sign = ball2.y_sign;
			ball4.y_sign = ball1.y_sign;
		end
	endtask
	task predict_move;
		input object pl;
		input object ball1, ball2;
		input logic [1:0] rnum; // 0~3
		output object next_pl;
		parameter SCREEN_WIDTH = 640<<FBITS;

		automatic int temp1;
		automatic int temp2;
		automatic object ball;

		if (pl.x > ball1.x) temp1 = pl.x - ball1.x;
		else temp1 = ball1.x - pl.x;
		if (pl.y > ball1.y) temp1 = temp1 + (pl.y - ball1.y);
		else temp1 = temp1 + (ball1.y - pl.y);

		if (pl.x > ball2.x) temp2 = pl.x - ball2.x;
		else temp2 = ball2.x - pl.x;
		if (pl.y > ball2.y) temp2 = temp2 + (pl.y - ball2.y);
		else temp2 = temp2 + (ball2.y - pl.y);

		if (temp1 < temp2) ball = ball1;
		else ball = ball2; 
		next_pl = pl;
		// add collision detection
		if (rnum[0] | rnum[1]) begin
			if (pl.y + pl.height/2 < ball.y + ball.height/2) next_pl.y = pl.y + pl.vy;
			else next_pl.y = pl.y - pl.vy;
		end
		if (rnum[0]) begin
			if (pl.x + pl.width/2 < ball.x + ball.width/2) begin
				if (pl.x + pl.vx < SCREEN_WIDTH/2 - pl.width) next_pl.x = pl.x + pl.vx;
			end else begin
				if (pl.x - pl.vx < SCREEN_WIDTH) next_pl.x = pl.x - pl.vx;  // not overflow
			end
		end
	endtask
endpackage