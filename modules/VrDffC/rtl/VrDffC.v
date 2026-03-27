module VrDffC (
    input CLK,
    input CLR,
    input D,
    output reg Q
);

    always @(posedge CLK or posedge CLR) begin
        if (CLR==1) Q <= 0;
        else Q <= D;
    end

endmodule
