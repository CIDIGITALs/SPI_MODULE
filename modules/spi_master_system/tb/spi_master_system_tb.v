`timescale 1ns/1ps

module tb_spi_master_system;

    reg clk; //clk
    reg reset; //reset
    
    reg cmd_valid; // Sinal que avisa que esta pronto para receber um comando
    reg [39:0] cmd_data;
    wire cmd_ready; // FSM avis que o modulo está pronto para receber o comando
    
    wire rsp_valid; // Host informa a chegada de um novo comando
    wire [15:0] rsp_data; // Dado de resposta
    reg rsp_ready; // Modulo avisa que pegou a resposta


    wire sclk; //clk do spi para os escravos
    wire mosi; // Master Out Slave In
    wire miso; // Master In Slave Out
    wire [3:0] cs; // Chip Select para 4 escravos

    spi_master_system #(
        .N_SLAVES(4),
        .MAX_BITS(16)
    ) dut (
        .clk(clk),
        .reset(reset),
        .cmd_valid(cmd_valid),
        .cmd_data(cmd_data),
        .cmd_ready(cmd_ready),
        .rsp_valid(rsp_valid),
        .rsp_data(rsp_data),
        .rsp_ready(rsp_ready),
        .sclk(sclk),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    //clk
    initial clk = 0;
    always #10 clk = ~clk;

    // Criacao de 4 escravos ficticios para testar o sistema
    reg [15:0] slave0_reg = 16'hAAAA;
    reg [15:0] slave1_reg = 16'hBBBB; 
    reg [15:0] slave2_reg = 16'hCCCC;
    reg [15:0] slave3_reg = 16'hDDDD;

    //fios dos escravos
    wire miso_s0, miso_s1, miso_s2, miso_s3;
    wire mosi_s0, mosi_s1, mosi_s2, mosi_s3;

    // Sinal que muda se o estado é multiponto normal ou daisy chain
    reg daisy_mode = 0;

    // Roteamento MOSI
    assign mosi_s0 = mosi;
    // cascateia se for modo daisy, senão vai direto do mestre para os escravos
    assign mosi_s1 = (daisy_mode) ? miso_s0 : mosi;
    assign mosi_s2 = (daisy_mode) ? miso_s1 : mosi;
    assign mosi_s3 = (daisy_mode) ? miso_s2 : mosi;

    // Roteamento MISO
    // No Daisy Chain com 4 escravos, o dado que volta pro mestre sai do ultimo (S3)
    // Aqui ocorre a conexão física, onde o MISO do mestre é conectado ao MISO do escravo selecionado, ou ao último escravo no caso de daisy chain
    assign miso = (daisy_mode) ? miso_s3 : (
                    (!cs[0]) ? miso_s0 :
                    (!cs[1]) ? miso_s1 :
                    (!cs[2]) ? miso_s2 :
                    (!cs[3]) ? miso_s3 : 1'b1
                  );

    // MSB apontando para fora
    // funciona como um tristate, quando o CS do escravo está alto, o MISO fica em estado alto igual a 1
    // se for daisy chain cs[0] estara baixo e daisymode sera 1, entao todos os escravos vao responder, mas o mestre so vai ler de s3, pelo formato cascata
    assign miso_s0 = (!cs[0]) ? slave0_reg[15] : 1'b1;
    assign miso_s1 = (!cs[1] || (daisy_mode && !cs[0])) ? slave1_reg[15] : 1'b1;
    assign miso_s2 = (!cs[2] || (daisy_mode && !cs[0])) ? slave2_reg[15] : 1'b1;
    assign miso_s3 = (!cs[3] || (daisy_mode && !cs[0])) ? slave3_reg[15] : 1'b1;


    reg mosi_capturado_s0;
    reg mosi_capturado_s1;
    reg mosi_capturado_s2;
    reg mosi_capturado_s3;

    // Amostragem, cs baixo indica que o escravo foi selecionado
    //salva nos registradores intermediarios o dado de cada escravo
    always @(posedge sclk) begin
        if (!cs[0]) 
            mosi_capturado_s0 <= mosi_s0;
        if (!cs[1] || (daisy_mode && !cs[0])) 
            mosi_capturado_s1 <= mosi_s1;
        if (!cs[2] || (daisy_mode && !cs[0]))
            mosi_capturado_s2 <= mosi_s2;
        if (!cs[3] || (daisy_mode && !cs[0]))
            mosi_capturado_s3 <= mosi_s3;
    end
 
    // Escrita coloca o dado no final do registrador, e o dado vai "andando" a cada pulso de clock
    always @(negedge sclk) begin
        if (!cs[0]) 
            slave0_reg <= {slave0_reg[14:0], mosi_capturado_s0};
        if (!cs[1] || (daisy_mode && !cs[0])) 
            slave1_reg <= {slave1_reg[14:0], mosi_capturado_s1};
        if (!cs[2] || (daisy_mode && !cs[0])) 
            slave2_reg <= {slave2_reg[14:0], mosi_capturado_s2};
        if (!cs[3] || (daisy_mode && !cs[0])) 
            slave3_reg <= {slave3_reg[14:0], mosi_capturado_s3};
    end


    // Uma task em verilog serve para encapsular um bloco de código que será reutilizado várias vezes.
    // funciona como uma função. 
    task send_spi_cmd;
        input [15:0] data;
        input [1:0]  target_slave;
        input        is_daisy;
        input        keep_cs_low;
        input        cpol;
        input        cpha;
        input [15:0] expected_rsp;
        begin
            @(posedge clk);
            cmd_data = {2'b00, keep_cs_low, is_daisy, target_slave, cpol, cpha, 8'd4, 8'd16, data};
            cmd_valid = 1;

            wait(cmd_ready == 1);
            @(posedge clk);
            cmd_valid = 0;

            wait(rsp_valid == 1);
            @(posedge clk);
            
            // Correção da checagem: Se for 16'hx (desconhecido), apenas imprime [INFO]
            if (expected_rsp === 16'hx) 
                $display("   [INFO] Resposta ignorada. Valor circulado recebido: %h", rsp_data);
            else if (rsp_data === expected_rsp) 
                $display("   [PASS] Resposta correta do Escravo. Recebido: %h", rsp_data);
            else 
                $display("   [FAIL] Erro! Esperado: %h | Recebido: %h", expected_rsp, rsp_data);

            rsp_ready = 1;
            @(posedge clk);
            rsp_ready = 0;
            @(posedge clk);
        end
    endtask


    initial begin
        $dumpfile("spi_master.vcd");
        $dumpvars(0, tb_spi_master_system);
        
        reset = 0;
        cmd_valid = 0;
        cmd_data = 40'd0;
        rsp_ready = 0;
        
        #50;
        reset = 1;
        #50;

        $display("--------------------------------------------------");
        $display("[TESTE 1] Transacao MULTIPONTO - Escravo 1");
        daisy_mode = 0;
        // (data, slave_id, is_daisy, keep_cs_low, cpol, cpha, expected)
        send_spi_cmd(16'h1234, 2'd1, 1'b0, 1'b0, 1'b0, 1'b0, 16'hBBBB);
        
        $display("\n[TESTE 2] Troca rapida de Escravo - Escravo 2");
        send_spi_cmd(16'h4321, 2'd2, 1'b0, 1'b0, 1'b0, 1'b0, 16'hCCCC);

        $display("--------------------------------------------------");
        $display("[TESTE 3] Variacao de CPOL e CPHA");
        $display("Enviando comando com CPOL=1 e CPHA=1 para o Escravo 3...");

        send_spi_cmd(16'hF0F0, 2'd3, 1'b0, 1'b0, 1'b1, 1'b1, 16'hx);

        $display("--------------------------------------------------");
        $display("[TESTE 4] Caso de Borda - Comando Invasor (Stress Test)");
        $display("Enviando comando longo, e simulando host ansioso...");
        
        @(posedge clk);
        cmd_data = {2'b00, 1'b0, 1'b0, 2'd0, 1'b0, 1'b0, 8'd8, 8'd16, 16'h1111};
        cmd_valid = 1;
        wait(cmd_ready == 1);
        @(posedge clk);
        cmd_valid = 0;

        #200; 
        
        // Host tenta mudar o CPOL e o Dado e dispara cmd_valid = 1!
        $display("   -> Injetando ruido no barramento e forcando cmd_valid = 1...");
        cmd_data = {2'b00, 1'b0, 1'b0, 2'd0, 1'b1, 1'b0, 8'd4, 8'd16, 16'h9999};
        cmd_valid = 1; 
        
        #40; // Host segura por 2 ciclos de relogio apenas
        cmd_valid = 0; // Host desiste do ataque ANTES da transacao atual
        
        // Espera a FSM terminar a transacao
        wait(rsp_valid == 1);
        @(posedge clk);
        
        if (rsp_data === 16'hAAAA) 
            $display("   [PASS] A FSM blindou a transacao e terminou com sucesso! Recebido: %h", rsp_data);
        else 
            $display("   [FAIL] A FSM quebrou com a invasao. Recebido: %h", rsp_data);
            
        rsp_ready = 1;
        @(posedge clk);
        rsp_ready = 0;


        $display("--------------------------------------------------");
        $display("[TESTE 5] Iniciando Transacao DAISY CHAIN (4 Escravos)");
        $display("Topologia alterada. Mestre -> S0 -> S1 -> S2 -> S3 -> Mestre");
        daisy_mode = 1;

    
        send_spi_cmd(16'h1111, 2'd0, 1'b1, 1'b1, 1'b0, 1'b0, 16'hx); // hold_cs = 1
        send_spi_cmd(16'h2222, 2'd0, 1'b1, 1'b1, 1'b0, 1'b0, 16'hx); // hold_cs = 1
        send_spi_cmd(16'h3333, 2'd0, 1'b1, 1'b1, 1'b0, 1'b0, 16'hx); // hold_cs = 1
        send_spi_cmd(16'h4444, 2'd0, 1'b1, 1'b0, 1'b0, 1'b0, 16'hx); // hold_cs = 0 
        
        $display("\nVerificando registros finais do Daisy Chain:");
        $display("Slave 0 contem: %h (Esperado: 4444)", slave0_reg);
        $display("Slave 1 contem: %h (Esperado: 3333)", slave1_reg);
        $display("Slave 2 contem: %h (Esperado: 2222)", slave2_reg);
        $display("Slave 3 contem: %h (Esperado: 1111)", slave3_reg);
        $display("--------------------------------------------------");

        #200;
        $finish;
    end

endmodule