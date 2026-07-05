`timescale 1ns/1ps
`include "fetcher.v"

module fetcher_tb();

reg clk, reset, mem_read_ready;
reg [2:0] core_state;
reg [7:0] current_pc;
reg [15:0] mem_read_data;
wire [15:0] instruction;
wire [7:0] mem_read_addr;
wire [2:0] fetcher_state;
wire mem_read_valid;

localparam FETCH = 3'b001, DECODE = 3'b010; 

fetcher uut (clk, reset, mem_read_ready, core_state, current_pc, mem_read_data, instruction, mem_read_addr, fetcher_state, mem_read_valid);

always #5 clk = ~clk;

initial begin

    $dumpfile("fetcher_tb.vcd");
    $dumpvars(0,fetcher_tb);
    clk = 0; reset = 1; mem_read_ready = 0;
    core_state = 3'b000; current_pc = 8'd0; mem_read_data = 16'h0000;
        
    #10; reset = 0;

    #10;
    core_state = FETCH;
    current_pc = 8'd42;
        
    #10;
    $display("State = %b, mem_read_valid = %b, Addr = %d",  
    fetcher_state, mem_read_valid, mem_read_addr);

    #20; // random delay to fetche instruction  form memory
    mem_read_ready = 1;
    mem_read_data = 16'hABCD; 
    
    #10;
    mem_read_ready = 0; 
    $display("State = %b, Instruction: %h", 
    fetcher_state, instruction);
    
    #10;
    core_state = DECODE;
    
    #10;
    $display("State  = %b", fetcher_state);

    #20;
    $finish;
end

endmodule