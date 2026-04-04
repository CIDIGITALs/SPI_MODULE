// Registrador de deslocamento base para o módulo SPI
module shift_register #(
    parameter WIDTH = 8,
    parameter MSB_FIRST = 1  // 1 = transmite MSB primeiro, 0 = LSB primeiro
)(
    input  wire             clk,
    input  wire             clear_n,      // clear síncrono ativo em 0
    input  wire             load,         // carrega parallel_in
    input  wire             shift_en,     // habilita deslocamento
    input  wire             serial_in,    // bit que entra no registrador
    input  wire [WIDTH-1:0] parallel_in,  // carga paralela
    output reg  [WIDTH-1:0] parallel_out, // conteúdo atual do registrador
    output wire             serial_out    // bit que sai do registrador
);

    always @(posedge clk) begin
        if (!clear_n) begin
            parallel_out <= {WIDTH{1'b0}};
        end
        else if (load) begin
            parallel_out <= parallel_in;
        end
        else if (shift_en) begin
            if (MSB_FIRST) begin
                // Sai o bit mais significativo; entra serial_in no LSB
                parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
            end
            else begin
                // Sai o bit menos significativo; entra serial_in no MSB
                parallel_out <= {serial_in, parallel_out[WIDTH-1:1]};
            end
        end
    end

    assign serial_out = (MSB_FIRST) ? parallel_out[WIDTH-1] : parallel_out[0];

endmodule
