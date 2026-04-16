module spi_clk_gen #(
    parameter DIV_WIDTH = 8
)(
    input wire clk, // Clock de entrada
    input wire clear_n, // Reset
    input wire enable, 
    input wire cpol, // Clock Polarity diz se o clock fica em 0 ou 1 quando inativo
    input wire cpha, // Clock Phase determina se a amostragem ocorre na borda líder ou traseira
    input wire [DIV_WIDTH-1:0] clk_div,

    output reg  sclk,
    output wire lead_edge_pulse, //Borda líder ocorre quando o clock muda do estado de repouso para o oposto
    output wire trail_edge_pulse, //Borda traseira ocorre quando o clock muda do estado oposto para o estado de repouso
    output wire sample_edge, //Borda de amostragem
    output wire shift_edge //Borda de deslocamento
);

    reg [DIV_WIDTH-1:0] div_cnt; // Registrador de contagem para gerar o clock
    wire [DIV_WIDTH-1:0] div_value
    wire toggle_now;

    //Operador ternario "se clk_div for zero, use 1, caso contrário use clk_div"
    assign div_value = (clk_div == {DIV_WIDTH{1'b0}}) ? 
                       {{(DIV_WIDTH-1){1'b0}}, 1'b1} : 
                       clk_div;

    // SCLK deve alternar quando o contador atingir o valor de divisão - 1
    assign toggle_now = enable && (div_cnt == (div_value - 1'b1));

    // CPOL
    // Se SCLK está em repouso e vai mudar, essa é a borda líder
    assign lead_edge_pulse  = toggle_now && (sclk == cpol);
    assign trail_edge_pulse = toggle_now && (sclk != cpol);

    // SPI:
    // CPHA = 0 -> sample na borda líder, shift na traseira
    // CPHA = 1 -> shift na borda líder, sample na traseira
    // Com base na em trail_edge_pulse e lead_edge_pulse, é determinado se é uma borda de amostragem ou de deslocamento, dependendo do valor de cpha
    assign sample_edge = (cpha == 1'b0) ? lead_edge_pulse  : trail_edge_pulse;
    assign shift_edge  = (cpha == 1'b0) ? trail_edge_pulse : lead_edge_pulse;

    always @(posedge clk) begin
        // Logica do clear
        if (!clear_n) begin
            div_cnt <= {DIV_WIDTH{1'b0}};
            sclk    <= 1'b0;
        end
        else if (!enable) begin
            // Quando o clock não está habilitado, o contador é resetado e o SCLK é colocado no estado de repouso definido por CPOL
            div_cnt <= {DIV_WIDTH{1'b0}};
            sclk    <= cpol;
        end
        else begin
            // bipa sclk quando é um toggle_now
            if (toggle_now) begin
                div_cnt <= {DIV_WIDTH{1'b0}}; // Reseta o contador
                sclk    <= ~sclk;
            end
            else begin
                //incrementa o contador
                div_cnt <= div_cnt + 1'b1;
            end
        end
    end

endmodule