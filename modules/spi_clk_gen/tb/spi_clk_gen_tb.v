`timescale 1ns/1ps

module tb_spi_clk;
    reg clk;
    reg clear_n;
    reg enable;
    reg cpol;
    reg cpha;
    reg [7:0] clk_div;

    wire sclk;
    wire lead_edge, trail_edge, sample_edge, shift_edge;

    spi_clk_gen #(.DIV_WIDTH(8)) dut (
        .clk(clk), .clear_n(clear_n), .enable(enable),
        .cpol(cpol), .cpha(cpha), .clk_div(clk_div),
        .sclk(sclk), .lead_edge_pulse(lead_edge), .trail_edge_pulse(trail_edge),
        .sample_edge(sample_edge), .shift_edge(shift_edge)
    );

    initial clk = 0;
    always #10 clk = ~clk; // 50 MHz

    initial begin
        $dumpfile("tb_spi_clk.vcd");
        $dumpvars(0, tb_spi_clk);

        clear_n = 0; enable = 0; cpol = 0; cpha = 0; clk_div = 8'd4;
        #25 clear_n = 1;
        
        $display("Testando CPOL=0, CPHA=0");
        enable = 1;
        #400; // Deixa o relógio bater algumas vezes
        
        enable = 0;
        #100;
        
        $display("Testando CPOL=1, CPHA=1");
        cpol = 1; cpha = 1;
        enable = 1;
        #400;

        $finish;
    end
endmodule