import object_package::*;

module stage (
	output object wall1, 
    output object wall2,
    output object wall3, 
    output object wall4, 
    output object wall5, 
    output object wall6, 
    output object mid_line
);   

	parameter [WIDTH-1:0] SCREEN_WIDTH = 640<<FBITS, SCREEN_HEIGHT = 480<<FBITS; // floating
	parameter [WIDTH-1:0] vwall_width = 10<<FBITS, vwall_height = 150<<FBITS, hwall_width = 660<<FBITS, hwall_height = 10<<FBITS; // floating
	parameter [WIDTH-1:0] mid_line_width = 2<<FBITS, mid_line_height = 480<<FBITS;

	always_comb begin
        // walls 1,2,3,4 are veritical, 5,6 are horizontal
        set(
            .x(0),
            .y(0),
            .width(vwall_width),
            .height(vwall_height),
            .o(wall1)
        );
        set(
            .x(0),
            .y(SCREEN_HEIGHT-vwall_height),
            .width(vwall_width),
            .height(vwall_height),
            .o(wall2)
        );
        set(
            .x(SCREEN_WIDTH-vwall_width),
            .y(0),
            .width(vwall_width),
            .height(vwall_height),
            .o(wall3)
        );
        set(
            .x(SCREEN_WIDTH-vwall_width),
            .y(SCREEN_HEIGHT-vwall_height),
            .width(vwall_width),
            .height(vwall_height),
            .o(wall4)
        );
        set(
            .x(vwall_width),
            .y(0),
            .width(hwall_width),
            .height(hwall_height),
            .o(wall5)
        );
        set(
            .x(vwall_width),
            .y(SCREEN_HEIGHT-hwall_height),
            .width(hwall_width),
            .height(hwall_height),
            .o(wall6)
        );
        set (
            .x(SCREEN_WIDTH/2-mid_line_width/2),
            .y(0),
            .width(mid_line_width),
            .height(mid_line_height),
            .o(mid_line)
        );
	end
endmodule
