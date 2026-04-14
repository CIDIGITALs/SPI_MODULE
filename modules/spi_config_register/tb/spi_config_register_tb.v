`timescale 1ns/1ps

module spi_config_register_tb;

    // 1. Parâmetros e Sinais
    parameter N = 10;
    
    reg clk;
    reg reset;
    reg load;
    reg [N-1:0] data_in;
    
    wire [N-1:0] data_out;

    // 2. Instanciação do DUT (Device Under Test)
    spi_config_register #(
        .N(N)
    ) dut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .data_in(data_in),
        .data_out(data_out)
    );

    // 3. Geração de Clock (50 MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    // 4. Roteiro de Teste
    initial begin
        // Configuração do GTKWave
        $dumpfile("spi_config_register.vcd");
        $dumpvars(0, spi_config_register_tb);

        // Inicialização Segura (Reset)
        reset   = 0;
        load    = 0;
        data_in = 10'd0;

        #25;
        reset = 1; // Solta o reset

        $display("--------------------------------------------------");
        
        // --- TESTE 1: Carregar um valor normal ---
        $display("[TESTE 1] Tentando carregar o valor 10'h2A5...");
        data_in = 10'h2A5; // Coloca o dado no fio de entrada
        load = 1;          // Dá a ordem para salvar
        #20; 
        load = 0;          // Tira a ordem
        
        // Espera um pouco e verifica
        #20;
        $display("Valor na saida: %h", data_out);

        // --- TESTE 2: Mudar a entrada sem o 'load' ativo ---
        $display("\n[TESTE 2] Mudando a entrada para 10'h111 (sem sinal de load)...");
        data_in = 10'h111; 
        #40;
        $display("Valor na saida continuou: %h (O esperado e manter 2A5!)", data_out);

        // --- TESTE 3: Sobrescrever o valor ---
        $display("\n[TESTE 3] Dando o pulso de load para atualizar...");
        load = 1;
        #20;
        load = 0;
        #20;
        $display("Novo valor na saida: %h", data_out);
        
        $display("--------------------------------------------------");

        #40 $finish;
    end

endmodule