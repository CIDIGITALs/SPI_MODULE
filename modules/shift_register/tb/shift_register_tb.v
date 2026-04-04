`timescale 1ns/1ns

module tb_shift_register;

    parameter WIDTH = 8;
    parameter MSB_FIRST = 1;

    reg clk;
    reg clear_n;
    reg load;
    reg shift_en;
    reg serial_in;
    reg [WIDTH-1:0] parallel_in;
    wire [WIDTH-1:0] parallel_out;
    wire serial_out;

    // Instância do DUT
    shift_register #(
        .WIDTH(WIDTH),
        .MSB_FIRST(MSB_FIRST)
    ) dut (
        .clk(clk),
        .clear_n(clear_n),
        .load(load),
        .shift_en(shift_en),
        .serial_in(serial_in),
        .parallel_in(parallel_in),
        .parallel_out(parallel_out),
        .serial_out(serial_out)
    );

    // Geração de clock: período = 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("shift_register.vcd");
        $dumpvars(0, tb_shift_register);

        // Inicialização
        clear_n     = 1'b1;
        load        = 1'b0;
        shift_en    = 1'b0;
        serial_in   = 1'b0;
        parallel_in = 8'b00000000;

        // -----------------------------
        // Teste 1: clear síncrono
        // -----------------------------
        #2;
        clear_n = 1'b0;
        @(posedge clk);   // clear ocorre na borda de subida
        #1;
        $display("T=%0t | Após clear | parallel_out = %b | serial_out = %b", 
                 $time, parallel_out, serial_out);

        clear_n = 1'b1;

        // -----------------------------
        // Teste 2: carga paralela
        // -----------------------------
        parallel_in = 8'b10110010;
        load = 1'b1;
        @(posedge clk);
        #1;
        load = 1'b0;

        $display("T=%0t | Após load  | parallel_out = %b | serial_out = %b", 
                 $time, parallel_out, serial_out);

        // -----------------------------
        // Teste 3: deslocamentos
        // serial_in vai entrando no LSB
        // -----------------------------
        serial_in = 1'b0;
        shift_en = 1'b1;
        @(posedge clk); #1;
        $display("T=%0t | Shift 1    | parallel_out = %b | serial_out = %b", 
                 $time, parallel_out, serial_out);

        serial_in = 1'b0;
        @(posedge clk); #1;
        $display("T=%0t | Shift 2    | parallel_out = %b | serial_out = %b", 
                 $time, parallel_out, serial_out);

        serial_in = 1'b0;
        @(posedge clk); #1;
        $display("T=%0t | Shift 3    | parallel_out = %b | serial_out = %b", 
                 $time, parallel_out, serial_out);

        serial_in = 1'b0;
        @(posedge clk); #1;
        $display("T=%0t | Shift 4    | parallel_out = %b | serial_out = %b", 
                 $time, parallel_out, serial_out);

        // -----------------------------
        // Finalização
        // -----------------------------
        #100;
        $finish;
    end

endmodule
