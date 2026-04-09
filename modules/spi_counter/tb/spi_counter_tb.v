`timescale 1ns/1ns

module tb_spi_counter;

    spi_counter dut (
    );

    initial begin
        $dumpfile("spi_counter.vcd");
        $dumpvars(0, tb_spi_counter);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
