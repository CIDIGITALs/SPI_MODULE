module VrDff (
    input CLK,
    input D,
    output reg Q
);

always @(posedge CLK) 
    Q <= D;
endmodule
