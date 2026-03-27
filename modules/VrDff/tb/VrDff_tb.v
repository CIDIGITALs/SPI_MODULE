`timescale 1ns/1ns

module tb_VrDff;

    reg CLK;
    reg D;
    wire Q;

    VrDff dut (
        .CLK(CLK),
        .D(D),
        .Q(Q)
    );

    initial begin
        $dumpfile("VrDff.vcd");
        $dumpvars(0, tb_VrDff);
        $monitor("t=%0t CLK=%b D=%b | Q=%b", $time, CLK, D, Q);
       
        CLK = 0;
        forever #5 CLK = ~CLK; 
        D = 0; #10;
        D = 1; #10;
        D = 0; #10;
        D = 1; #10;
        D = 0; #10;
        D = 1; #10;
    end

endmodule
