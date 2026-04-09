`timescale 1ns/1ps

module tb_tx_rx;

// ----------------------------------------------------
// Clock
// ----------------------------------------------------
reg clk;
reg rx_reg = 8'b0;

// ----------------------------------------------------
// Encoder signals
// ----------------------------------------------------
wire [2:0] sigXYZ;

wire [7:0] muxIn;

wire TXdata;
wire TXclk;
wire [3:0] TXsel;

wire [7:0] RXdata;
wire RXclk;

// ----------------------------------------------------
// Instantiate XYZ Generator
// ----------------------------------------------------
genXYZ DUT_XYZ (
    .clki(clk),
    .sigXYZ(sigXYZ)
);

assign muxIn = {5'b00000, sigXYZ};

// ----------------------------------------------------
// Transmitter
// ----------------------------------------------------
transmitter DUT_TX (
    .clki   (clk),
    .muxIn  (muxIn),
    .TXdata (TXdata),
    .sel    (TXsel),
    .TXclk  (TXclk)
);

// ----------------------------------------------------
// Receiver
// ----------------------------------------------------
receiver DUT_RX (
    .clki    (TXclk),
    .demuxIn (TXdata),
    .sel     (TXsel),
    .RXdata  (RXdata)
);

// ----------------------------------------------------
// Clock generation (20ns period)
// ----------------------------------------------------
initial begin
    clk = 0;
    forever #10 clk = ~clk;
end

// ----------------------------------------------------
// Dump waves
// ----------------------------------------------------
initial begin
    $dumpfile("sim/wave.vcd");
    $dumpvars(0, tb_tx_rx);
    #100000;
    $finish;
end

endmodule