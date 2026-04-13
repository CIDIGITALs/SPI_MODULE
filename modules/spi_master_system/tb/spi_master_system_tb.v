`timescale 1ns/1ps

module tb_spi_master_system;

    // Sinais do Sistema Principal
    reg clk;
    reg reset;
    
    // Sinais de Interface do Sistema
    reg cmd_valid;
    reg [39:0] cmd_data;
    wire cmd_ready;
    wire rsp_valid;
    wire [15:0] rsp_data;
    reg rsp_ready;

    // Sinais Físicos SPI
    wire sclk;
    wire mosi;
    wire miso;
    wire [3:0] cs;

    // =========================================================================
    // 1. INSTANCIAÇÃO DO SEU MÓDULO (O "Device Under Test")
    // =========================================================================
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

    // =========================================================================
    // 2. GERAÇÃO DE CLOCK (50 MHz)
    // =========================================================================
    initial clk = 0;
    always #10 clk = ~clk; // Período de 20ns

// =========================================================================
    // 3. CRIAÇÃO DOS "ESCRAVOS FALSOS" (Mock Slaves - À prova de Race Condition)
    // =========================================================================
    reg [15:0] slave0_reg = 16'hAAAA; 
    reg [15:0] slave1_reg = 16'hBBBB; 
    
    // Fios físicos dos escravos
    wire miso_s0, miso_s1;
    wire mosi_s0, mosi_s1;
    
    // Sinal de controle para a "Placa de Circuito" mudar o roteamento
    reg topologia_daisy = 0; 

    // Roteamento MOSI
    assign mosi_s0 = mosi;
    assign mosi_s1 = (topologia_daisy) ? miso_s0 : mosi;

    // Roteamento MISO
    assign miso = (topologia_daisy) ? miso_s1 : (
                    (!cs[0]) ? miso_s0 :
                    (!cs[1]) ? miso_s1 : 1'b1
                  );

    // O bit de saída (MISO) aponta sempre para o MSB atual do registrador
    assign miso_s0 = (!cs[0]) ? slave0_reg[15] : 1'b1;
    assign miso_s1 = (!cs[1] || (topologia_daisy && !cs[0])) ? slave1_reg[15] : 1'b1;

    // --- A MÁGICA DA CORREÇÃO: Separar Amostragem e Deslocamento ---
    
    // Registradores temporários para segurar a leitura do fio
    reg mosi_capturado_s0;
    reg mosi_capturado_s1;

    // 1. AMOSTRAGEM (Leitura segura): 
    // Ocorre na borda de SUBIDA, longe do momento em que o mestre altera os fios.
    always @(posedge sclk) begin
        if (!cs[0]) 
            mosi_capturado_s0 <= mosi_s0;
            
        if (!cs[1] || (topologia_daisy && !cs[0])) 
            mosi_capturado_s1 <= mosi_s1;
    end

    // 2. DESLOCAMENTO (Escrita): 
    // Ocorre na borda de DESCIDA, empurrando para dentro o bit que foi lido com segurança.
    always @(negedge sclk) begin
        if (!cs[0]) 
            slave0_reg <= {slave0_reg[14:0], mosi_capturado_s0};
            
        if (!cs[1] || (topologia_daisy && !cs[0])) 
            slave1_reg <= {slave1_reg[14:0], mosi_capturado_s1};
    end

    // =========================================================================
    // 4. TASK DE AUTOMAÇÃO (Para facilitar o envio de comandos)
    // =========================================================================
    task send_spi_cmd;
        input [15:0] data;
        input [1:0]  target_slave;
        input        is_daisy;
        input        keep_cs_low;
        begin
            @(posedge clk);
            // Montagem do barramento de 40 bits
            // [39:38] 00 | [37] hold_cs | [36] daisy_mode | [35:34] slave_id
            // [33] cpol=0 | [32] cpha=0 | [31:24] clk_div=4 | [23:16] n_bits=16 | [15:0] data
            cmd_data = {2'b00, keep_cs_low, is_daisy, target_slave, 1'b0, 1'b0, 8'd4, 8'd16, data};
            cmd_valid = 1;

            // Espera a FSM dizer que começou a processar
            wait(cmd_ready == 1);
            @(posedge clk);
            cmd_valid = 0;

            // Espera a FSM dizer que terminou e entregou os dados
            wait(rsp_valid == 1);
            @(posedge clk);
            
            // Avisa que lemos a resposta
            rsp_ready = 1;
            @(posedge clk);
            rsp_ready = 0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // 5. O ROTEIRO DE TESTES PRINCIPAL
    // =========================================================================
    initial begin
        // Configuração do GTKWave
        $dumpfile("spi_master.vcd");
        $dumpvars(0, tb_spi_master_system);

        // Reset inicial de todo o sistema
        reset = 0;
        cmd_valid = 0;
        cmd_data = 40'd0;
        rsp_ready = 0;
        
        #50;
        reset = 1;
        #50;

        $display("--------------------------------------------------");
        $display("[TESTE 1] Iniciando Transacao MULTIPONTO normal");
        $display("Mestre envia 16'h1234 para o Escravo 1. Escravo 1 deve responder 16'hBBBB");
        topologia_daisy = 0;
        
        // (data, slave_id, is_daisy, keep_cs_low)
        send_spi_cmd(16'h1234, 2'd1, 1'b0, 1'b0);
        $display("Resposta lida do Escravo 1: %h", rsp_data);
        
        #100;

        $display("--------------------------------------------------");
        $display("[TESTE 2] Iniciando Transacao DAISY CHAIN (Cascata)");
        $display("Topologia alterada. Mestre -> Slave 0 -> Slave 1 -> Mestre");
        $display("Mestre vai enviar DUAS palavras (16'hDEAD e 16'hBEEF) segurando o CS.");
        topologia_daisy = 1;

        // Palavra 1: Envia DEAD. Isso vai entrar no Slave 0.
        // Como keep_cs_low = 1, a FSM não vai desligar o CS.
        send_spi_cmd(16'hDEAD, 2'd0, 1'b1, 1'b1);
        $display("Transacao 1 finalizada. CS ainda esta BAIXO.");

        // Palavra 2: Envia BEEF. 
        // O DEAD que estava no Slave 0 vai ser empurrado para o Slave 1.
        // O BEEF vai entrar no Slave 0.
        // keep_cs_low = 0, então o CS vai subir no final e cravar os dados nos escravos.
        send_spi_cmd(16'hBEEF, 2'd0, 1'b1, 1'b0);
        $display("Transacao 2 finalizada. CS subiu.");
        
        $display("Verificando registros finais dos Escravos:");
        $display("Slave 0 contem: %h (Esperado: BEEF)", slave0_reg);
        $display("Slave 1 contem: %h (Esperado: DEAD)", slave1_reg);
        $display("--------------------------------------------------");

        #200;
        $finish;
    end

endmodule