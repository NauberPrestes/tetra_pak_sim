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

module tx_framer (
    input        clk_bit,
    input        start,
    input  [7:0] payload,
    output reg   bit_out,
    output reg   busy
);

    reg [4:0] bit_cnt = 0;
    reg [23:0] frame = 0; // 8 + 8 + 8

    localparam PREAMBLE = 8'b10101010;
    localparam SYNC     = 8'b11010011;

    always @(posedge clk_bit) begin
        if (start && !busy) begin
            frame <= {PREAMBLE, SYNC, payload};
            bit_cnt <= 0;
            busy <= 1;
        end 
        else if (busy) begin
            bit_out <= frame[23];
            frame <= {frame[22:0], 1'b0};
            bit_cnt <= bit_cnt + 1;

            if (bit_cnt == 23) begin
                busy <= 0;
            end
        end
    end
endmodule

module manchester_encoder (
    input clk,       // Data rate clock
    input nrz_in,    // NRZ Data In
    output man_out   // Manchester Encoded Data Out
);
    // IEEE 802.3 convention: XOR clock and data
    assign man_out = clk ^ nrz_in;
endmodule

// --------------------------------------------------------
// (1) Demultiplexador 8x1
// --------------------------------------------------------

module rx_framer (
    input        clk,
    input        bit_in,
    input        bit_valid,
    output reg [7:0] payload,
    output reg       data_valid
);

    reg [7:0] shift = 0;
    reg [4:0] count = 0;

    localparam SYNC = 8'b11010011;

    always @(posedge clk) begin
        data_valid <= 0;

        if (bit_valid) begin
            shift <= {shift[6:0], bit_in};

            // detect sync word
            if (shift == SYNC) begin
                count <= 0;
            end
            else if (count < 8) begin
                count <= count + 1;
                payload <= {payload[6:0], bit_in};

                if (count == 7) begin
                    data_valid <= 1;
                end
            end
        end
    end
endmodule

module manchester_decoder_sync (
    input        clk_2x,
    input        man_in,
    output reg   bit_out,
    output reg   bit_valid
);

    reg [2:0] shift = 0;

    always @(posedge clk_2x) begin
        shift <= {shift[1:0], man_in};

        // edge detection
        if (shift[2] ^ shift[1]) begin
            bit_out <= shift[2];   // sample before transition
            bit_valid <= 1;
        end else begin
            bit_valid <= 0;
        end
    end
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

module transmitter (
    input        clk_bit,
    input        start,
    input  [7:0] data_in,
    output       tx_out
);

    wire serial_bit;

    tx_framer framer (
        .clk_bit(clk_bit),
        .start(start),
        .payload(data_in),
        .bit_out(serial_bit),
        .busy()
    );

    manchester_encoder enc (
        .clk(clk_bit),
        .nrz_in(serial_bit),
        .man_out(tx_out)
    );

endmodule

// --------------------------------------------------------
// (2) Receiver with Manchester Decoding
// --------------------------------------------------------

module receiver (
    input        clk_2x,
    input        rx_in,
    output [7:0] data_out,
    output       data_valid
);

    wire bit;
    wire bit_valid;

    manchester_decoder_sync dec (
        .clk_2x(clk_2x),
        .man_in(rx_in),
        .bit_out(bit),
        .bit_valid(bit_valid)
    );

    rx_framer framer (
        .clk(clk_2x),
        .bit_in(bit),
        .bit_valid(bit_valid),
        .payload(data_out),
        .data_valid(data_valid)
    );

endmodule

// ========================================================
// Top-Level Entity for Altera Cyclone III FPGA
// Testbench in real hardware for:
// - Encoder XYZ generator
// - Manchester TX/RX
// ========================================================
//
// Suggested connections:
// CLOCK_50  -> 50 MHz onboard oscillator
// KEY[0]    -> Reset / Start button
// LEDG[]    -> Debug LEDs
// GPIO[]    -> External probing with oscilloscope / logic analyzer
//
// ========================================================

module top_cyclone3 (

    // --------------------------------------------
    // FPGA CLOCK
    // --------------------------------------------
    input         CLOCK_50,

    // --------------------------------------------
    // Push buttons
    // --------------------------------------------
    input   [3:0] KEY,

    // --------------------------------------------
    // LEDs
    // --------------------------------------------
    output  [7:0] LEDG,
    output  [7:0] LEDR,

    // --------------------------------------------
    // GPIO Header
    // --------------------------------------------
    output [35:0] GPIO1_D
);

// ========================================================
// Internal clocks
// ========================================================

wire [31:0] clk_div;

// clock divider chain
clockDiv2n div2n_inst (
    .clki (CLOCK_50),
    .clko (clk_div)
);

// Select slower clocks for visualization/debug
wire clk_bit = clk_div[15];   // TX clock
wire clk_2x  = clk_div[14];   // 2x RX clock

// ========================================================
// XYZ encoder signal generator
// ========================================================

wire [2:0] xyz;

genXYZ xyz_gen (
    .clki   (CLOCK_50),
    .sigXYZ (xyz)
);

// ========================================================
// Transmission system
// ========================================================

wire tx_line;

transmitter tx_inst (
    .clk_bit (clk_bit),
    .start   (~KEY[0]),     // active low pushbutton
    .data_in ({5'b00000, xyz}),
    .tx_out  (tx_line)
);

// ========================================================
// Receiver system
// ========================================================

wire [7:0] rx_data;
wire       rx_valid;

receiver rx_inst (
    .clk_2x    (clk_2x),
    .rx_in     (tx_line),
    .data_out  (rx_data),
    .data_valid(rx_valid)
);

// ========================================================
// LEDs
// ========================================================

// XYZ generator
assign LEDG[0] = xyz[0];   // X
assign LEDG[1] = xyz[1];   // Y
assign LEDG[2] = xyz[2];   // Z

// TX/RX debug
assign LEDG[3] = tx_line;
assign LEDG[4] = rx_valid;

// Received data
assign LEDR = rx_data;

// ========================================================
// GPIO outputs for oscilloscope / logic analyzer
// ========================================================

assign GPIO1_D[0] = clk_bit;
assign GPIO1_D[1] = clk_2x;

assign GPIO1_D[2] = xyz[0];
assign GPIO1_D[3] = xyz[1];
assign GPIO1_D[4] = xyz[2];

assign GPIO1_D[5] = tx_line;

assign GPIO1_D[6] = rx_valid;

assign GPIO1_D[14:7] = rx_data;

// Unused GPIO
assign GPIO1_D[35:15] = 0;

endmodule