module spi_cs_decoder #(
    parameter N_SLAVES = 4
)(
    input wire cs_enable,  //sinal de enable
    input wire daisy_mode, // 0 = Multiponto, 1 = Daisy Chain
    input wire [$clog2(N_SLAVES)-1:0] slave_id,   // ID do escravo
    
    output reg  [N_SLAVES-1:0]  cs_out //pino respectivo ao escravo 
);

    always @(*) begin
        //inicial com todos os CS em estado 1
        cs_out = {N_SLAVES{1'b1}};

        if (cs_enable) begin
            
            if (daisy_mode) begin
                // No modo daisy chain todos os escravos sao ligados ao mesmo CS
                cs_out[0] = 1'b0; // --> Ativo em baixo
            end 
            
            else begin
                // No modo multiponto, apenas o escravo selecionado tem seu CS ativado (0)
                cs_out[slave_id] = 1'b0; //--> Ativo em baixo
            end
            
        end
    end

endmodule