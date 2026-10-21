`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 03:50:02
// Design Name: 
// Module Name: tb_byte_packer
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


module tb_byte_packer;
    reg         clk = 0, rst = 1, i_valid = 0;
    reg  [31:0] i_data = 0;
    reg  [3:0]  i_strb = 0;
    wire        o_valid;
    wire [31:0] o_data;

    byte_packer dut (clk, rst, i_valid, i_data, i_strb, o_valid, o_data);
    always #5 clk = ~clk;

    reg [7:0]  qb [0:15];
    integer    qn = 0, errors = 0, j, k;
    reg        exp_v;
    reg [31:0] exp_w;

    task model(input v, input [31:0] d, input [3:0] s);
        begin
            exp_v = 0;
            if (v)
                for (j = 0; j < 4; j = j + 1)
                    if (s[j]) begin qb[qn] = d[8*j +: 8]; qn = qn + 1; end
            if (qn >= 4) begin
                exp_v = 1;
                exp_w = {qb[3], qb[2], qb[1], qb[0]};
                for (j = 4; j < 16; j = j + 1) qb[j-4] = qb[j];
                qn = qn - 4;
            end
        end
    endtask

    task send(input v, input [31:0] d, input [3:0] s);
        begin
            @(negedge clk);
            i_valid = v; i_data = d; i_strb = s;
            model(v, d, s);
            @(posedge clk); #1;
            if (o_valid !== exp_v || (exp_v && o_data !== exp_w)) begin
                errors = errors + 1;
                $display("FAIL: o_valid=%b o_data=%h, expected %b %h", o_valid, o_data, exp_v, exp_w);
            end
        end
    endtask

    task reset_dut;
        begin
            @(negedge clk); rst = 1; i_valid = 0; qn = 0;
            @(posedge clk); #1;
            if (o_valid !== 1'b0) begin errors = errors + 1; $display("FAIL: o_valid after reset"); end
            @(negedge clk); rst = 0;
        end
    endtask

    task expect_word(input [31:0] w, input [255:0] msg);
        begin
            if (o_valid !== 1'b1 || o_data !== w) begin
                errors = errors + 1;
                $display("FAIL %0s: o_valid=%b o_data=%h, expected %h", msg, o_valid, o_data, w);
            end
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst = 0; qn = 0;

        // all four bytes valid
        send(1, 32'hA3A2A1A0, 4'b1111);
        expect_word(32'hA3A2A1A0, "all valid");

        // one byte valid, four times
        send(1, 32'h11, 4'b0001); send(1, 32'h22, 4'b0001);
        send(1, 32'h33, 4'b0001); send(1, 32'h44, 4'b0001);
        expect_word(32'h44332211, "one byte x4");

        // mix: 0101 then 1010
        send(1, 32'hAABBCCDD, 4'b0101);
        send(1, 32'h11223344, 4'b1010);
        expect_word(32'h1133BBDD, "mix 0101 / 1010");

        // example from the assignment
        send(1, 32'h00001110, 4'b0011);              // D0 = 10, D1 = 11
        send(1, 32'h17161514, 4'b1111);              // D4..D7
        expect_word(32'h15141110, "example first word");
        send(1, 32'h00001918, 4'b0011);              // D8, D9
        expect_word(32'h19181716, "example leftovers D6 D7");

        // several inputs in a row with leftovers carried across words
        repeat (4) send(1, $random, 4'b0111);

        // valid low with a nonzero strobe, and valid high with strobe 0
        send(0, 32'hDEADBEEF, 4'b1111);
        send(1, 32'hDEADBEEF, 4'b0000);

        // reset drops leftover bytes
        send(1, 32'h000000AA, 4'b0001);
        reset_dut;
        send(1, 32'hD4C3B2A1, 4'b1111);
        expect_word(32'hD4C3B2A1, "reset clears leftovers");

        // random traffic
        for (k = 0; k < 5000; k = k + 1) send($random, $random, $random);

        if (errors == 0) $display("PASS: all checks passed");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule