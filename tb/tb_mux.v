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

wire [7:0] RXdata;

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
transmitter tx (
    .clki   (clk),
    .muxIn  (muxIn),
    .TXdata (TXdata),
    .TXclk  (TXclk)
);

// ----------------------------------------------------
// Receiver
// ----------------------------------------------------
receiver rx (
    .clki    (TXclk),
    .demuxIn (TXdata),
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
    #1000000;
    $finish;
end

endmodule