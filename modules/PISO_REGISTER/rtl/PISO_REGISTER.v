module PISO_REGISTER #( parameter N = 8 ) (
    input wire clk, //clk
    input wire reset, //reset
    input wire load, //carrega data_in em reg
    input wire dir, // 0 = shift right, 1 = shift left
    input wire [N-1:0] data_in, //entrada paralela
    output reg data_out //saida paralela
);

reg [N-1:0] shift_reg; //registrador de deslocamento


always @(*) begin
    data_out = dir ? shift_reg[N-1] : shift_reg[0]; 
end

always @(posedge clk or posedge reset) begin
    if (reset) 
        shift_reg <= {N{1'b0}}; //zera o registrador
    else if (load)
        shift_reg <= data_in; //carrega o registrador com data_in
    else if (dir)
        shift_reg <= {shift_reg[N-2:0], 1'b0}; //shift left
    else
        shift_reg <= {1'b0, shift_reg[N-1:1]}; //shift right
end


endmodule
