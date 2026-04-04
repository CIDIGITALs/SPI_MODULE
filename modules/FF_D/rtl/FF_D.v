// Create a Flip-Flop D (FF_D) with synchronous Set and Reset inputs
module FF_D (
    input clk,
    input set, // Ativo em alto --> Seta 1 na saída Q
    input clear_n, // Ativo em baixo --> Reseta 0 na saída Q
    input d,
    output reg q,
    output wire nq
);

    always @(posedge clk) begin
        if (set) begin
            q <= 1'b1;
            nq <= 1'b0;
        end else if (!clear_n) begin
            q <= 1'b0;
        end else begin
            q <= d;
        end
    end
    assign nq = ~q;
endmodule
