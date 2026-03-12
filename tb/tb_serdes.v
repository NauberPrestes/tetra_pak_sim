`timescale 1ns/1ps

module tb_tx_rx;

reg         clk;
    reg         rst;
    wire [2:0]  sigXYZ;
    wire        TXdata;
    wire        TXframe;
    wire [7:0]  RX_data_out;
    wire        RX_data_valid;
    
    reg  [7:0]  tx_data_in;
    reg         tx_load;
    
    integer     cycle_count;
    reg  [7:0]  test_vectors [0:7];
    integer     i;
    
    parameter CLK_PERIOD = 20;
    
    // Instantiate all modules
    genXYZ u_genXYZ (
        .clki(clk), 
        .sigXYZ(sigXYZ)
    );

    transmitter u_transmitter (
        .clk(clk), 
        .rst(rst), 
        .data_in(tx_data_in),                
        .load(tx_load), 
        .TXdata(TXdata), 
        .TXframe(TXframe)
    );

    receiver u_receiver (
        .clk(clk), 
        .rst(rst), 
        .RXdata(TXdata), 
        .RXframe(TXframe),
        .data_out(RX_data_out), 
        .data_valid(RX_data_valid)
    );
    
    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Main test process
    initial begin
        clk = 0;
        rst = 1;
        tx_load = 0;
        cycle_count = 0;
        
        #(CLK_PERIOD * 3);
        rst = 0;
        #(CLK_PERIOD * 2);
        
        // Test with sigXYZ as data source for multiple cycles
        $display("\n--- Testing with sigXYZ data for multiple encoder cycles ---\n");
        
        for (i = 0; i < 20; i = i + 1) begin
            // Sample sigXYZ at different points
            #(CLK_PERIOD * 5);
            
            tx_data_in = {5'b00000, sigXYZ};
            tx_load = 1;
            #(CLK_PERIOD);
            tx_load = 0;
            
            #(CLK_PERIOD * 5);
        end
        
        #(CLK_PERIOD * 20);
        $finish;
    end

initial begin
    $dumpfile("sim/wave.vcd");
    $dumpvars(0, tb_tx_rx);
end

endmodule