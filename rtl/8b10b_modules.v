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

// ========================================================
// 8b/10b Encoder (Data Characters Only)
// Fully synthesizable
// ========================================================

module encoder8b10b (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] data_in,
    output reg  [9:0] code_out,
    output reg        running_disparity   // 0 = negative, 1 = positive
);

// --------------------------------------------------------
// Split input into 5b/3b
// --------------------------------------------------------

wire [4:0] fiveb = data_in[4:0];
wire [2:0] threeb = data_in[7:5];

// --------------------------------------------------------
// 5b/6b encoding tables (negative disparity version)
// --------------------------------------------------------

reg [5:0] sixb_neg;
reg       sixb_disp; // 1 if this code has positive disparity

always @(*) begin
    case (fiveb)
        5'b00000: begin sixb_neg = 6'b100111; sixb_disp = 1; end
        5'b00001: begin sixb_neg = 6'b011101; sixb_disp = 1; end
        5'b00010: begin sixb_neg = 6'b101101; sixb_disp = 1; end
        5'b00011: begin sixb_neg = 6'b110001; sixb_disp = 0; end
        5'b00100: begin sixb_neg = 6'b110101; sixb_disp = 1; end
        5'b00101: begin sixb_neg = 6'b101001; sixb_disp = 0; end
        5'b00110: begin sixb_neg = 6'b011001; sixb_disp = 0; end
        5'b00111: begin sixb_neg = 6'b111000; sixb_disp = 0; end
        5'b01000: begin sixb_neg = 6'b111001; sixb_disp = 1; end
        5'b01001: begin sixb_neg = 6'b100101; sixb_disp = 0; end
        5'b01010: begin sixb_neg = 6'b010101; sixb_disp = 0; end
        5'b01011: begin sixb_neg = 6'b110100; sixb_disp = 0; end
        5'b01100: begin sixb_neg = 6'b001101; sixb_disp = 0; end
        5'b01101: begin sixb_neg = 6'b101100; sixb_disp = 0; end
        5'b01110: begin sixb_neg = 6'b011100; sixb_disp = 0; end
        5'b01111: begin sixb_neg = 6'b010111; sixb_disp = 1; end
        5'b10000: begin sixb_neg = 6'b011011; sixb_disp = 1; end
        5'b10001: begin sixb_neg = 6'b100011; sixb_disp = 0; end
        5'b10010: begin sixb_neg = 6'b010011; sixb_disp = 0; end
        5'b10011: begin sixb_neg = 6'b110010; sixb_disp = 0; end
        5'b10100: begin sixb_neg = 6'b001011; sixb_disp = 0; end
        5'b10101: begin sixb_neg = 6'b101010; sixb_disp = 0; end
        5'b10110: begin sixb_neg = 6'b011010; sixb_disp = 0; end
        5'b10111: begin sixb_neg = 6'b111010; sixb_disp = 1; end
        5'b11000: begin sixb_neg = 6'b110011; sixb_disp = 1; end
        5'b11001: begin sixb_neg = 6'b100110; sixb_disp = 0; end
        5'b11010: begin sixb_neg = 6'b010110; sixb_disp = 0; end
        5'b11011: begin sixb_neg = 6'b110110; sixb_disp = 1; end
        5'b11100: begin sixb_neg = 6'b001110; sixb_disp = 0; end
        5'b11101: begin sixb_neg = 6'b101110; sixb_disp = 1; end
        5'b11110: begin sixb_neg = 6'b011110; sixb_disp = 1; end
        5'b11111: begin sixb_neg = 6'b101011; sixb_disp = 1; end
    endcase
end

// --------------------------------------------------------
// 3b/4b encoding (negative disparity version)
// --------------------------------------------------------

reg [3:0] fourb_neg;
reg       fourb_disp;

always @(*) begin
    case (threeb)
        3'b000: begin fourb_neg = 4'b1011; fourb_disp = 1; end
        3'b001: begin fourb_neg = 4'b1001; fourb_disp = 0; end
        3'b010: begin fourb_neg = 4'b0101; fourb_disp = 0; end
        3'b011: begin fourb_neg = 4'b1100; fourb_disp = 0; end
        3'b100: begin fourb_neg = 4'b1101; fourb_disp = 1; end
        3'b101: begin fourb_neg = 4'b1010; fourb_disp = 0; end
        3'b110: begin fourb_neg = 4'b0110; fourb_disp = 0; end
        3'b111: begin fourb_neg = 4'b1110; fourb_disp = 1; end
    endcase
end

// --------------------------------------------------------
// Running disparity control
// --------------------------------------------------------

wire use_positive = running_disparity;

wire [5:0] sixb_final  = use_positive ? ~sixb_neg  : sixb_neg;
wire [3:0] fourb_final = use_positive ? ~fourb_neg : fourb_neg;

wire total_disp = sixb_disp ^ fourb_disp;

// --------------------------------------------------------
// Sequential output
// --------------------------------------------------------

always @(posedge clk or posedge rst) begin
    if (rst) begin
        code_out <= 10'b0;
        running_disparity <= 0; // start negative
    end
    else begin
        code_out <= {fourb_final, sixb_final};
        running_disparity <= total_disp;
    end
end

endmodule

// ========================================================
// 8b/10b Decoder (Data Characters Only)
// Fully synthesizable
// Matches provided encoder
// ========================================================

