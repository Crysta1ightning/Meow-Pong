module final_top(
    input clk,
    input rst,
    input en,
    input absorb,
    input btnU,
    input btnD,
    input btnL,
    input btnR,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
);


    wire clk_25MHz, clk_slow; // clk_slow = clk/32
    wire valid;
    wire [9:0] h_cnt;  // 640
    wire [9:0] v_cnt;  // 480
    wire [1:0] s1;
    wire [1:0] s2;


    clock_divider clk_wiz_0_inst(
      .clk(clk),
      .clk1(clk_25MHz)
    );

    clock_divider #(.WIDTH(7)) clk_wiz_1_inst (
      .clk(clk),
      .clk1(clk_slow)
    );

    pixel_gen pixel_gen_inst(
      .clk(clk_slow),
      .rst(rst),
      .en(en),
      .absorb(absorb),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt),
      .btnU(btnU),
      .btnD(btnD),
      .btnL(btnL),
      .btnR(btnR),
      .valid(valid),
      .vgaRed(vgaRed),
      .vgaGreen(vgaGreen),
      .vgaBlue(vgaBlue)
    );

    vga_controller vga_inst(
      .pclk(clk_25MHz),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
      
endmodule
