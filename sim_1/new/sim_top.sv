`timescale 1ns / 1ps

module sim_top();
    reg clk, rst;
    reg [3:0] vgaRed, vgaGreen, vgaBlue;
    final_top ft (.clk(clk), .rst(rst), .vgaRed(vgaRed), .vgaGreen(vgaGreen), .vgaBlue(vgaBlue), .hsync(hsync), .vsync(vsync));
    initial begin
        #10
        rst = 1'b1;

        #10
        rst = 1'b0;

        while (rst == 1'b0) begin
            #10;
        end
    end
    always #5 clk = ~clk;
endmodule
