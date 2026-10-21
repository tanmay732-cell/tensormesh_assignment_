`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 03:36:22
// Design Name: 
// Module Name: arbiter_fixed
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


module arbiter_fixed (
    input  wire       clk, rst,
    input  wire       req_A, req_B,
    input  wire [7:0] data_A, data_B,
    output wire       grant_A, grant_B,
    output wire [7:0] out_data,
    output wire       out_valid
);
    assign grant_A   = req_A;
    assign grant_B   = req_B & ~req_A;
    assign out_valid = grant_A | grant_B;
    assign out_data  = grant_A ? data_A : grant_B ? data_B : 8'h00;
endmodule
