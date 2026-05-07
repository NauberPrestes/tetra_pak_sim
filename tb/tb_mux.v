`timescale 1ns/1ps

module tb_tx_rx;

// ----------------------------------------------------
// Clock
// ----------------------------------------------------
reg clk = 0;
reg rx_reg = 8'b0;

// ----------------------------------------------------
// Transmitter Signals
// ----------------------------------------------------
wire [2:0] sigXYZ;
wire [7:0] MuxIn;
wire Reset = 0;
wire TXdata = 0;
wire TXclk = 0;
wire sel = 0;

// ----------------------------------------------------
// Receiver Signals
// ----------------------------------------------------
wire [7:0] RXdata = 0;

// ----------------------------------------------------
// Instantiate XYZ Generator
// ----------------------------------------------------
genXYZ DUT_XYZ (
    .clki(clk),
    .sigXYZ(sigXYZ)
);

assign MuxIn = {5'b00000, sigXYZ};

// ----------------------------------------------------
// Transmitter
// ----------------------------------------------------
transmitter tx (
    .clkIn  (clk),
    .muxIn  (MuxIn),
    .txData (TXdata),
    .txClk  (TXclk),
    .reset  (Reset)
);

// ----------------------------------------------------
// Receiver
// ----------------------------------------------------
receiver rx (
    .reset    (Reset),
    .clkIn    (TXclk),
    .demuxIn (TXdata),
    .rxData  (RXdata)
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