module spi_counter #(
    // Se o MAX_BITS do seu projeto é 16, 5 bits são suficientes (conta até 31)
    parameter CNT_WIDTH = 5 
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // Controle
    input  wire                 load_data,  // FSM avisa (estado CONFIGURE)
    input  wire                 trail_edge, // Divisor avisa que o ciclo do bit acabou
    input  wire [CNT_WIDTH-1:0] n_bits,     // Quantidade de bits (vem do cmd_data)
    
    // Saída
    output reg                  transfer_done // Flag para a FSM (estado TRANSFER)
);

    reg [CNT_WIDTH-1:0] bit_count;

    always @(posedge clk) begin
        if (!rst_n) begin
            bit_count     <= {CNT_WIDTH{1'b0}};
            transfer_done <= 1'b0;
        end 
        else begin
            // 1. A FSM manda carregar o número de bits
            if (load_data) begin
                bit_count     <= n_bits;
                transfer_done <= 1'b0; // Abaixa a flag de concluído
            end 
            
            // 2. O Divisor de Clock avisa que um bit terminou de trafegar
            else if (trail_edge) begin
                
                // Se ainda temos bits para contar...
                if (bit_count > 0) begin
                    
                    // Se este for exatamente o ÚLTIMO bit sendo finalizado, 
                    // levantamos a flag para a FSM avançar no próximo ciclo de clk
                    if (bit_count == 1) begin
                        transfer_done <= 1'b1; 
                    end
                    
                    // Decrementa o contador
                    bit_count <= bit_count - 1'b1;
                end
            end
        end
    end

endmodule