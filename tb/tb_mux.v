`timescale 1ns/1ps

module tb_tx_rx;

// ----------------------------------------------------
// Clock
// ----------------------------------------------------
reg clk;

// ----------------------------------------------------
// Transmitter Signals
// ----------------------------------------------------
wire [2:0] sigXYZ;
wire [7:0] MuxIn;
wire Reset;
wire TXdata;
wire TXclk;

// ----------------------------------------------------
// Receiver Signals
// ----------------------------------------------------
wire [7:0] RXdata;
wire [2:0] SelRx;
wire [2:0] SelTx;

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
    //.muxIn  (MuxIn),
    .txData (TXdata),
    .txClk  (TXclk),
    .reset  (Reset),
    .sel     (SelTx)
);

// ----------------------------------------------------
// Receiver
// ----------------------------------------------------
receiver rx (
    .reset    (Reset),
    .clkIn    (TXclk),
    .demuxIn (TXdata),
    .rxData  (RXdata),
    .sel     (SelRx)
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