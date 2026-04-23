module spi_fsm (
    input wire clk,           // clk do sistema 
    input wire rst_n,         // reset sincrono ativo baixo
    
    // Sinais de controle externos ao modulo
    input wire cmd_valid,     // Host informa a chegada de um novo comando
    output reg cmd_ready,     // FSM avis que o modulo está pronto para receber o comando
    input wire hold_cs,       // Sinal do host que indica se o CS deve permanecer ativo após a transferência (Daisy Chain)
    input wire rsp_ready,     // Sistema avisa que pegou a resposta
    output reg rsp_valid,     // FSM avisa que a resposta está pronta
    
    // Sinais internos ao modulo
    input wire transfer_done, // Sinal do Contador de Bits que indica o fim da transferência
    output reg load_data,     // Vai para o registrador de configuração, contador, e shift register
    output reg cs_enable,     // Vai para o spi_cs_decoder, sendo esse o sinal de enable do decodificador
    output reg start_transfer // Liga o gerador de clock começar a gerar os pulos de shift(envio de dados) e sample(leitura de dados) e sclk (clock dos escravos)
);

    reg [2:0] actual_state, next_state; // registros para o estado atual e próximo estado da FSM

    parameter [2:0] //alias para os estados da FSM
        IDLE        = 3'b000, 
        FETCH_CMD   = 3'b001, 
        CONFIGURE   = 3'b010, 
        ASSERT_CS   = 3'b011, // Habilita o decodificador de CS para comunicar com o respectivo escravo.
        TRANSFER    = 3'b100, 
        DEASSERT_CS = 3'b101, // Desabilita o decoficador de CS, termina a comunicação com os escravos.
        DONE        = 3'b110; // Ativa rsp_valid

    // Lógica do reset sincrono e transicao de estados
    always @(posedge clk) begin
        if (!rst_n) actual_state <= IDLE;
        else        actual_state <= next_state;
    end

    // Logica de atualização do próximo estado da FSM
    always @(*) begin
        next_state = actual_state; 
        
        case (actual_state)
            IDLE :        if (cmd_valid && cmd_ready) next_state = FETCH_CMD;
            FETCH_CMD :   next_state = CONFIGURE;
            CONFIGURE :   next_state = ASSERT_CS;
            ASSERT_CS :   next_state = TRANSFER;
            TRANSFER : begin
                if (transfer_done) begin
                    if (hold_cs) next_state = DONE; // Se hold_cs for 1, vai direto para DONE, mantendo o CS ativo no modo daisy chain.
                    else         next_state = DEASSERT_CS; 
                end
            end
            DEASSERT_CS : next_state = DONE;
            DONE :        if (rsp_ready) next_state = IDLE;
            default :     next_state = IDLE;
        endcase
    end

    // Lógica de Saída dos sinais relativo a cada estado da FSM
    always @(*) begin

        cmd_ready      = 1'b0;
        rsp_valid      = 1'b0;
        load_data      = 1'b0;
        start_transfer = 1'b0;
        cs_enable      = hold_cs; 
        
        case (actual_state)
            IDLE :        cmd_ready = 1'b1; 
            FETCH_CMD :   ; // Mantém padrões
            CONFIGURE :   load_data = 1'b1; // Carrega os dados de configuração no registrador, contador e shift register
            ASSERT_CS :   cs_enable = 1'b1; //Levanta o CS para iniciar a comunicação com os escravos
            TRANSFER : begin
                cs_enable      = 1'b1; // Garante que o CS permaneça ativo durante toda a transferência
                start_transfer = 1'b1; // Liga o gerador de clock para iniciar a transferência
            end
            DEASSERT_CS : cs_enable = 1'b0; //libera o CS
            DONE :        rsp_valid = 1'b1; //avisa que a resposta está pronta para ser lida
        endcase
    end 
endmodule