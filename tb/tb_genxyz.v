`timescale 1ns/1ps

module tb;

reg clk = 0;

/* encoder outputs */
wire [2:0] sigXYZ;
wire clockTz;

/* transmitter signals */
wire TXdata;
wire TXclk;

/* receiver signals */
wire [7:0] RXdata;
wire RXclk;

/* mux input */
wire [7:0] muxIn;

assign muxIn = {sigXYZ[0], sigXYZ[1], sigXYZ[2], 5'b0};

/* demux input */
wire demuxIn;

assign demuxIn = TXdata;

/* instantiate encoder generator */
genXYZ encoder (
    .clki(clk),
    .sigXYZ(sigXYZ),
    .clockTz(clockTz)
);

/* instantiate transmitter */
transmitter tx(
    .clki(clk),
    .muxIn(muxIn),
    .TXdata(TXdata),
    .TXclk(TXclk)
);

/* instantiate receiver */
receiver rx(
    .clki(clk),
    .demuxIn(demuxIn),
    .RXdata(RXdata),
    .RXclk(RXclk)
);

/* clock generator */
always #10 clk = ~clk;

/* stimulus */
initial begin

    $dumpfile("sim/wave.vcd");
    $dumpvars(0,tb);

    #1000000 $finish;

end

endmodule