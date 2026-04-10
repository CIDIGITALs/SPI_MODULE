module spi_clk_gen #(
    parameter DIV_WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 clear_n,
    input  wire                 enable,
    input  wire                 cpol,
    input  wire                 cpha,
    input  wire [DIV_WIDTH-1:0] clk_div,

    output reg                  sclk,
    output wire                 lead_edge_pulse,
    output wire                 trail_edge_pulse,
    output wire                 sample_edge,
    output wire                 shift_edge
);

    reg [DIV_WIDTH-1:0] div_cnt;
    wire [DIV_WIDTH-1:0] div_value;
    wire toggle_now;

    // Evita problema se clk_div vier 0
    assign div_value = (clk_div == {DIV_WIDTH{1'b0}}) ?
                       {{(DIV_WIDTH-1){1'b0}}, 1'b1} :
                       clk_div;

    // Toggle do SCLK ocorre quando o contador atinge o divisor
    assign toggle_now = enable && (div_cnt == (div_value - 1'b1));

    // Definição de borda líder/traseira em função do nível de repouso (CPOL)
    // Se SCLK está em repouso e vai mudar, essa é a borda líder
    assign lead_edge_pulse  = toggle_now && (sclk == cpol);
    assign trail_edge_pulse = toggle_now && (sclk != cpol);

    // SPI:
    // CPHA = 0 -> sample na borda líder, shift na traseira
    // CPHA = 1 -> shift na borda líder, sample na traseira
    assign sample_edge = (cpha == 1'b0) ? lead_edge_pulse  : trail_edge_pulse;
    assign shift_edge  = (cpha == 1'b0) ? trail_edge_pulse : lead_edge_pulse;

    always @(posedge clk) begin
        if (!clear_n) begin
            div_cnt <= {DIV_WIDTH{1'b0}};
            sclk    <= 1'b0;
        end
        else if (!enable) begin
            div_cnt <= {DIV_WIDTH{1'b0}};
            sclk    <= cpol;
        end
        else begin
            if (toggle_now) begin
                div_cnt <= {DIV_WIDTH{1'b0}};
                sclk    <= ~sclk;
            end
            else begin
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end

endmodule