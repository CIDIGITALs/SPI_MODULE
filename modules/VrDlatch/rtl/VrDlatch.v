module VrDlatch (
    input D,       
    input G,       
    output reg Q   
);

  always @(D or G) begin
    if (G == 1'b1) begin
        Q <= D;
    end
end
    
endmodule