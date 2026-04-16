module spi_shift_register #(
    parameter WIDTH = 8,
    parameter MSB_FIRST = 1  //decide a ordem de transmissão: 1 = MSB primeiro, 0 = LSB primeiro
)(
    input wire clk,
    input wire clear_n,  // clear síncrono ativo em 0
    input wire load,     // carrega parallel_in no TX
    
    // Ticks de envio e amostragem feitas pelo clk_div
    input  wire shift_edge,   // Desloca o bit da SPI master para o escravo 
    input  wire sample_edge,  // Amostra o bit da SPI vindo do escravo para o master
    
    // Dados SPI
    input  wire serial_in, // MISO
    input  wire [WIDTH-1:0] parallel_in,  
    output reg  [WIDTH-1:0] parallel_out, // registrador para salvar a resposta do escravo
    output wire serial_out  // MOSI
);

    reg [WIDTH-1:0] tx_reg;

    always @(posedge clk) begin
        if (!clear_n) begin
            tx_reg       <= {WIDTH{1'b0}};
            parallel_out <= {WIDTH{1'b0}};
        end
        else if (load) begin
            parallel_out <= {WIDTH{1'b0}}; 
            tx_reg <= parallel_in; // carrega os dados a serem enviados em TX
        end
        else begin
            //RX
            if (sample_edge) begin
                if (MSB_FIRST)
                    // Coloca o bit que vem do miso no lsb
                    parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
                else
                    // Coloca o bit que vem do miso no msb
                    parallel_out <= {serial_in, parallel_out[WIDTH-1:1]};
            end

            //TX
            if (shift_edge) begin
                if (MSB_FIRST) 
                    //move a extremidade de TX_reg
                    // Coloca 0 no lsb e desloca o msb para a direita
                    tx_reg <= {tx_reg[WIDTH-2:0], 1'b0};
                else
                    // Coloca 0 no msb e desloca o lsb para a esquerda
                    tx_reg <= {1'b0, tx_reg[WIDTH-1:1]};
            end
        end
    end

    // O pino serial_out (MOSI) aponta sempre para a extremidade correta do tx_reg
    assign serial_out = (MSB_FIRST) ? tx_reg[WIDTH-1] : tx_reg[0];

endmodule