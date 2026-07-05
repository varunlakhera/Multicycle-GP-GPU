`timescale 1ps/1ps

`include "pc.v"
module pc_tb;

reg clk, reset, enable;
reg [2:0] core_state;
reg nzp_write_enable, pc_out_mux;
reg [7:0] current_pc, immediate;
reg [2:0] nzp_inst, nzp_out;

wire [7:0] new_pc;


pc uut (clk, reset, enable, core_state, nzp_write_enable, pc_out_mux, current_pc,
 immediate, nzp_inst, nzp_out, new_pc);

 always #5 clk = ~clk;

 initial begin
    $dumpfile("pc_tb.vcd");
    $dumpvars(0, pc_tb);

    clk = 0; reset = 1; enable = 0;
    core_state = 0; nzp_write_enable = 0;
    pc_out_mux = 0; current_pc = 8'd10;
    immediate = 8'd53; nzp_inst = 0; nzp_out = 0;

    #20;
    reset = 0;
    enable = 1;

    $display("NORMAL_INCREMENT");
    core_state = 3'b101;
    #10;
    $display("Current PC : %d | New PC Calculated : %d", current_pc, new_pc);

    $display("updating nzp with nzp_out(001)");
    core_state = 3'b110;
    nzp_out = 3'b001;
    nzp_write_enable = 1;
    #10;
    nzp_write_enable = 0;
    $display("Branch evaluates to true");
    core_state = 3'b101;
    pc_out_mux = 1;
    nzp_inst = 3'b011; // greater or equal
    #10;
    $display("BRANCH JUMP, newPC calculates : %d (exp : 53)", new_pc);
    $display("branch evaluates to false");
    core_state = 3'b101;
    pc_out_mux = 1;
    nzp_inst = 3'b110;
    #10;
    $display("BRANCH JUMP FALSE, newPC  : %d (exp : 11)", new_pc);

    #20 $finish;
 end



endmodule