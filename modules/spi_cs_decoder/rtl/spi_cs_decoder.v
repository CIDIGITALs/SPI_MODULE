module spi_cs_decoder #(
    parameter N_SLAVES = 4
)(
    // Controle interno
    input  wire                           cs_enable,  // Sinal da FSM (ativa em ASSERT_CS/TRANSFER)
    
    // Configuração (Vindas do barramento cmd_data)
    input  wire                           daisy_mode, // 0 = Multiponto, 1 = Daisy Chain
    input  wire [$clog2(N_SLAVES)-1:0]    slave_id,   // Identificador do escravo alvo
    
    // Saída Física
    output reg  [N_SLAVES-1:0]            cs_out      // Pinos de Chip Select (Ativos em BAIXO)
);

    // Bloco puramente combinatório (Roteamento instantâneo)
    always @(*) begin
        // 1. Valor padrão seguro: Todos os CS desativados (Nível ALTO)
        cs_out = {N_SLAVES{1'b1}};

        // 2. Só avalia qual CS baixar se a FSM autorizar
        if (cs_enable) begin
            
            if (daisy_mode) begin
                // --- MODO DAISY CHAIN ---
                // No modo Daisy Chain, deve haver um único sinal de chip select ativo.
                // Padronizamos o uso do pino cs_out[0] para habilitar toda a cascata.
                // Ignoramos o 'slave_id' recebido, pois todos os chips compartilham o mesmo fio CS.
                cs_out[0] = 1'b0;
            end 
            
            else begin
                // --- MODO MULTIPONTO ---
                // Não é permitido ativar mais de um escravo simultaneamente.
                // Decodificação One-Hot clássica baseada no slave_id.
                // Apenas o pino correspondente vai para 0.
                cs_out[slave_id] = 1'b0;
            end
            
        end
    end

endmodule