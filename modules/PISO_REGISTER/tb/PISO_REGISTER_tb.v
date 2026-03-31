`timescale 1ns/1ns

module tb_PISO_REGISTER;
    reg clk;
    reg reset;
    reg load;
    reg dir;
    reg [7:0] data_in;
    wire data_out;

    PISO_REGISTER dut (
        .clk(clk),
        .reset(reset),
        .load(load),
        .dir(dir),
        .data_in(data_in),
        .data_out(data_out)

    );

    initial clk = 0;
    always #5 clk = ~clk; 

    initial begin
        $dumpfile("PISO_REGISTER.vcd");
        $dumpvars(0, tb_PISO_REGISTER);
        // Teste 1: Reset
        reset = 1; load = 0; dir = 0; data_in = 8'b10101010; #10;
        reset = 0; #10;


        // Teste 3: Shift Right
        data_in = 8'b11001100;
        load = 1; #10; // Carrega o registrador
        load = 0; #10;
        dir = 0; #80; // Shift right por 8 ciclos
        // Teste 4: Shift Left 
        load = 1; #10;
        load = 0; #10;
        dir = 1; #80; // Shift left por 8 ciclos
        $finish;

    end

endmodule
