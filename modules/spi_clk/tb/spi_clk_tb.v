`timescale 1ns/1ns

module tb_spi_clk;

    spi_clk dut (
    );

    initial begin
        $dumpfile("spi_clk.vcd");
        $dumpvars(0, tb_spi_clk);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
