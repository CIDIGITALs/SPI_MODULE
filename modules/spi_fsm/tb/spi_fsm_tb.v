`timescale 1ns/1ns

module tb_spi_fsm;

    // Entradas para o DUT (Device Under Test)
    reg clk;
    reg rst_n;
    reg cmd_valid;
    reg rsp_ready;
    reg transfer_done;

    // Saídas do DUT
    wire cmd_ready;
    wire rsp_valid;
    wire start_transfer;
    wire load_data;
    wire cs_control;
    wire config_en;

    // Instanciação da sua Máquina de Estados
    spi_fsm dut (
        .clk(clk),
        .rst_n(rst_n),
        .cmd_valid(cmd_valid),
        .cmd_ready(cmd_ready),
        .rsp_ready(rsp_ready),
        .rsp_valid(rsp_valid),
        .transfer_done(transfer_done),
        .start_transfer(start_transfer),
        .load_data(load_data),
        .cs_control(cs_control),
        .config_en(config_en)
    );

    // Geração do Clock isolada (período de 10ns)
    initial clk = 0;
    always #5 clk = ~clk;

    // Bloco de estímulos principal
    initial begin
        // Configuração de log para o GTKWave
        $dumpfile("spi_fsm.vcd");
        $dumpvars(0, tb_spi_fsm);

        // 1. Inicialização segura
        rst_n = 0;          // Mantém em reset
        cmd_valid = 0;
        rsp_ready = 0;
        transfer_done = 0;

        #12;                // Espera um pouco mais que 1 ciclo de clock
        rst_n = 1;          // Solta o reset. A FSM deve ir para IDLE (cmd_ready sobe)

        // --- INICIANDO A TRANSAÇÃO ---
        #10;
        $display("[%0t] Sistema: Enviando comando (cmd_valid = 1)", $time);
        cmd_valid = 1;      // Levanta a flag de comando válido

        #10; // Ciclo do FETCH_CMD
        cmd_valid = 0;      // O sistema externo pode abaixar a flag

        // Aqui a FSM vai passar pelos estados sozinha:
        // -> CONFIGURE (deve levantar load_data e config_en)
        // -> ASSERT_CS (deve levantar cs_control)
        // -> TRANSFER (deve manter cs_control e levantar start_transfer)
        #30; 

        $display("[%0t] Shift Register: Começando a deslocar bits...", $time);
        #40; // Simula um tempo demorado de deslocamento serial
        
        $display("[%0t] Shift Register: Transferência concluída (transfer_done = 1)", $time);
        transfer_done = 1;  // O contador avisa a FSM que acabou

        #10; // Ciclo do DEASSERT_CS (CS volta para 0)
        transfer_done = 0;  // Abaixa o aviso
        
        #10; // Ciclo do DONE
        $display("[%0t] FSM: Operação concluída (rsp_valid = %b)", $time, rsp_valid);

        #20;
        $display("[%0t] Sistema: Resposta lida (rsp_ready = 1)", $time);
        rsp_ready = 1;      // Sistema avisa que recebeu o rsp_valid

        #10; // Volta para IDLE
        rsp_ready = 0;

        #30;
        $display("[%0t] Fim da simulação.", $time);
        $finish;
    end

endmodule