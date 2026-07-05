`timescale 1ns/1ps
`include "dispatcher.v"

module dispatcher_tb ();

reg clk, reset, start;
reg [7:0] thread_count;
reg [1:0] core_done;
wire [1:0] core_start, core_reset;
wire [15:0] core_block_ids;
wire [5:0] core_thread_counts;
wire done;

dispatcher #(.NUM_CORE(2), .THREADS_PER_BLOCK(4))
uut (clk, reset, start, thread_count, core_done, core_start, core_reset, core_block_ids, core_thread_counts, done);

always #5 clk = ~clk;

initial begin

    $dumpfile ("dispatcher_tb.vcd");
    $dumpvars (0,dispatcher_tb);
    clk = 0; reset = 1; start = 0;
    thread_count = 8'd11; // total threads 11 should go as 4-4-3
    core_done = 2'b00;

    #10 reset = 0;

    #10 start = 1;
    #10 start = 0;
        
    #30; // waiting so that the cores have started
    $display("Core Starts = %b (Expected: 11)", core_start);
    $display("Core 0 is running Block ID %d with %d threads", core_block_ids[7:0], core_thread_counts[2:0]); // block 0with 4 threads
    $display("Core 1 is running Block ID %d with %d threads", core_block_ids[15:8], core_thread_counts[5:3]); // block 1 with 4 threads

    #20 core_done[0] = 1; 
    #10 core_done[0] = 0; 
        
    #30; // waiting for core 0 to start again
    $display("Core 0 is running Block ID %d with %d threads", core_block_ids[7:0], core_thread_counts[2:0]); //block 2 with 3 threads

    #20 core_done[1] = 1; 
    #10 core_done[1] = 0;
        
    #20 core_done[0] = 1; 
    #10 core_done[0] = 0;
        
    #20;
    $display("TEST 3: Global GPU Done Signal = %b", done);

    #20 $finish;
end
endmodule