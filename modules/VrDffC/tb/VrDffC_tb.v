`timescale 1ns/1ns

module tb_VrDffC;
    reg CLK;
    reg RESET;
    reg DATA_IN;
    wire DATA_OUT;

    VrDffC dut (
        .CLK(CLK),
        .CLR(RESET),
        .D(DATA_IN),
        .Q(DATA_OUT)
    );

    initial CLK = 0;
    always #5 CLK = ~CLK; 


    initial begin
        $dumpfile("VrDffC.vcd");
        $dumpvars(0, tb_VrDffC);
        $monitor("t=%0t CLK=%b CLR=%b D=%b | Q=%b", $time, CLK, RESET, DATA_IN, DATA_OUT);
        // Teste de reset
        RESET = 1; DATA_IN = 0; #10;
        RESET = 0; #10;
        // Teste de operação normal
        DATA_IN = 1; #10;
        DATA_IN = 0; #10;
        DATA_IN = 1; #10;
        DATA_IN = 0; #10;
        DATA_IN = 1; #10;
        // Teste de reset durante operação
        RESET = 1; #10;
        RESET = 0; #10;
        DATA_IN = 1; #10;
        DATA_IN = 0; #10;
    $finish;
        
        
   end

endmodule
