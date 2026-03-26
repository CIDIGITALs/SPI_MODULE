`timescale 1ns/1ns 

module tb_VrDlatch;

  reg D;
  reg G;
  wire Q;

  VrDlatch dut (
    .D(D),
    .G(G),
    .Q(Q)
  );

  initial begin
    $dumpfile("VrDlatch.vcd");
    $dumpvars(0, tb_VrDlatch);
    $monitor("t=%0t D=%b G=%b | Q=%b", $time, D, G, Q);

    D = 0; G = 0; #10;
    D = 1; G = 0; #10;
    D = 0; G = 1; #10;
    D = 1; G = 1; #10;
    D = 0; G = 0; #10;
    D = 1; G = 0; #10;
    D = 0; G = 1; #10;
    D = 1; G = 1; #10;

    $finish;
  end

endmodule