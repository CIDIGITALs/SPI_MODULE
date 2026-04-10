module spi_fsm (
    input wire clk,           // Relógio principal do sistema (50MHz)
    input wire rst_n,         // Reset síncrono ativo baixo
    
    // Interface com o Sistema Externo
    input wire cmd_valid,     // Sistema avisa que enviou um comando
    output reg cmd_ready,     // FSM avisa que está pronta
    input wire hold_cs,       // Vem do cmd_data[37] (1 = Daisy Chain, mantém CS baixo)
    input wire rsp_ready,     // Sistema avisa que pegou a resposta
    output reg rsp_valid,     // FSM avisa que a resposta está pronta
    
    // Interface com os Módulos Internos
    input wire transfer_done, // Vem do spi_counter (avisa que os bits acabaram)
    output reg load_data,     // Sinal Mestre: Carrega Datapath, Contador e Regs do Top-Level
    output reg cs_enable,     // Vai para o spi_cs_decoder (1 = Autoriza rotear o CS)
    output reg start_transfer // Vai para o spi_clk_gen (liga o motor gerador de ticks)
);

    reg [2:0] actual_state, next_state;

    parameter [2:0]
        IDLE        = 3'b000, 
        FETCH_CMD   = 3'b001, 
        CONFIGURE   = 3'b010, 
        ASSERT_CS   = 3'b011, 
        TRANSFER    = 3'b100, 
        DEASSERT_CS = 3'b101, 
        DONE        = 3'b110; 

    // Lógica Sequencial (Reset Síncrono)
    always @(posedge clk) begin
        if (!rst_n) actual_state <= IDLE;
        else        actual_state <= next_state;
    end

    // Lógica Combinatória (Próximo Estado)
    always @(*) begin
        next_state = actual_state; 
        
        case (actual_state)
            IDLE :        if (cmd_valid && cmd_ready) next_state = FETCH_CMD;
            FETCH_CMD :   next_state = CONFIGURE;
            CONFIGURE :   next_state = ASSERT_CS;
            ASSERT_CS :   next_state = TRANSFER;
            TRANSFER : begin
                if (transfer_done) begin
                    if (hold_cs) next_state = DONE; 
                    else         next_state = DEASSERT_CS; 
                end
            end
            DEASSERT_CS : next_state = DONE;
            DONE :        if (rsp_ready) next_state = IDLE;
            default :     next_state = IDLE;
        endcase
    end

    // Lógica de Saída (Sinais de Controle)
    always @(*) begin
        // Valores Padrão
        cmd_ready      = 1'b0;
        rsp_valid      = 1'b0;
        load_data      = 1'b0;
        start_transfer = 1'b0;
        cs_enable      = hold_cs; // Se for Daisy Chain, mantém a porta aberta no IDLE
        
        case (actual_state)
            IDLE :        cmd_ready = 1'b1; 
            FETCH_CMD :   ; // Mantém padrões
            CONFIGURE :   load_data = 1'b1; 
            ASSERT_CS :   cs_enable = 1'b1; 
            TRANSFER : begin
                cs_enable      = 1'b1; 
                start_transfer = 1'b1; 
            end
            DEASSERT_CS : cs_enable = 1'b0; 
            DONE :        rsp_valid = 1'b1; 
        endcase
    end 
endmodule