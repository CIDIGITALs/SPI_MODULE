module spi_fsm (

    input wire clk,// Sinal de clock
    input wire rst_n, // Sinal de reset ativo baixo
    
    // Comandos
    input wire cmd_valid, //sistema emite um sinal de que um comando está disponível
    output reg cmd_ready, //fsm emite dizendo que está pronta para receber um comando

    input wire rsp_ready, //sistema pronto para receber resposta
    output reg rsp_valid, //avisa que a resposta está pronta
    
    // Sinais de controle interno
    input wire transfer_done, //shift register informa que a transferência foi concluída
    output reg start_transfer, //avisa o shift register para iniciar a transferência
    output reg load_data, //avisa o shift register para carregar os dados a serem transferidos
    output reg cs_control, //controle do chip select (CS)
    output reg config_en //habilita a configuração de divisor de clock

);

reg [2:0] actual_state, next_state;

parameter [2:0]
    IDLE = 3'b000, 
    FETCH_CMD = 3'b001, 
    CONFIGURE = 3'b010,
    ASSERT_CS = 3'b011,
    TRANSFER = 3'b100,
    DEASSERT_CS = 3'b101,
    DONE = 3'b110; 

// logica de mudança de estado a cada ciclo de clock
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) // Se o reset estiver em nivel baixo, volta para o estado IDLE
        actual_state <= IDLE;
    else
        actual_state <= next_state; // Transição para o próximo estado mas depende do estado atual e das condições
end

// logica de transição de estados apenas define qual a próxima etapa do processo
// não tem relação direta com os sinais de saida
always @(*) begin

    //valores padrão para os sinais de controle
    next_state = actual_state; //por padrão, permanece no estado atual

    case (actual_state)
        IDLE : begin
            if (cmd_valid && cmd_ready) begin
                next_state = FETCH_CMD;
            end
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
            if(transfer_done) 
                next_state = DEASSERT_CS;
        end

        DEASSERT_CS : begin
            next_state = DONE;
        end

        DONE : begin
            if (rsp_ready) begin  
                next_state = IDLE;
            end
        end
        
        default : next_state = IDLE;    
    endcase
end

// logica de saida, define os sinais de controle para cada estado
always @(*) begin

    cmd_ready = 0;
    rsp_valid = 0;
    start_transfer = 0;
    load_data = 0;
    cs_control = 0;
    config_en = 0;

    case (actual_state)
        IDLE : begin
            cmd_ready = 1'b1; //fsm pronta para receber um cmd
        end
        FETCH_CMD : begin
            cmd_ready = 1'b0; //abaixa o sinal de cmd_ready para indicar que o comando foi recebido
        end
        CONFIGURE : begin
            load_data = 1'b1; //avisa o shift register para carregar os dados a serem transferidos
            config_en = 1'b1; //habilita a configuração de divisor de clock
        end
        ASSERT_CS : begin
            cs_control = 1'b1; //ativa o chip select (CS) acorda o escravo
        end
        TRANSFER : begin
            cs_control = 1'b1; //mantém o chip select ativo durante a transferência
            start_transfer = 1'b1; //avisa o shift register para iniciar a transferência
        end
        DEASSERT_CS : begin
            cs_control = 1'b0; //desativa o chip select (CS) após a transferência
        end
        DONE : begin
            rsp_valid = 1'b1; //avisa que a resposta está pronta
        end
    
    default: ;

    endcase
end 
endmodule
