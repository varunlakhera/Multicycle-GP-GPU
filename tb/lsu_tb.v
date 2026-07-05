`timescale 1ns/1ns
`include "lsu.v"
module lsu_tb();

    reg clk, reset, enable;
    reg [2:0] core_state;
    reg mem_read_enable, mem_write_enable, mem_read_ready, mem_write_ready;
    reg [7:0] rs_out, rt_out, mem_read_data;

    wire [7:0] mem_read_addr, mem_write_addr, mem_write_data, lsu_out;
    wire [1:0] lsu_state;
    wire mem_read_valid, mem_write_valid;

//localparam  IDLE = 2'b00, REQUESTING = 2'b01, WAITING = 2'b10, DONE = 2'b11;
localparam  REQUEST = 3'b011, UPDATE = 3'b110;

    lsu uut (
        .clk(clk), .reset(reset), .enable(enable),
        .core_state(core_state), .mem_read_enable(mem_read_enable), .mem_write_enable(mem_write_enable),
        .rs_out(rs_out), .rt_out(rt_out), .mem_read_data(mem_read_data),
        .mem_read_ready(mem_read_ready), .mem_write_ready(mem_write_ready),
        .mem_read_addr(mem_read_addr), .mem_write_addr(mem_write_addr), .mem_write_data(mem_write_data),
        .lsu_state(lsu_state), .lsu_out(lsu_out),
        .mem_read_valid(mem_read_valid), .mem_write_valid(mem_write_valid)
    );

always #5 clk = ~clk;

initial begin

    $dumpfile("lsu_tb.vcd");
    $dumpvars(0,lsu_tb);
    clk = 0; reset = 1; enable = 0;
    core_state = 3'b000; mem_read_enable = 0; mem_write_enable = 0;
    mem_read_ready = 0; mem_write_ready = 0;
    rs_out = 0; rt_out = 0; mem_read_data = 0;

    #10; reset = 0; enable = 1;

    core_state = REQUEST; 
    mem_read_enable = 1;
    rs_out = 8'd100; 
        
    #10; 
    $display("State=%b", lsu_state); // should be requeting 01
        
    #10; 
    $display("State=%b, ReadValid=%b, Addr=%d", 
    lsu_state, mem_read_valid, mem_read_addr); // state should be waiting 10, read valid is 1, addr = rsout
        
    #20; // random delay as mem read takes unkown amount of time

    mem_read_ready = 1;
    mem_read_data = 8'd55; // The data pulled from RAM
        
    #10; // lsu state changes
    mem_read_ready = 0;  
    $display("State=%b, Data Received=%d ",
    lsu_state, lsu_out); // data is 55, state is done 11

    #10; 
    core_state = UPDATE; // so lsu goes to idle
        
    #10; // lsustate goes DONE to IDLE
    mem_read_enable = 0;
    core_state = 3'b000; 
    $display("State=%b ", lsu_state); // should be idle 00

       
    #20;
    core_state = REQUEST;
    mem_write_enable = 1;
    rs_out = 8'd200; // Write Addr
    rt_out = 8'd88;  // Write Data
        
    #10; 
    $display("State=%b", lsu_state); // should be requsting 01
                 
    #10;  
    $display("State=%b, WriteValid=%b, Addr=%d, Data=%d", 
    lsu_state, mem_write_valid, mem_write_addr, mem_write_data);
        
    #20; // random amount of time delay
    mem_write_ready = 1;
        
    #10; 
    mem_write_ready = 0;
    $display("State=%b ", lsu_state);

    #10;
    core_state = UPDATE;
        
    #10; 
    mem_write_enable = 0;
    core_state = 3'b000;
    $display("State=%b", lsu_state);



    #20;
    $finish;
    end
endmodule