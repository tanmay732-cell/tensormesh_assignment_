`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 02:57:11
// Design Name: 
// Module Name: Tensormesh1
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
module Tensormesh1 (
    input  wire       clk, rst, start, stop,
    output reg  [1:0] state,
    output reg  [3:0] count
);
    localparam [1:0] IDLE = 2'd0, ACTIVE = 2'd1, DONE = 2'd2;
    reg [1:0] ns;

    always @(posedge clk) state <= rst ? IDLE : ns;

    always @(*)
        case (state)
            IDLE:    ns = start ? ACTIVE : IDLE;
            ACTIVE:  ns = stop  ? DONE   : ACTIVE;
            default: ns = IDLE;
        endcase

    always @(posedge clk)
        if (rst) count <= 0;
        else if (state == IDLE && start) count <= 2;
        else if (state == ACTIVE && !stop)
            count <= (count == 2) ? 3 : (count == 3) ? 5 : (count == 5) ? 7 :
                     (count == 7) ? 11 : (count == 11) ? 13 : 2;
endmodule