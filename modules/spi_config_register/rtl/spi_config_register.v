module spi_config_register #( parameter N = 8 ) (
    input wire clk, //clk
    input wire reset, //reset
    input wire load, //carrega data_in em reg
    input wire [N-1:0] data_in, //entrada paralela
    output reg [N-1:0] data_out //saida paralela
);

always @(posedge clk) begin
    if (!reset) data_out <= 0; // Limpa o registrador no reset
    else if (load)
        data_out <= data_in; // Carrega o valor de data_in em data_out
end



endmodule