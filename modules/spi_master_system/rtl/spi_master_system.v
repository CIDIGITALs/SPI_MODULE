module spi_master_system #(
    parameter N_SLAVES = 4,
    parameter MAX_BITS = 16
)
(
    input clk,
    input reset,

    // Comandos
    input cmd_valid,
    input [39:0] cmd_data, // Exp: [31:30] slave_id, [29] cpol, [28] cpha, [27:20] clk_div, [19:15] n_bits, [14:0] data
    output cmd_ready,

    // Resposta 
    output rsp_valid,
    output [15:0] rsp_data, // Dado recebido do escravo
    input rsp_ready,

    // SPI Físico
    output sclk,
    output mosi,
    input miso,
    output [N_SLAVES-1:0] cs
);

    // A lógica interna 

endmodule