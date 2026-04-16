`timescale 1ns/1ps

module tb_spi_register;
    reg clk;
    reg clear_n;
    reg load;
    reg shift_edge;
    reg sample_edge;
    reg serial_in;
    reg [7:0] parallel_in;

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
        serial_in = 0; parallel_in = 8'b10101100; 

        #25 clear_n = 1;
        
        load = 1; #20 load = 0;

        repeat (8) begin //loop para simular 8 ciclos de envio/amostragem, suficiente para transmitir os 8 bits
            #40 sample_edge = 1; 
            serial_in = ~serial_in; //flipa a entrada serial para testar a recepção
            #20 sample_edge = 0;
            
            #40 shift_edge = 1;
            #20 shift_edge = 0;
        end
        
        #100;
        $finish;
    end
endmodule