`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 03:06:38
// Design Name: 
// Module Name: Tensormesh2
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


module Tensormesh2 #(
    parameter FAIR = 0
)(
    input  wire       clk, rst,
    input  wire       req_A, req_B,
    input  wire [7:0] data_A, data_B,
    output wire       grant_A, grant_B,
    output wire [7:0] out_data,
    output wire       out_valid
);
    reg  last_B;
    wire a_wins = FAIR ? last_B : 1'b1;

    assign grant_A   = req_A & (~req_B |  a_wins);
    assign grant_B   = req_B & (~req_A | ~a_wins);
    assign out_valid = grant_A | grant_B;
    assign out_data  = grant_A ? data_A : grant_B ? data_B : 8'h00;

    always @(posedge clk)
        if (rst)                    last_B <= 1'b1;
        else if (FAIR && grant_A)   last_B <= 1'b0;
        else if (FAIR && grant_B)   last_B <= 1'b1;
endmodule