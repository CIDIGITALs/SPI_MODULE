module spi_fsm (
    input wire clk,           // Relógio principal do sistema
    input wire rst_n,         // Reset síncrono ativo baixo
    
    // Interface com o Sistema Externo
    input wire cmd_valid,     // Sistema avisa que enviou um comando
    output reg cmd_ready,     // FSM avisa que está pronta
    input wire hold_cs,       // NOVO: Bit extraído do cmd_data[37] (1 = Daisy Chain/Cascata)
    input wire rsp_ready,     // Sistema avisa que pegou a resposta
    output reg rsp_valid,     // FSM avisa que a resposta está pronta
    
    // Interface com os Módulos Internos (Datapath)
    input wire transfer_done, // Vem do spi_counter (avisa que os bits acabaram)
    output reg load_data,     // Vai para o Shift Reg, Counter e Divisor (estado CONFIGURE)
    output reg config_en,     // Vai para o Divisor para resetar o relógio SPI
    output reg cs_enable,     // Vai para o spi_cs_decoder (1 = Acorda escravo)
    output reg start_transfer // Vai para o Divisor de Clock e Datapath (enable)
);

    reg [2:0] actual_state, next_state;

    parameter [2:0]
        IDLE        = 3'b000, // Repouso
        FETCH_CMD   = 3'b001, // Comando recebido
        CONFIGURE   = 3'b010, // Carrega os registradores e o contador
        ASSERT_CS   = 3'b011, // Ativa o Chip Select
        TRANSFER    = 3'b100, // Comunicação SPI rolando
        DEASSERT_CS = 3'b101, // Desativa o Chip Select
        DONE        = 3'b110; // Operação concluída

    // 1. LÓGICA SEQUENCIAL (Atualização de Estado com Reset Síncrono)
    always @(posedge clk) begin
        if (!rst_n) 
            actual_state <= IDLE;
        else 
            actual_state <= next_state;
    end

    // 2. LÓGICA COMBINATÓRIA (Definição do Próximo Estado)
    always @(*) begin
        next_state = actual_state; // Por padrão, mantém o estado
        
        case (actual_state)
            IDLE : begin
                if (cmd_valid && cmd_ready) 
                    next_state = FETCH_CMD;
            end
            
            FETCH_CMD : begin
                next_state = CONFIGURE;
            end
            
            CONFIGURE : begin
                next_state = ASSERT_CS;
            end
            
            ASSERT_CS : begin
                next_state = TRANSFER;
            end
            
            TRANSFER : begin
                if (transfer_done) begin
                    // Lógica Daisy Chain: Se hold_cs for 1, a comunicação de uma palavra acabou,
                    // mas queremos enviar outra logo em seguida sem subir o pino CS!
                    if (hold_cs)
                        next_state = DONE; 
                    else
                        next_state = DEASSERT_CS; // Transação normal, vai desligar o CS
                end
            end
            
            DEASSERT_CS : begin
                next_state = DONE;
            end
            
            DONE : begin
                if (rsp_ready) 
                    next_state = IDLE;
            end
            
            default : next_state = IDLE;
        endcase
    end

    // 3. LÓGICA DE SAÍDA (Sinais de Controle sem Latches)
    always @(*) begin
        
        // --- VALORES PADRÃO (Evita a criação de memória indesejada) ---
        cmd_ready      = 1'b0;
        rsp_valid      = 1'b0;
        load_data      = 1'b0;
        config_en      = 1'b0;
        start_transfer = 1'b0;
        
        // O cs_enable depende se estamos segurando o CS por causa do Daisy Chain.
        // Se hold_cs for 1, o CS deve continuar ativo mesmo no IDLE esperando a próxima palavra.
        cs_enable      = hold_cs; 

        // --- SOBRESCRITA ESPECÍFICA DE CADA ESTADO ---
        case (actual_state)
            
            IDLE : begin
                cmd_ready = 1'b1; 
            end
            
            FETCH_CMD : begin
                // Nada a sobrescrever (cmd_ready já desceu pra 0 no topo)
            end
            
            CONFIGURE : begin
                load_data = 1'b1; 
                config_en = 1'b1; 
            end
            
            ASSERT_CS : begin
                cs_enable = 1'b1; // Força a ativação do CS independente do hold_cs
            end
            
            TRANSFER : begin
                cs_enable      = 1'b1; // Mantém ativo
                start_transfer = 1'b1; // Habilita o pulso do clk_div
            end
            
            DEASSERT_CS : begin
                cs_enable = 1'b0; // Força a desativação do CS
            end
            
            DONE : begin
                rsp_valid = 1'b1; // Avisa o sistema que pode ler a resposta
            end
            
        endcase
    end 
endmodule