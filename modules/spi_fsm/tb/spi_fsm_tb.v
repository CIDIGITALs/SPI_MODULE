`timescale 1ns/1ns

module tb_spi_fsm;

    spi_fsm dut (
    );

    initial begin
        $dumpfile("spi_fsm.vcd");
        $dumpvars(0, tb_spi_fsm);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
