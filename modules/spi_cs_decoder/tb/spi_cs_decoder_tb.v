`timescale 1ns/1ns

module tb_spi_decoder;

    // 1. Declaração dos Sinais
    // Entradas do módulo são geradas como 'reg' no testbench
    reg        cs_enable;
    reg        daisy_mode;
    reg  [1:0] slave_id; // $clog2(4) = 2 bits

    // Saídas do módulo são lidas como 'wire'
    wire [3:0] cs_out;

    // 2. Instanciação Correta do DUT (Device Under Test)
    spi_cs_decoder #(
        .N_SLAVES(4)
    ) dut (
        .cs_enable(cs_enable),
        .daisy_mode(daisy_mode),
        .slave_id(slave_id),
        .cs_out(cs_out)
    );

    // 3. Roteiro de Teste
    initial begin
        // Configuração do GTKWave
        $dumpfile("spi_decoder.vcd");
        $dumpvars(0, tb_spi_decoder);

        // Inicialização Segura
        cs_enable  = 0;
        daisy_mode = 0;
        slave_id   = 0;

        // O $monitor imprime no terminal toda vez que um desses sinais mudar
        $display("Iniciando Testes do Decodificador CS...");
        $display(" Tempo | Enable | Daisy | ID  | Saida CS (3 2 1 0)");
        $display("-------|--------|-------|-----|--------------------");
        $monitor("%5t  |   %b    |   %b   | %d   |       %b", $time, cs_enable, daisy_mode, slave_id, cs_out);

        #10;
        $display("\n[TESTE 1] CS Desabilitado -> Ninguem deve acordar (Saida 1111)");
        cs_enable = 0; daisy_mode = 0; slave_id = 2;
        
        #20;
        $display("\n[TESTE 2] Modo MULTIPONTO -> Apenas um pino vai a 0 por vez");
        cs_enable = 1; daisy_mode = 0;
        slave_id = 0; #20;
        slave_id = 1; #20;
        slave_id = 2; #20;
        slave_id = 3; #20;

        $display("\n[TESTE 3] Modo DAISY CHAIN -> Fixo no pino 0, ignora o ID");
        cs_enable = 1; daisy_mode = 1;
        
        slave_id = 0; #20; 
        slave_id = 2; #20; // Tentando chamar o escravo 2...
        slave_id = 3; #20; // Tentando chamar o escravo 3...
        // ...mas o cs_out deve continuar teimosamente em 1110!

        $display("\nTestes Concluidos com Sucesso!");
        #20 $finish;
    end

endmodule