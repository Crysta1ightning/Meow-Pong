module clock_divider #(parameter WIDTH = 2) (clk1, clk);
    input clk;
    output clk1;
  
    reg [WIDTH-1:0] num;
    wire [WIDTH-1:0] next_num;

    always @(posedge clk) begin
      num <= next_num;
    end

    assign next_num = num + 1'b1;
    assign clk1 = num[WIDTH-1];

endmodule
