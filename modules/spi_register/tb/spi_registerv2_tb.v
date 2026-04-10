`timescale 1ns/1ps

module tb_spi_register;
    reg clk;
    reg clear_n;
    reg load;
    reg shift_edge;
    reg sample_edge;
    reg serial_in;
    reg [7:0] parallel_in; // Usando 8 bits para simplificar a visualização

    wire [7:0] parallel_out;
    wire serial_out;

    spi_shift_register #(.WIDTH(8), .MSB_FIRST(1)) dut (
        .clk(clk), .clear_n(clear_n), .load(load),
        .shift_edge(shift_edge), .sample_edge(sample_edge),
        .serial_in(serial_in), .parallel_in(parallel_in),
        .parallel_out(parallel_out), .serial_out(serial_out)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        $dumpfile("tb_spi_register.vcd");
        $dumpvars(0, tb_spi_register);

        clear_n = 0; load = 0; shift_edge = 0; sample_edge = 0;
        serial_in = 0; parallel_in = 8'b10101100; // Valor a transmitir
        
        #25 clear_n = 1;
        
        // Carrega o dado
        load = 1; #20 load = 0;

        // Simula os "ticks" vindo do gerador de clock
        repeat (8) begin
            #40 sample_edge = 1; serial_in = ~serial_in; // Simula dado chegando e inverte a cada bit
            #20 sample_edge = 0;
            
            #40 shift_edge = 1;
            #20 shift_edge = 0;
        end
        
        #100;
        $finish;
    end
endmodule