`timescale 1ns/1ps

module tb_spi_fsm;
    reg clk;
    reg rst_n;
    reg cmd_valid;
    reg hold_cs;
    reg rsp_ready;
    reg transfer_done;

    wire cmd_ready;
    wire rsp_valid;
    wire load_data;
    wire cs_enable;
    wire start_transfer;

    spi_fsm dut (
        .clk(clk), .rst_n(rst_n),
        .cmd_valid(cmd_valid), .cmd_ready(cmd_ready),
        .hold_cs(hold_cs), .rsp_ready(rsp_ready), .rsp_valid(rsp_valid),
        .transfer_done(transfer_done), .load_data(load_data),
        .cs_enable(cs_enable), .start_transfer(start_transfer)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        $dumpfile("tb_spi_fsm.vcd");
        $dumpvars(0, tb_spi_fsm);

        rst_n = 0; cmd_valid = 0; hold_cs = 0; rsp_ready = 0; transfer_done = 0;
        #25 rst_n = 1;

        $display("Iniciando comando NORMAL (hold_cs = 0)");
        // Sistema avisa que o comando está válido
        cmd_valid = 1;
        wait(!cmd_ready); // FSM avança
        #20 cmd_valid = 0;

        // FSM entra em TRANSFER e aguarda
        #60 transfer_done = 1; // Contador avisa que acabou
        #20 transfer_done = 0;

        // FSM termina e avisa
        wait(rsp_valid);
        #20 rsp_ready = 1;
        #20 rsp_ready = 0;

        #100;

        $display("Iniciando comando DAISY CHAIN (hold_cs = 1)");
        hold_cs = 1;
        cmd_valid = 1;
        wait(!cmd_ready);
        #20 cmd_valid = 0;

        #60 transfer_done = 1;
        #20 transfer_done = 0;

        wait(rsp_valid);
        #20 rsp_ready = 1;
        #20 rsp_ready = 0;

        #100 $finish;
    end
endmodule