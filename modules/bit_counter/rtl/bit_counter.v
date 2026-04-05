// Contador para contar o número de bits processados e indicar o fim da transmissão.
module bit_counter #(
    parameter WIDTH = 6
)(
    input  wire             clk,
    input  wire             clear_n,
    input  wire             load,
    input  wire             count_en,
    input  wire [WIDTH-1:0] n_bits,
    output reg  [WIDTH-1:0] count,
    output wire             done
);

always @(posedge clk) begin
    if (!clear_n)
        count <= 0;
    else if (load)
        count <= 0;
    else if (count_en)
        count <= count + 1'b1;
end

assign done = (count == (n_bits - 1'b1)) && count_en;

endmodule