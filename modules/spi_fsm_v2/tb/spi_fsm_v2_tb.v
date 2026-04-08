`timescale 1ns/1ns

module tb_spi_fsm_v2;

    spi_fsm_v2 dut (
    );

    initial begin
        $dumpfile("spi_fsm_v2.vcd");
        $dumpvars(0, tb_spi_fsm_v2);

        // Inicialização
        #20 reset = 0;

        // Estímulos do teste aqui

        #100 $finish;
    end

endmodule
