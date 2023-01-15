import object_package::*;

module gameover_score (
    input logic clk,
	input logic rst,
    input object ball1,
    input object ball2,
    output object score1, 
    output object score2,
    output object w1,
    output object w2,
	output logic [2:0] s1,
    output logic [2:0] s2,
    output logic gameover
);
    parameter [WIDTH-1:0] SCREEN_WIDTH = 640<<FBITS, SCREEN_HEIGHT = 480<<FBITS; // floating
    parameter [WIDTH-1:0] score_width = 64<<FBITS, score_height = 56<<FBITS;
	parameter [WIDTH-1:0] word_width = 128<<FBITS, word_height = 40<<FBITS;
    logic [2:0] next_s1, next_s2;
	logic [WIDTH-1:0] i, j, k, m;
    logic next_gameover;

    always_comb begin
		set (
			.x(SCREEN_WIDTH/4-score_width/2),
			.y(score_height),
			.width(score_width),
			.height(score_height),
			.o(score1)
		);
		set (
			.x(SCREEN_WIDTH/4*3-score_width/2),
			.y(score_height),
			.width(score_width),
			.height(score_height),
			.o(score2)
		);
		set (
			.x(SCREEN_WIDTH/4-word_width/2),
			.y(SCREEN_HEIGHT-word_height*2),
			.width(word_width),
			.height(word_height),
			.o(w1)
		);
		set (
			.x(SCREEN_WIDTH/4*3-word_width/2),
			.y(SCREEN_HEIGHT-word_height*2),
			.width(word_width),
			.height(word_height),
			.o(w2)
		);
	end
    
	// score update
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			s1 <= 0;
			s2 <= 0;
		end else begin
			s1 <= next_s1;
			s2 <= next_s2;
		end
	end
	always_comb begin
		if (rst) begin
			next_s1 = 0;
			next_s2 = 0;
		end else begin
			i = 0;
			j = 0;
			if (ball1.x > SCREEN_WIDTH*2) begin // overflow
				i = i+1;
			end else if (ball1.x > SCREEN_WIDTH) begin
				j = j+1;
			end 
			if (ball2.x > SCREEN_WIDTH*2) begin // overflow
				i = i+1;
			end else if (ball2.x > SCREEN_WIDTH) begin
				j = j+1;
			end
			
			next_s1 = s1 + j;
			if (next_s1 < s1) next_s1 = 3'd7; // overflow
			next_s2 = s2 + i;
			if (next_s2 < s2) next_s2 = 3'd7; // overflow
		end
	end

	// gameover update
	always_ff @(posedge clk, posedge rst) begin
		if (rst) begin
			gameover <= 1'b0;	
		end else begin
			gameover <= next_gameover;
		end
	end
	always_comb begin
		if (rst) begin
			next_gameover = 1'b0;
		end else begin
			if (gameover) next_gameover = 1'b1;
			else next_gameover = 1'b0;
			k = 0;
			m = 0;
			if (ball1.x > SCREEN_WIDTH*2) begin // overflow
				k = k+1;
			end else if (ball1.x > SCREEN_WIDTH) begin
				m = m+1;
			end 
			if (ball2.x > SCREEN_WIDTH*2) begin // overflow
				k = k+1;
			end else if (ball2.x > SCREEN_WIDTH) begin
				m = m+1;
			end 
			if ((s2 == 3'd6 && k > 0) || (s2 == 3'd5 && k > 1)) next_gameover = 1'b1;
			else if ((s1 == 3'd6 && m > 0) || (s1 == 3'd5 && m > 1)) next_gameover = 1'b1;
		end
	end
endmodule