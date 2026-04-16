`timescale 1ns/1ns

module tb_spi_decoder;

    reg        cs_enable; // Sinal de enable 
    reg        daisy_mode; // Se for daisy mode levanta todo o barramento de CS, caso contrário é um decodificador one-hot
    reg  [1:0] slave_id; // como o maximo é 4 escravos, o numero de bits para endereçar é 2 

    wire [3:0] cs_out;

    spi_cs_decoder #(
        .N_SLAVES(4)
    ) dut (
        .cs_enable(cs_enable),
        .daisy_mode(daisy_mode),
        .slave_id(slave_id),
        .cs_out(cs_out)
    );

    initial begin
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
        slave_id = 2; #20; 
        slave_id = 3; #20; 

        $display("\nTestes Concluidos com Sucesso!");
        #20 $finish;
    end

endmodule