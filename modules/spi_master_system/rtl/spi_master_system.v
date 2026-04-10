module spi_master_system #(
    parameter N_SLAVES = 4,
    parameter MAX_BITS = 16
)
(
    input wire clk,
    input wire reset, // Assumindo que este é o reset ativo baixo (rst_n) do seu sistema

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

    // =========================================================================
    // 1. FATIAMENTO DO BARRAMENTO (Extraindo a configuração do cmd_data)
    // =========================================================================
    wire [15:0] ext_data_in  = cmd_data[15:0];
    wire [7:0]  ext_n_bits   = cmd_data[23:16];
    wire [7:0]  ext_clk_div  = cmd_data[31:24];
    wire        ext_cpha     = cmd_data[32];
    wire        ext_cpol     = cmd_data[33];
    wire [1:0]  ext_slave_id = cmd_data[35:34]; // Assumindo N_SLAVES = 4
    wire        ext_daisy    = cmd_data[36];
    wire        ext_hold_cs  = cmd_data[37];

    // =========================================================================
    // 2. FIOS DE INTERCONEXÃO (Roteamento entre os módulos)
    // =========================================================================
    // Fios da FSM
    wire load_data_wire;
    wire start_transfer_wire;
    wire cs_enable_wire;
    wire transfer_done_wire;

    // Fios do Divisor de Clock
    wire sample_tick;
    wire shift_tick;
    wire trail_tick;
    wire lead_tick; // Gerado pelo módulo, mas não usado diretamente pelos registradores

    // =========================================================================
    // 3. REGISTRADORES DE CONFIGURAÇÃO (Salvos no momento do load_data)
    // =========================================================================
    reg reg_cpol;
    reg reg_cpha;
    reg [7:0] reg_clk_div;

    always @(posedge clk) begin
        if (!reset) begin
            reg_cpol    <= 1'b0;
            reg_cpha    <= 1'b0;
            reg_clk_div <= 8'd0;
        end
        else if (load_data_wire) begin
            // Copia as configurações do barramento para uso contínuo do Divisor
            reg_cpol    <= ext_cpol;
            reg_cpha    <= ext_cpha;
            reg_clk_div <= ext_clk_div;
        end
    end

    // =========================================================================
    // 4. INSTANCIAÇÃO DOS SUBMÓDULOS
    // =========================================================================

    // O Cérebro
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

    // O Maestro do Tempo
    spi_clk_gen #(
        .DIV_WIDTH(8)
    ) clk_gen_inst (
        .clk(clk),
        .clear_n(reset),
        .enable(start_transfer_wire),
        .cpol(reg_cpol),             // Usa o valor salvo no registrador
        .cpha(reg_cpha),             // Usa o valor salvo no registrador
        .clk_div(reg_clk_div),       // Usa o valor salvo no registrador
        .sclk(sclk),                 // Pino físico
        .lead_edge_pulse(lead_tick), 
        .trail_edge_pulse(trail_tick),
        .sample_edge(sample_tick),
        .shift_edge(shift_tick)
    );

    // Os Músculos (Datapath)
    spi_shift_register #(
        .WIDTH(MAX_BITS),
        .MSB_FIRST(1)
    ) shift_reg_inst (
        .clk(clk),
        .clear_n(reset),
        .load(load_data_wire),
        .shift_edge(shift_tick),
        .sample_edge(sample_tick),
        .serial_in(miso),            // Pino físico
        .parallel_in(ext_data_in),   // Vem direto do barramento
        .parallel_out(rsp_data),     // Vai para a saída do sistema
        .serial_out(mosi)            // Pino físico
    );

    // O Cronômetro
    spi_counter #(
        .CNT_WIDTH(5) // Para 16 bits (conta até 31)
    ) counter_inst (
        .clk(clk),
        .rst_n(reset),
        .load_data(load_data_wire),
        .trail_edge(trail_tick),
        .n_bits(ext_n_bits[4:0]),    // Pegamos só os 5 bits necessários
        .transfer_done(transfer_done_wire)
    );

    // A Chave Seletora
    spi_cs_decoder #(
        .N_SLAVES(N_SLAVES)
    ) cs_decoder_inst (
        .cs_enable(cs_enable_wire),
        .daisy_mode(ext_daisy),
        .slave_id(ext_slave_id),
        .cs_out(cs)                  // Pinos físicos
    );

endmodule