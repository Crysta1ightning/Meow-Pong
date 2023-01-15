module random_number_generator #(parameter WIDTH = 8) (
  input logic clk,
  output logic [WIDTH-1:0] random_number
);
    reg [7:0] seed;

    always @(posedge clk) begin
        if (seed == 8'h00) begin
            seed <= 8'hA5;
        end else begin
            seed <= {seed[6:0],seed[7]^seed[6]};
        end
    end

    assign random_number = seed;

endmodule
