// Junção de todos os modulos para formar o sistema completo de SPI Master

module spi_master_system #(
    parameter N_SLAVES = 4,
    parameter MAX_BITS = 16
)
(
    input wire clk,
    input wire reset,

    // Comandos
    input  wire cmd_valid,
    input  wire [39:0] cmd_data, 
    output wire cmd_ready,

    // Resposta 
    output wire rsp_valid,
    output wire [15:0] rsp_data, 
    input  wire rsp_ready,

    // SPI Físico
    output wire sclk,
    output wire mosi,
    input  wire miso,
    output wire [N_SLAVES-1:0] cs
);

    //Pica o barramento de comando para os sinais individuais
    wire [15:0] ext_data_in  = cmd_data[15:0];
    wire [7:0]  ext_n_bits   = cmd_data[23:16];
    wire [7:0]  ext_clk_div  = cmd_data[31:24];
    wire        ext_cpha     = cmd_data[32];
    wire        ext_cpol     = cmd_data[33];
    wire [1:0]  ext_slave_id = cmd_data[35:34];
    wire        ext_daisy    = cmd_data[36];
    wire        ext_hold_cs  = cmd_data[37];

 
    // Fios da FSM
    wire load_data_wire;
    wire start_transfer_wire;
    wire cs_enable_wire;
    wire transfer_done_wire;

    // Fios do Divisor de Clock
    wire sample_tick;
    wire shift_tick;
    wire trail_tick;
    wire lead_tick; 

    //Registradores de configuração estilo PIPO
    //Esses registradores protegem os valores de configuração e os mantêm estáveis durante a transferência, mesmo que o barramento de comando mude.
    // A FSM vai carregar esses registradores no início de cada transferência, garantindo que o Divisor de Clock e os outros módulos tenham dados consistentes
    // para trabalhar.

    // Fios para extrair as saídas do registrador
    wire reg_cpol;
    wire reg_cpha;
    wire [7:0] reg_clk_div;
    
    // Concatenando os sinais de configuração para entrar no registrador de uma só vez
    wire [9:0] config_data_in  = {ext_cpol, ext_cpha, ext_clk_div};
    wire [9:0] config_data_out;

    assign reg_cpol    = config_data_out[9];
    assign reg_cpha    = config_data_out[8];
    assign reg_clk_div = config_data_out[7:0];

    // Instanciação do Registrador de Configuração
    spi_config_register #(
        .N(10)
    ) config_reg_inst (
        .clk(clk),
        .reset(reset),
        .load(load_data_wire),      // O mesmo pulso da FSM que carrega os dados
        .data_in(config_data_in),   // O que vem de fora (clk_div, cpol, cpha)
        .data_out(config_data_out)  // O dado que vai para o Divisor de Clock
    );
    
    //FSM
    spi_fsm fsm_inst (
        .clk(clk),
        .rst_n(reset),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .hold_cs(ext_hold_cs),
        .rsp_ready(rsp_ready),
        .rsp_valid(rsp_valid),
        .transfer_done(transfer_done_wire),
        .load_data(load_data_wire),
        .cs_enable(cs_enable_wire),
        .start_transfer(start_transfer_wire)
    );

    // Divisor de Clock
    spi_clk_gen #(
        .DIV_WIDTH(8)
    ) clk_gen_inst (
        .clk(clk),
        .clear_n(reset),
        .enable(start_transfer_wire),
        .cpol(reg_cpol), //Pelo assign acima reg_cpol, reg_cpha e reg_clk_div vem diretamente do registrador de configuração            
        .cpha(reg_cpha),             
        .clk_div(reg_clk_div),       
        .sclk(sclk),                
        .lead_edge_pulse(lead_tick), 
        .trail_edge_pulse(trail_tick),
        .sample_edge(sample_tick),
        .shift_edge(shift_tick)
    );

    //registro de deslocamento
    spi_shift_register #(
        .WIDTH(MAX_BITS),
        .MSB_FIRST(1)
    ) shift_reg_inst (
        .clk(clk),
        .clear_n(reset),
        .load(load_data_wire),
        .shift_edge(shift_tick),
        .sample_edge(sample_tick),
        .serial_in(miso),            
        .parallel_in(ext_data_in),   
        .parallel_out(rsp_data),     
        .serial_out(mosi)            
    );

    // O Counter de bits
    spi_counter #(
        .CNT_WIDTH(5) 
    ) counter_inst (
        .clk(clk),
        .rst_n(reset),
        .load_data(load_data_wire),
        .trail_edge(trail_tick),
        .n_bits(ext_n_bits[4:0]),    
        .transfer_done(transfer_done_wire)
    );

    // O decodificador de Chip Select
    spi_cs_decoder #(
        .N_SLAVES(N_SLAVES)
    ) cs_decoder_inst (
        .cs_enable(cs_enable_wire),
        .daisy_mode(ext_daisy),
        .slave_id(ext_slave_id),
        .cs_out(cs)                  
    );

endmodule