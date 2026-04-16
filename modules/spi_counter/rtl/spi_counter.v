module spi_counter #(
    parameter CNT_WIDTH = 5 
)(
    input  wire                 clk,
    input  wire                 rst_n,
    
    // Controle
    input  wire                 load_data,  // FSM avisa (estado CONFIGURE)
    input  wire                 trail_edge, // trail_edge que vem do dividor de clock sempre avisa que uma transferencia e recebimento de um bit foi finalizada (estado TRANSFER)
    input  wire [CNT_WIDTH-1:0] n_bits,     // Quantidade de bits (vem do cmd_data)
    
    // Saída
    output reg                  transfer_done // Avisa a FSM que a transferência de todos os bits foi concluída (estado TRANSFER)
);

    reg [CNT_WIDTH-1:0] bit_count; //registrador de contagem de bits

    always @(posedge clk) begin //reset síncrono
        if (!rst_n) begin
            bit_count     <= {CNT_WIDTH{1'b0}};
            transfer_done <= 1'b0;
        end 
        else begin
            // Fsm manda carregar os bits
            if (load_data) begin
                bit_count     <= n_bits;
                transfer_done <= 1'b0; // Força a flag para estado baixo
            end 
            
            // O Divisor de Clock avisa que um bit terminou de trafegar
            else if (trail_edge) begin
                
                // Se bit count for maior que 0, significa que ainda temos bits para transferir
                if (bit_count > 0) begin
                    
                    // Se este for exatamente o ÚLTIMO bit sendo finalizado, 
                    // FSM avançar no próximo ciclo de clk, o ultimo bit pois a contagem é de n_bits para 0, ou seja, quando bit_count for 1, o próximo bit a ser transferido é o último
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