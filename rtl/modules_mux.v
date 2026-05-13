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
 
 reg [31:0] counter = 0; 
 
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
// Multiplexador 8x1
// --------------------------------------------------------

module mux(
    input  [2:0] sel,
    input  [7:0] chIn,
    input  clkIn,
    output reg chOut = 0
);

always @(posedge clkIn)
begin
    chOut = chIn[sel];
end

endmodule

// --------------------------------------------------------
// Counter Tx
// --------------------------------------------------------

module txCounter(
    input clkIn,
    output reg [2:0] sel = 0
);

always @(posedge clkIn) begin
    sel <= sel + 1;
end

endmodule

// --------------------------------------------------------
// Demultiplexador 8x1
// --------------------------------------------------------

module demux(
    input  [2:0] sel,
    input  chIn,
    input  clkIn,
    output reg [7:0] chOut = 0
);

always @ (negedge clkIn)
begin
    case(sel)
    0: chOut[0] <= chIn;
    1: chOut[1] <= chIn;
    2: chOut[2] <= chIn;
    3: chOut[3] <= chIn;
    4: chOut[4] <= chIn;
    5: chOut[5] <= chIn;
    6: chOut[6] <= chIn;
    7: chOut[7] <= chIn;
    endcase
end

endmodule

// --------------------------------------------------------
// Counter Rx
// --------------------------------------------------------

module rxCounter(
    input clkIn,
    input reset,
    output reg [2:0] sel = 0
);

always @(negedge reset) begin
    sel <= 0;
end

always @(negedge clkIn) begin
    sel <= sel + 1;
end

endmodule

// --------------------------------------------------------
// Sync
// --------------------------------------------------------

module sync(
    input [2:0] selTx,
    input clkTx,
    output reg reset = 0
);

    always @(clkTx) begin
        if (!selTx & clkTx) begin
            reset = 1;
        end
        else if (!clkTx) begin
            reset = 0;
        end
    end

endmodule

// --------------------------------------------------------
// Transmissor
// --------------------------------------------------------

module transmitter(
    input clkIn,
    //input [7:0] muxIn,
    output txData,
    output txClk,
    output reset
);

wire [2:0] sel;
wire [2:0] muxIn;

txCounter TxCounter(
    .clkIn(clkIn),
    .sel(sel)
);

genXYZ GenXYZ(
    .clki(clkIn),
    .sigXYZ(muxIn)
);

mux Mux(
    .sel(sel),
    .clkIn(clkIn),
    .chIn({5'b00000, muxIn}),
    .chOut(txData)
);

sync Sync(
    .selTx(sel),
    .clkTx(clkIn),
    .reset(reset)
);

assign txClk = clkIn;

endmodule

// --------------------------------------------------------
// (2) Receiver
// --------------------------------------------------------

module receiver(
    input        clkIn,
    input        demuxIn,
    input        reset,
    output [7:0] rxData,
    // Tb signals
    output [2:0] sel
);

rxCounter RxCounter(
    .clkIn(clkIn),
    .reset(reset),
    .sel(sel)
);

demux Demux(
    .sel(sel),
    .clkIn(clkIn),
    .chIn(demuxIn),
    .chOut(rxData)
);

endmodule
/*
// -------------------------------------------------------- 
// (3) kitDE0
// ------------------------------------------------------
module kitDE0 ( 
    input CLOCK_50, 
    output [14:0] GPIO1_D,
	 input [7:0] GPIO0_D
); 

    wire [31:0] clockVector; 
    wire [7:0] muxIn; 
    wire [2:0] sigXYZ; 
	 wire [7:0] rxData;
	 wire txClk;
	 wire txData;

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
    .TXdata (txdata),
    .TXclk  (txclk)
);

		receiver rx1(
			 .clki    (txclk),
			 .demuxIn (txdata),
			 .RXdata  (rxdata)
		);
		assign muxIn = {5'b00000, sigXYZ};

		assign GPIO1_D[0] = sigXYZ[0]; 
		assign GPIO1_D[1] = sigXYZ[1]; 
		assign GPIO1_D[2] = sigXYZ[2]; 
	 
		assign GPIO1_D[3] = txData;
		assign GPIO1_D[4] = txClk;
		assign GPIO1_D[12:5] = rxData;
	
endmodule*/