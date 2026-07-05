// we are testing the following: 
// testing all the operations : 
//ADD, SUB, MUL, DIV
// DIv by 0  
// checking what happens when core_state is not EXECUTE


`timescale 1ns/1ps
`include "alu.v"

module alu_tb();

reg clk, reset, enable;
reg [7:0] rs, rt;
reg [1:0] alu_op;
reg [2:0] core_state;

wire [7:0] alu_out;
wire [2:0] alu_nzp;

localparam  ADD = 2'b00, SUB = 2'b01, MUL = 2'b10, DIV = 2'b11, EXECUTE = 3'b101;

alu uut (clk, reset, enable, rs, rt, alu_op, core_state, alu_out, alu_nzp);

always #5 clk = ~clk;

initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars(0,alu_tb);

    clk = 0; reset = 1; enable = 0; core_state = 3'b000;
    rs = 0; rt = 0; alu_op = 0;

    #20;
    reset = 0; enable = 1;

    core_state = EXECUTE; 
    alu_op = ADD;
    rs = 8'd10; rt = 8'd5;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    alu_op = SUB;
    rs = 8'd30; rt = 8'd22;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    alu_op = MUL;
    rs = 8'd4; rt = 8'd60;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    alu_op = DIV;
    rs = 8'd30; rt = 8'd6;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    alu_op = DIV;
    rs = 8'd30; rt = 8'd20;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    alu_op = DIV;
    rs = 8'd6; rt = 8'd6;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp); // RS == RT

    alu_op = DIV;
    rs = 8'd30; rt = 8'd0;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    core_state = 3'b111;
    alu_op = ADD;
    rs = 8'd10; rt = 8'd99;
    #10;
    $display("alu_out = %d and NZP = %b", alu_out, alu_nzp);

    #20;
    $finish;
end
endmodule
