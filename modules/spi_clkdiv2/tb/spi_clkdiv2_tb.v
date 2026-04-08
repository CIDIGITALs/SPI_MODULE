`timescale 1ns/1ns

module tb_spi_clkdiv2;

    spi_clkdiv2 dut (
    );

    initial begin
        $dumpfile("spi_clkdiv2.vcd");
        $dumpvars(0, tb_spi_clkdiv2);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
