`timescale 1ns/1ps

module tb_8b10b;

// --------------------------------------------------
// Testbench signals
// --------------------------------------------------

reg clk = 0;
reg rst;

wire [9:0] encoded;
wire [7:0] decoded;

wire rd_enc;
wire rd_dec;

wire code_error;
wire disparity_error;

wire [2:0] sigXYZ;
wire clockTz;

wire [7:0] data_in;

// Fix: Properly pack the signals into data_in (8 bits)
// sigXYZ[0] = X, sigXYZ[1] = Y, sigXYZ[2] = Z
assign data_in = {5'b0, sigXYZ[2], sigXYZ[1], sigXYZ[0]};  // Reversed to match typical MSB ordering

// --------------------------------------------------
// Instantiate encoder
// --------------------------------------------------

genXYZ xyz (
    .clki(clk),
    .sigXYZ(sigXYZ),
    .clockTz(clockTz)
);

encoder8b10b encoder (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .code_out(encoded),
    .running_disparity(rd_enc)
);

// --------------------------------------------------
// Instantiate decoder
// --------------------------------------------------

decoder8b10b decoder (
    .clk(clk),
    .rst(rst),
    .code_in(encoded),
    .data_out(decoded),
    .running_disparity(rd_dec),
    .code_error(code_error),
    .disparity_error(disparity_error)
);

// --------------------------------------------------
// Clock generation
// --------------------------------------------------

always #10 clk = ~clk;  // 50MHz clock

// --------------------------------------------------
// Reset and stimulus
// --------------------------------------------------

initial begin
    // Initialize
    rst = 1;
    
    // Apply reset for multiple clock cycles
    #30;
    rst = 0;
    
    // Let it run
    #100000;
    
    $display("Simulation completed");
    $display("Final comparison: data_in = %h, decoded = %h", data_in, decoded);
    $finish;
end

// --------------------------------------------------
// Monitor and compare
// --------------------------------------------------

// Monitor for errors
always @(posedge clk) begin
    if (!rst) begin
        if (code_error) 
            $display("ERROR: Code error detected at time %t", $time);
        if (disparity_error) 
            $display("ERROR: Disparity error detected at time %t", $time);
        
        // Compare after pipeline delay (encoder + decoder = 2 clock cycles)
        if ($time > 100) begin  // Wait for initial pipeline to fill
            #2;  // Small delay to avoid race conditions
            if (decoded !== data_in && !code_error && !disparity_error) begin
                $display("WARNING: Data mismatch at time %t: data_in=%h, decoded=%h", 
                         $time, data_in, decoded);
            end
        end
    end
end

// wave dump
initial begin
    $dumpfile("sim/wave.vcd");
    $dumpvars(0, tb_8b10b);
end

endmodule