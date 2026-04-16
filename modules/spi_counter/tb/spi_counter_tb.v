`timescale 1ns/1ps

module tb_spi_counter;
    
    reg clk;
    reg rst_n;
    reg load_data;
    reg trail_edge;
    reg [4:0] n_bits; 

    // Saída
    wire transfer_done;

    spi_counter #(
        .CNT_WIDTH(5)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_data(load_data),
        .trail_edge(trail_edge),
        .n_bits(n_bits),
        .transfer_done(transfer_done)
    );

    initial clk = 0;
    always #10 clk = ~clk; // Período de 20ns

    initial begin
        $dumpfile("tb_spi_counter.vcd");
        $dumpvars(0, tb_spi_counter);

        rst_n      = 0;
        load_data  = 0;
        trail_edge = 0;
        n_bits     = 5'd0;

        #25;
        rst_n = 1; 

        $display("--------------------------------------------------");
        $display("[TESTE 1] Simulando um envio rapido de 4 bits");
        
        n_bits = 5'd4;
        load_data = 1;
        #20; 
        load_data = 0;

        repeat (4) begin
            #40 trail_edge = 1; 
            #20 trail_edge = 0;
        end

        #40; 
        if (transfer_done) $display("-> Sucesso: transfer_done subiu apos 4 bits!");
        else $display("-> ERRO: transfer_done nao subiu!");


        $display("--------------------------------------------------");
        $display("[TESTE 2] Simulando a carga oficial de 16 bits");
        
        n_bits = 5'd16;
        load_data = 1;
        #20; 
        load_data = 0; 

        repeat (16) begin
            #40 trail_edge = 1; 
            #20 trail_edge = 0;
        end

        #40;
        if (transfer_done) $display("-> Sucesso: transfer_done subiu apos 16 bits!");
        else $display("-> ERRO: transfer_done nao subiu!");
        $display("--------------------------------------------------");

        #100;
        $finish;
    end

endmodule