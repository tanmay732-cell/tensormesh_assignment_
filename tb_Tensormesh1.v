`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 03:01:06
// Design Name: 
// Module Name: tb_Tensormesh1
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


module tb_Tensormesh1;
    reg clk = 0, rst = 1, start = 0, stop = 0;
    wire [1:0] state;
    wire [3:0] count;
    integer errors = 0;
    Tensormesh1 dut (clk, rst, start, stop, state, count);
    always #5 clk = ~clk;

    task t(input r, s, p, input [1:0] es, input [3:0] ec);
        begin
            @(negedge clk); rst = r; start = s; stop = p;
            @(posedge clk); #1;
            if (state !== es || count !== ec) begin
                errors = errors + 1;
                $display("FAIL: state=%0d count=%0d, expected %0d %0d", state, count, es, ec);
            end
        end
    endtask

    always @(posedge clk) #2
        if (state == 1 && !((16'h28AC >> count) & 1'b1)) begin
            errors = errors + 1;
            $display("FAIL: count=%0d not prime while ACTIVE", count);
        end

    initial begin
        t(1,0,0, 0,0);                       // reset
        t(0,0,0, 0,0); t(0,0,1, 0,0);        // hold in IDLE
        t(0,1,0, 1,2);                       // start loads 2
        t(0,0,0, 1,3); t(0,0,0, 1,5); t(0,0,0, 1,7);
        t(0,0,0, 1,11); t(0,0,0, 1,13);
        t(0,0,0, 1,2); t(0,0,0, 1,3);        // wrap 13 -> 2
        t(0,1,0, 1,5);                       // start ignored in ACTIVE
        t(0,0,1, 2,5);                       // stop -> DONE
        t(0,0,0, 0,5); t(0,0,0, 0,5);        // DONE -> IDLE, hold
        t(0,1,0, 1,2);                       // restart reloads 2
        t(0,1,1, 2,2); t(0,0,0, 0,2);        // stop wins over start
        t(0,1,0, 1,2); t(1,0,0, 0,0);        // reset from ACTIVE
        if (errors == 0) $display("PASS"); else $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule