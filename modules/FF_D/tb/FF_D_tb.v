`timescale 1ns/1ns
module tb_FF_D;
    reg clk;
    reg set;
    reg clear_n;
    reg d;
    wire q, nq;

    FF_D dut (
        .clk(clk),
        .set(set),
        .clear_n(clear_n),
        .d(d),
        .q(q),
        .nq(nq)
    );
    //Cria o pulso de clock com período de 10ns (100MHz)
    initial clk = 0;
    always #5 clk = ~clk;    

    initial begin
        $dumpfile("FF_D.vcd");
        $dumpvars(0, tb_FF_D);

        // Inicialização com funcionamento normal set=0 e clear=1
        #10 set = 0; clear_n = 1; d = 1; 
        // Teste 1: Clear
        #20 set = 0; clear_n = 0;
        // Teste 2: Set
        #30 set = 1; d=0; clear_n = 1; 
        // Teste 3: Funcionamento normal
        #40 set =0; d = 0;

        $finish;
    end

endmodule
