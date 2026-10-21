`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 03:47:22
// Design Name: 
// Module Name: byte_packer
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module byte_packer (
    input  wire        clk, rst,
    input  wire        i_valid,
    input  wire [31:0] i_data,
    input  wire [3:0]  i_strb,
    output reg         o_valid,
    output reg  [31:0] o_data
);
    // Task 1: compaction. Valid bytes move to the lowest lanes, in order.
    reg [31:0] compact;
    reg [2:0]  n;
    integer i;
    always @(*) begin
        compact = 32'd0;
        n = 3'd0;
        for (i = 0; i < 4; i = i + 1)
            if (i_strb[i]) begin
                compact[8*n +: 8] = i_data[8*i +: 8];
                n = n + 1'b1;
            end
    end

    // Task 2: accumulation. hold = leftover bytes, cnt = how many (0 to 3).
    reg  [23:0] hold;
    reg  [1:0]  cnt;
    wire [2:0]  total  = {1'b0, cnt} + n;
    wire [55:0] merged = ({24'd0, compact} << {cnt, 3'b000}) | {32'd0, hold};

    always @(posedge clk) begin
        if (rst) begin
            hold    <= 24'd0;
            cnt     <= 2'd0;
            o_valid <= 1'b0;
            o_data  <= 32'd0;
        end else begin
            o_valid <= 1'b0;
            if (i_valid && n != 3'd0) begin
                if (total >= 3'd4) begin
                    o_valid <= 1'b1;
                    o_data  <= merged[31:0];
                    hold    <= merged[55:32];
                    cnt     <= total - 3'd4;
                end else begin
                    hold <= merged[23:0];
                    cnt  <= total[1:0];
                end
            end
        end
    end
endmodule
