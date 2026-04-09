// ========================================================
// Tetra Pak Project:
// Encoder signal generator modules (X, Y, Z)
// 8 bit mux and demux modules
// Vrsion for simulation with Icarus + Make + GTKWave
// ========================================================

// --------------------------------------------------------
// (1) clock divider geração da base de tempo dos sinais X Y Z
// --------------------------------------------------------

// --------------------------------------------------------
// (1) clock divider geração da base de tempo dos sinais X Y Z
// --------------------------------------------------------

module clockDivider1(
    input clki,
    output clko);

    // Clock para o parâmetro Tz. Lembrando que Tx=4.Tz
    // 450m/min: DIV=3141
    // 600m/min: DIV=2356 1178
    parameter DIV = 1178;
    reg [11:0] count = 0;
    reg out = 0;

    always@(posedge clki) begin
        if( count == DIV ) begin
            count <= 0;
            out <= ~out;
        end
        else count <= count+1;
    end

    assign clko = out;
endmodule

// -------------------------------------------------------- 
// Clock divider 2^n
 // -------------------------------------------------------
 module clockDiv2n( 
	 input clki, 
	 output reg [31:0] clko 
 ); 
 
 reg [31:0] counter; 
 
 always@(posedge clki) 
	 begin counter <= counter + 1; 
	 clko <= counter; 
 end 
 
 endmodule

// --------------------------------------------------------
// (1) Gerador dos sinais X e Y do encoder (500 pulsos por volta)
// --------------------------------------------------------

module genXY(input clkTz, output X, Y );
    reg outX = 0;
    reg outY = 0;
    reg [1:0] count = 0;

    always@(posedge clkTz) count <= count + 1;

    always@(count) begin
        case(count)
        0: begin outX <= 1'b1; outY <= 1'b0; end
        1: begin outX <= 1'b1; outY <= 1'b1; end
        2: begin outX <= 1'b0; outY <= 1'b1; end
        3: begin outX <= 1'b0; outY <= 1'b0; end
        endcase
    end

    assign X = outX;
    assign Y = outY;
endmodule

// --------------------------------------------------------
// (1) Geração do sinal do canal Z (um pulso por volta)
// --------------------------------------------------------

module genZ(input clkTz, output Z);
    reg outZ = 0;
    reg [10:0] i = 0;

    always@(posedge clkTz) begin
        if(i==1999) begin
            i<=0;
            outZ<=1'b1; end
        else begin
            i<=i+1;
            outZ<=1'b0; end
    end

    assign Z = outZ;
endmodule

// --------------------------------------------------------
// (2) Módulo gerador de sinais (X,Y,Z)
// --------------------------------------------------------

module genXYZ (
    input clki,
    output [2:0] sigXYZ
);
    wire clkTz;

    clockDivider1 clkdiv1(
        .clki (clki),
        .clko (clkTz)
    );

    genXY genXY1(
        .clkTz(clkTz),
        .X    (sigXYZ[0]),
        .Y    (sigXYZ[1])
    );

    genZ genZ1(
        .clkTz(clkTz),
        .Z    (sigXYZ[2])
    );
endmodule

// --------------------------------------------------------
// (1) Multiplexador 8x1
// --------------------------------------------------------

module mux(
    input  [2:0] sel,
    input  [7:0] ch_in,
    input  clki, // talvez tenha que inverter
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
    input  clki, // talvez tenha que inverter
    output reg [7:0] ch_out = 0
);

//assign ch_out = ch_in << sel;
always @ (negedge clki)
begin
    case(sel)
    0: ch_out[0] <= ch_in;
    1: ch_out[1] <= ch_in;
    2: ch_out[2] <= ch_in;
    3: ch_out[3] <= ch_in;
    4: ch_out[4] <= ch_in;
    5: ch_out[5] <= ch_in;
    6: ch_out[6] <= ch_in;
    7: ch_out[7] <= ch_in;
    endcase
end
 // high speed opto-coupler IC
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
    output [2:0] sel,
    output TXclk
);

counter8 cnt2(
    .clki(clki),
    .sel(sel)
);

mux mux1(
    .sel(sel),
    .clki(clki),
    .ch_in(muxIn),
    .ch_out(TXdata)
);

assign TXclk = clki;

endmodule

// --------------------------------------------------------
// (2) Receiver
// --------------------------------------------------------

module receiver(
    input        clki,
    input        demuxIn,
    input  [2:0] sel,
    output [7:0] RXdata
);

demux demux1(
    .sel(sel),
    .clki(clki),
    .ch_in(demuxIn),
    .ch_out(RXdata)  // Direct connection to stable output
);

endmodule

// -------------------------------------------------------- 
// (3) kitDE0
// ------------------------------------------------------
/*module kitDE0 ( 
    input CLOCK_50, 
    output [7:0] GPIO1_D
); 

    wire [31:0] clockVector; 
    wire [7:0] muxIn; 
    wire [2:0] sigXYZ; 
    wire [2:0] sel_wire;

    assign muxIn = {5'b00000, sigXYZ};

    assign GPIO1_D[0] = sigXYZ[0]; 
    assign GPIO1_D[1] = sigXYZ[1]; 
    assign GPIO1_D[2] = sigXYZ[2]; 

    clockDiv2n clkdiv2( 
        .clki (CLOCK_50), 
        .clko (clockVector)
    ); 

    genXYZ genXYZ1( 
        .clki (CLOCK_50), 
        .sigXYZ (sigXYZ)
    ); 

    transmitter tx1(
        .clki   (clockVector[1]), 
        .muxIn  (muxIn), 
        .TXdata (GPIO1_D[3]), 
        .sel    (sel_wire),
        .TXclk  (GPIO1_D[4])
    ); 

    assign GPIO1_D[5] = sel_wire[0];
	 assign GPIO1_D[6] = sel_wire[1];
	 assign GPIO1_D[7] = sel_wire[2];
	
endmodule
 
 // -------------------------------------------------------- 
// (3) kitDE1
 // --------------------------------------------------------
module kitDE1 ( 
    input [7:0] GPIO1_D,
    output [7:0] GPIO0_D
); 

    wire TXdata = GPIO1_D[3];
    wire TXclk  = GPIO1_D[4];

    wire [2:0] sel;
    assign sel[0] = GPIO1_D[5];
    assign sel[1] = GPIO1_D[6];
    assign sel[2] = GPIO1_D[7];

    wire [7:0] rxdata;

    receiver rx1(
        .clki    (TXclk), 
        .demuxIn (TXdata), 
        .sel     (sel),
        .RXdata  (rxdata), 
        .RXclk   ()
    ); 

    assign GPIO0_D = rxdata;

endmodule*/