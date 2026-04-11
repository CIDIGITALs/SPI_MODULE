// Registrador de deslocamento adaptado para SPI (TX e RX separados)
module spi_shift_register #(
    parameter WIDTH = 8,
    parameter MSB_FIRST = 1  // 1 = transmite MSB primeiro, 0 = LSB primeiro
)(
    input  wire             clk,
    input  wire             clear_n,      // clear síncrono ativo em 0
    input  wire             load,         // carrega parallel_in no TX
    
    // Ticks de Controle (vindos do spi_clk_gen)
    input  wire             shift_edge,   // autoriza deslocar bit para o MOSI
    input  wire             sample_edge,  // autoriza amostrar bit do MISO
    
    // Dados SPI
    input  wire             serial_in,    // bit que entra (MISO)
    input  wire [WIDTH-1:0] parallel_in,  // carga paralela para enviar
    output reg  [WIDTH-1:0] parallel_out, // conteúdo recebido (RX)
    output wire             serial_out    // bit que sai (MOSI)
);

    // Registrador interno exclusivo para transmissão
    reg [WIDTH-1:0] tx_reg;

    always @(posedge clk) begin
        if (!clear_n) begin
            tx_reg       <= {WIDTH{1'b0}};
            parallel_out <= {WIDTH{1'b0}};
        end
        else if (load) begin
            parallel_out <= {WIDTH{1'b0}}; // Limpa a saída paralela para receber nova transmissão
            tx_reg <= parallel_in; // Prepara o dado a ser enviado
        end
        else begin
            // --- Lógica de Recepção (RX) ---
            // Acionada exclusivamente pelo sample_edge
            if (sample_edge) begin
                if (MSB_FIRST)
                    // Entra serial_in no LSB
                    parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
                else
                    // Entra serial_in no MSB
                    parallel_out <= {serial_in, parallel_out[WIDTH-1:1]};
            end

            // --- Lógica de Transmissão (TX) ---
            // Acionada exclusivamente pelo shift_edge
            if (shift_edge) begin
                if (MSB_FIRST)
                    tx_reg <= {tx_reg[WIDTH-2:0], 1'b0};
                else
                    tx_reg <= {1'b0, tx_reg[WIDTH-1:1]};
            end
        end
    end

    // O pino serial_out (MOSI) aponta sempre para a extremidade correta do tx_reg
    assign serial_out = (MSB_FIRST) ? tx_reg[WIDTH-1] : tx_reg[0];

endmodule