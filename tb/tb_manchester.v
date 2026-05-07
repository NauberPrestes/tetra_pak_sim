`timescale 1ns/1ps

module tb_tx_rx;

// ----------------------------------------------------
// Clocks
// ----------------------------------------------------
reg clk_bit;     // bit-rate clock
reg clk_2x;      // 2x clock for Manchester decoding

reg start = 1;

// ----------------------------------------------------
// Signals
// ----------------------------------------------------
wire [2:0] sigXYZ = 0;
wire [7:0] tx_data = 0;
wire [7:0] rx_data = 0;

wire tx_line = 0;    // Manchester encoded serial line

// ----------------------------------------------------
// Instantiate XYZ Generator
// ----------------------------------------------------
genXYZ DUT_XYZ (
    .clki(clk_bit),
    .sigXYZ(sigXYZ)
);

// Pack into 8-bit frame
assign tx_data = {5'b00000, sigXYZ};

// ----------------------------------------------------
// Transmitter (Serializer + Manchester Encoder)
// ----------------------------------------------------
transmitter DUT_TX (
    .clk_bit    (clk_bit),
    .start   (start),
    .data_in(tx_data),
    .tx_out (tx_line)
);

// ----------------------------------------------------
// Receiver (Manchester Decoder + Deserializer)
// ----------------------------------------------------
receiver DUT_RX (
    .clk_2x   (clk_2x),
    .rx_in    (tx_line),
    .data_out (rx_data)
);

// ----------------------------------------------------
// Clock generation
// ----------------------------------------------------

// Bit clock (20 ns period)
initial begin
    clk_bit = 0;
    forever #10 clk_bit = ~clk_bit;
end

// 2x clock (10 ns period)
initial begin
    clk_2x = 0;
    forever #5 clk_2x = ~clk_2x;
end

// ----------------------------------------------------
// Frame sync (load pulse every 8 bits)
// ----------------------------------------------------

initial begin
    start = 0;

    #100;
    start = 1;
    @(posedge clk_bit);
    start = 0;

    // periodic transmissions
    forever begin
        #5000;
        start = 1;
        @(posedge clk_bit);
        start = 0;
    end
end

// ----------------------------------------------------
// Dump waves
// ----------------------------------------------------
initial begin
    $dumpfile("sim/wave.vcd");
    $dumpvars(0, tb_tx_rx);

    #200000;
    $finish;
end

endmodule