module decoder8b10b (
    input  wire       clk,
    input  wire       rst,
    input  wire [9:0] code_in,
    output reg  [7:0] data_out,
    output reg        running_disparity,
    output reg        code_error,
    output reg        disparity_error
);

// --------------------------------------------------------
// Internal signals
// --------------------------------------------------------

wire [3:0] fourb = code_in[9:6];
wire [5:0] sixb  = code_in[5:0];

// Detect polarity (positive if MSB group inverted)
wire is_positive = (running_disparity == 1'b1);

// Normalize to negative form for table decoding
wire [5:0] sixb_norm  = is_positive ? ~sixb  : sixb;
wire [3:0] fourb_norm = is_positive ? ~fourb : fourb;

// --------------------------------------------------------
// 6b → 5b decode
// --------------------------------------------------------

reg [4:0] fiveb_dec;
reg       sixb_valid;
reg       sixb_disp;

always @(*) begin
    sixb_valid = 1;
    case (sixb_norm)
        6'b100111: begin fiveb_dec=5'b00000; sixb_disp=1; end
        6'b011101: begin fiveb_dec=5'b00001; sixb_disp=1; end
        6'b101101: begin fiveb_dec=5'b00010; sixb_disp=1; end
        6'b110001: begin fiveb_dec=5'b00011; sixb_disp=0; end
        6'b110101: begin fiveb_dec=5'b00100; sixb_disp=1; end
        6'b101001: begin fiveb_dec=5'b00101; sixb_disp=0; end
        6'b011001: begin fiveb_dec=5'b00110; sixb_disp=0; end
        6'b111000: begin fiveb_dec=5'b00111; sixb_disp=0; end
        6'b111001: begin fiveb_dec=5'b01000; sixb_disp=1; end
        6'b100101: begin fiveb_dec=5'b01001; sixb_disp=0; end
        6'b010101: begin fiveb_dec=5'b01010; sixb_disp=0; end
        6'b110100: begin fiveb_dec=5'b01011; sixb_disp=0; end
        6'b001101: begin fiveb_dec=5'b01100; sixb_disp=0; end
        6'b101100: begin fiveb_dec=5'b01101; sixb_disp=0; end
        6'b011100: begin fiveb_dec=5'b01110; sixb_disp=0; end
        6'b010111: begin fiveb_dec=5'b01111; sixb_disp=1; end
        6'b011011: begin fiveb_dec=5'b10000; sixb_disp=1; end
        6'b100011: begin fiveb_dec=5'b10001; sixb_disp=0; end
        6'b010011: begin fiveb_dec=5'b10010; sixb_disp=0; end
        6'b110010: begin fiveb_dec=5'b10011; sixb_disp=0; end
        6'b001011: begin fiveb_dec=5'b10100; sixb_disp=0; end
        6'b101010: begin fiveb_dec=5'b10101; sixb_disp=0; end
        6'b011010: begin fiveb_dec=5'b10110; sixb_disp=0; end
        6'b111010: begin fiveb_dec=5'b10111; sixb_disp=1; end
        6'b110011: begin fiveb_dec=5'b11000; sixb_disp=1; end
        6'b100110: begin fiveb_dec=5'b11001; sixb_disp=0; end
        6'b010110: begin fiveb_dec=5'b11010; sixb_disp=0; end
        6'b110110: begin fiveb_dec=5'b11011; sixb_disp=1; end
        6'b001110: begin fiveb_dec=5'b11100; sixb_disp=0; end
        6'b101110: begin fiveb_dec=5'b11101; sixb_disp=1; end
        6'b011110: begin fiveb_dec=5'b11110; sixb_disp=1; end
        6'b101011: begin fiveb_dec=5'b11111; sixb_disp=1; end
        default: begin fiveb_dec=5'b00000; sixb_disp=0; sixb_valid=0; end
    endcase
end

// --------------------------------------------------------
// 4b → 3b decode
// --------------------------------------------------------

reg [2:0] threeb_dec;
reg       fourb_valid;
reg       fourb_disp;

always @(*) begin
    fourb_valid = 1;
    case (fourb_norm)
        4'b1011: begin threeb_dec=3'b000; fourb_disp=1; end
        4'b1001: begin threeb_dec=3'b001; fourb_disp=0; end
        4'b0101: begin threeb_dec=3'b010; fourb_disp=0; end
        4'b1100: begin threeb_dec=3'b011; fourb_disp=0; end
        4'b1101: begin threeb_dec=3'b100; fourb_disp=1; end
        4'b1010: begin threeb_dec=3'b101; fourb_disp=0; end
        4'b0110: begin threeb_dec=3'b110; fourb_disp=0; end
        4'b1110: begin threeb_dec=3'b111; fourb_disp=1; end
        default: begin threeb_dec=3'b000; fourb_disp=0; fourb_valid=0; end
    endcase
end

// --------------------------------------------------------
// Sequential output
// --------------------------------------------------------

wire total_disp = sixb_disp ^ fourb_disp;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= 8'b0;
        running_disparity <= 0;
        code_error <= 0;
        disparity_error <= 0;
    end
    else begin
        data_out <= {threeb_dec, fiveb_dec};

        code_error <= ~(sixb_valid & fourb_valid);

        disparity_error <= (running_disparity != total_disp);

        running_disparity <= total_disp;
    end
end

endmodule
