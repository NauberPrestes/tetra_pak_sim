// ========================================================
// Tetra Pak Project:
// Encoder signal generator modules (X, Y, Z)
// 8 bit mux and demux modules
// Vrsion for simulation with Icarus + Make + GTKWave
// ========================================================

// --------------------------------------------------------
// (1) clock divider geração da base de tempo dos sinais X Y Z
// --------------------------------------------------------

module clockDivider1(
    // Clock para o parâmetro Tz. Lembrando que Tx=4.Tz
    // 450m/min: período=3141, DIV=1570
    // 600m/min: período=2356, DIV=1178
    input  clki,
    output clko
);

parameter DIV = 1178;

reg [11:0] count = 0;
reg out = 0;

always @(posedge clki) begin
    if (count == DIV) begin
        count <= 0;
        out <= ~out;
    end
    else begin
        count <= count + 1;
    end
end

assign clko = out;

endmodule

// --------------------------------------------------------
// (1) Gerador dos sinais X e Y do encoder (500 pulsos por volta)
// --------------------------------------------------------

module genXY(
    input clkTz,
    output X,
    output Y
);

reg outX = 0;
reg outY = 0;
reg [1:0] count = 0;

always @(posedge clkTz)
    count <= count + 1;

always @(*) begin
    case(count)
        2'd0: begin outX = 1'b1; outY = 1'b0; end
        2'd1: begin outX = 1'b1; outY = 1'b1; end
        2'd2: begin outX = 1'b0; outY = 1'b1; end
        2'd3: begin outX = 1'b0; outY = 1'b0; end
    endcase
end

assign X = outX;
assign Y = outY;

endmodule

// --------------------------------------------------------
// (1) Geração do sinal do canal Z (um pulso por volta)
// --------------------------------------------------------

module genZ(
    input clkTz,
    output Z
);

reg outZ = 0;
reg [10:0] i = 0;

always @(posedge clkTz) begin

    if (i == 1999) begin
        i <= 0;
        outZ <= 1'b1;
    end
    else begin
        i <= i + 1;
        outZ <= 1'b0;
    end

end

assign Z = outZ;

endmodule

// --------------------------------------------------------
// (2) Módulo gerador de sinais (X,Y,Z)
// --------------------------------------------------------

module genXYZ(
    input clki,
    output [2:0] sigXYZ,
    output clockTz
);

wire clkTz_internal;

clockDivider1 clkdiv1(
    .clki(clki),
    .clko(clkTz_internal)
);

genXY genXY1(
    .clkTz(clkTz_internal),
    .X(sigXYZ[0]),
    .Y(sigXYZ[1])
);

genZ genZ1(
    .clkTz(clkTz_internal),
    .Z(sigXYZ[2])
);

assign clockTz = clkTz_internal;

endmodule

// --------------------------------------------------------
// (1) Multiplexador 8x1
// --------------------------------------------------------

module mux(
    input  [2:0] sel,
    input  [7:0] ch_in,
    output ch_out
);

assign ch_out = ch_in[sel];

endmodule

// --------------------------------------------------------
// (1) Demultiplexador 8x1
// --------------------------------------------------------

module demux(
    input  [2:0] sel,
    input  ch_in,
    output [7:0] ch_out
);

assign ch_out = (8'b00000001 << sel) & {8{ch_in}};

endmodule

// --------------------------------------------------------
// (1) couter8: gerador do sinal sel do multiplexador
// --------------------------------------------------------

module counter8(
    input clki,
    output [2:0] sel
);

reg [2:0] count = 0;

always @(posedge clki)
    count <= count + 1;

assign sel = count;

endmodule


// --------------------------------------------------------
// (2) Transmissor
// --------------------------------------------------------

module transmitter(
    input clki,
    input [7:0] muxIn,
    output TXdata,
    output TXclk
);

wire [2:0] sel;

counter8 cnt2(
    .clki(clki),
    .sel(sel)
);

mux mux1(
    .sel(sel),
    .ch_in(muxIn),
    .ch_out(TXdata)
);

assign TXclk = clki;

endmodule

// --------------------------------------------------------
// (2) Receptor
// --------------------------------------------------------

module receiver(
    input clki,
    input demuxIn,
    output [7:0] RXdata,
    output RXclk
);

wire [2:0] sel;

counter8 cnt3(
    .clki(clki),
    .sel(sel)
);

demux demux1(
    .sel(sel),
    .ch_in(demuxIn),
    .ch_out(RXdata)
);

assign RXclk = clki;

endmodule