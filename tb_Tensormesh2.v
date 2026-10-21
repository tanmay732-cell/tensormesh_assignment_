`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.10.2026 03:09:35
// Design Name: 
// Module Name: tb_Tensormesh2
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


module tb_Tensormesh2;
    reg        clk = 0, rst = 1, req_A = 0, req_B = 0;
    reg  [7:0] data_A = 0, data_B = 0;
    wire       gA1, gB1, gA2, gB2, v1, v2;
    wire [7:0] d1, d2;

    Tensormesh2 #(.FAIR(0)) u1 (clk, rst, req_A, req_B, data_A, data_B, gA1, gB1, d1, v1);
    Tensormesh2 #(.FAIR(1)) u2 (clk, rst, req_A, req_B, data_A, data_B, gA2, gB2, d2, v2);

    always #5 clk = ~clk;

    integer errors = 0, i, nA1 = 0, nB1 = 0, nA2 = 0, nB2 = 0;
    reg mlastB = 1, count_on = 0, pgB = 0;

    task fail(input [255:0] msg);
        begin errors = errors + 1; $display("FAIL: %0s (t=%0t)", msg, $time); end
    endtask

    task chk(input ra, rb);
        reg eA1, eB1, eA2, eB2;
        begin
            eA1 = ra;  eB1 = rb & ~ra;
            if (ra && rb) begin eA2 = mlastB; eB2 = ~mlastB; end
            else          begin eA2 = ra;     eB2 = rb;      end

            if (gA1 !== eA1 || gB1 !== eB1) fail("V1 wrong grant");
            if (gA2 !== eA2 || gB2 !== eB2) fail("V2 wrong grant");

            if (gA1 && gB1) fail("V1 both grants high");
            if (gA2 && gB2) fail("V2 both grants high");
            if (gA1 && d1 !== data_A) fail("V1 out_data != data_A");
            if (gB1 && d1 !== data_B) fail("V1 out_data != data_B");
            if (gA2 && d2 !== data_A) fail("V2 out_data != data_A");
            if (gB2 && d2 !== data_B) fail("V2 out_data != data_B");
            if (v1 !== (gA1 | gB1)) fail("V1 out_valid");
            if (v2 !== (gA2 | gB2)) fail("V2 out_valid");

            if (eA2) mlastB = 0; else if (eB2) mlastB = 1;
            if (count_on) begin
                nA1 = nA1 + gA1; nB1 = nB1 + gB1;
                nA2 = nA2 + gA2; nB2 = nB2 + gB2;
            end
        end
    endtask

    task cyc(input ra, rb);
        begin
            @(negedge clk);
            req_A = ra; req_B = rb; data_A = $random; data_B = $random;
            #1; chk(ra, rb);
        end
    endtask

    initial begin
        repeat (2) @(negedge clk);
        rst = 0; mlastB = 1;

        cyc(1,0); cyc(1,0);                  // A alone
        cyc(0,1); cyc(0,1);                  // B alone
        cyc(0,0); cyc(0,0);                  // neither
        cyc(1,1);                            // both together

        for (i = 0; i < 12; i = i + 1) begin // both held: V2 must alternate
            cyc(1,1);
            if (i > 0 && gB2 === pgB) fail("V2 did not alternate");
            pgB = gB2;
        end

        count_on = 1;                        // both held for 20 cycles
        for (i = 0; i < 20; i = i + 1) cyc(1,1);
        count_on = 0;
        $display("20 cycles, both requesting:");
        $display("  V1 fixed : A=%0d B=%0d", nA1, nB1);
        $display("  V2 fair  : A=%0d B=%0d", nA2, nB2);
        if (nB1 !== 0 || nA1 !== 20) fail("V1 starvation count");
        if (nA2 !== 10 || nB2 !== 10) fail("V2 fairness count");

        for (i = 0; i < 2000; i = i + 1) cyc($random, $random);

        if (errors == 0) $display("PASS: all checks passed");
        else             $display("FAIL: %0d errors", errors);
        $finish;
    end
endmodule
