`timescale 1ns/1ns

module tb_bit_counter;

    parameter WIDTH = 6;

    reg clk;
    reg clear_n;
    reg load;
    reg count_en;
    reg [WIDTH-1:0] n_bits;
    wire [WIDTH-1:0] count;
    wire done;

    // DUT
    bit_counter #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .clear_n(clear_n),
        .load(load),
        .count_en(count_en),
        .n_bits(n_bits),
        .count(count),
        .done(done)
    );

    // Clock: período de 10 ns
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("bit_counter.vcd");
        $dumpvars(0, tb_bit_counter);

        // Inicialização
        clear_n  = 1'b1;
        load     = 1'b0;
        count_en = 1'b0;
        n_bits   = 6'd8;

        $display("==== INICIO DA SIMULACAO ====");

        // -----------------------------
        // Teste 1: clear síncrono
        // -----------------------------
        #2;
        clear_n = 1'b0;
        @(posedge clk); #1;
        $display("T=%0t | apos clear | count=%0d done=%b", $time, count, done);

        clear_n = 1'b1;

        // -----------------------------
        // Teste 2: load zera contador
        // -----------------------------
        load = 1'b1;
        @(posedge clk); #1;
        load = 1'b0;
        $display("T=%0t | apos load  | count=%0d done=%b", $time, count, done);

        // -----------------------------
        // Teste 3: contar 8 bits
        // -----------------------------
        count_en = 1'b1;

        repeat (10) begin
            @(posedge clk); #1;
            $display("T=%0t | contando  | count=%0d done=%b", $time, count, done);
        end

        count_en = 1'b0;
        #10;

        // -----------------------------
        // Teste 4: reinicia e testa outro n_bits
        // -----------------------------
        n_bits = 6'd4;
        load = 1'b1;
        @(posedge clk); #1;
        load = 1'b0;
        $display("T=%0t | novo teste | count=%0d done=%b n_bits=%0d", $time, count, done, n_bits);

        count_en = 1'b1;
        repeat (6) begin
            @(posedge clk); #1;
            $display("T=%0t | contando  | count=%0d done=%b", $time, count, done);
        end
        count_en = 1'b0;

        #20;
        $display("==== FIM DA SIMULACAO ====");
        $finish;
    end

    initial begin
        $monitor("MONITOR T=%0t clk=%b clear_n=%b load=%b count_en=%b n_bits=%0d count=%0d done=%b",
                 $time, clk, clear_n, load, count_en, n_bits, count, done);
    end

endmodule