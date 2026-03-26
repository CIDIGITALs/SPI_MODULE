module spi_master_system (
    parameter N_SLAVES = 4,
    parameter MAX_BITS = 16
)
(
    input clk,
    input reset,

    //comands
    input cmd_valid,
    input [39:0] cmd_data, //[31:30] slave_id, [29] cpol, [28] cpha, [27:20] clk_div, [19:15] n_bits, [14:0] data
    output cmd_ready,

    //resposta 

    output rsp_valid,
    output [15:0] rsp_data, // data received from slave
    input rsp_ready,

    // SPI fisico
    output sclk,
    output mosi,
    input miso,
    output [N_SLAVES-1:0] cs
);

