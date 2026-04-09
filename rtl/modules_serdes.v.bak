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
    // 600m/min: DIV=2356
    parameter DIV = 10;
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
// (2) Transmissor
// --------------------------------------------------------

module transmitter(
    input        clk,
    input        rst,
    input  [7:0] data_in,
    input        load,
    output       TXdata,
    output       TXframe
);

reg [7:0] shift_reg = 0;
reg [2:0] bit_cnt = 0;

assign TXdata  = shift_reg[7];
assign TXframe = (bit_cnt == 3'd0);

always @(posedge clk or posedge rst)
begin
    if (rst) begin
        shift_reg <= 0;
        bit_cnt   <= 0;
    end
    else begin
        if (load) begin
            shift_reg <= data_in;
            bit_cnt   <= 0;
        end
        else begin
            shift_reg <= {shift_reg[6:0], 1'b0};
            bit_cnt   <= bit_cnt + 1;
        end
    end
end

endmodule

// --------------------------------------------------------
// (2) Receptor
// --------------------------------------------------------

module receiver(
    input        clk,
    input        rst,
    input        RXdata,
    input        RXframe,
    output reg [7:0] data_out,
    output reg       data_valid
);

reg [7:0] shift_reg;
reg [2:0] bit_cnt;
reg       receiving;

always @(posedge clk or posedge rst)
begin
    if (rst) begin
        shift_reg  <= 8'h00;
        bit_cnt    <= 3'd0;
        data_valid <= 1'b0;
        data_out   <= 8'h00;
        receiving  <= 1'b0;
    end
    else begin
        data_valid <= 1'b0;  // Default
        
        if (RXframe) begin
            // Start of new frame
            receiving <= 1'b1;
            bit_cnt <= 3'd0;
            shift_reg <= {shift_reg[6:0], RXdata};  // Store first bit
        end
        else if (receiving) begin
            // Continue receiving
            shift_reg <= {shift_reg[6:0], RXdata};
            bit_cnt <= bit_cnt + 1;
            
            if (bit_cnt == 3'd6) begin  // After 7 bits (0-6), we have 8 bits total
                data_out <= {shift_reg[6:0], RXdata};
                data_valid <= 1'b1;
                receiving <= 1'b0;
            end
        end
    end
end

endmodule
