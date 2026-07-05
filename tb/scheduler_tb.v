`timescale 1ns/1ps
`include "scheduler.v"

module scheduler_tb();

reg clk, reset,start, mem_read_enable, mem_write_enable, decoded_return;
reg [2:0] fetcher_state;
reg [7:0] lsu_states;
reg [7:0] new_pc;
wire [2:0] core_state;
wire [7:0] current_pc;
wire done;

scheduler #(.THREADS_PER_BLOCK(4))
uut(clk, reset,start, mem_read_enable, mem_write_enable, decoded_return, fetcher_state, lsu_states, new_pc, core_state, current_pc, done);

always #5 clk = ~clk;

initial begin

$dumpfile("scheduler_tb.vcd");
$dumpvars(0,scheduler_tb);
    
clk = 0; reset = 1; start = 0; mem_read_enable = 0; mem_write_enable = 0; decoded_return = 0;
fetcher_state = 3'b000; lsu_states = 8'b00000000;
new_pc = 8'd42; // random

#10;
reset = 0;

#10 start = 1;
#10 start = 0;
$display("State = %b", core_state);//should be fetch
    
#10 fetcher_state = 3'b100; 
#10 fetcher_state = 3'b000; 
$display("State = %b", core_state);//decoede

#10;
$display("State = %b ", core_state); // request
        
#10;
$display("State = %b ", core_state); // goes to ececute wo going to wait

#10;
$display(" State = %b ", core_state);//update
    
#10;
$display("State = %b, PC = %d", core_state, current_pc); // state is fetch , pc is --

fetcher_state = 3'b100; 
#10;
fetcher_state = 3'b000;
        
#10;
mem_read_enable = 1; // core is in request

#10;
$display("State = %b", core_state); //goes ot wait
        
        
lsu_states = 8'b01_01_01_01; // all lsu requestinf
#20;
$display("State = %b", core_state); // still waiting

lsu_states = 8'b11_11_11_11; // all lsu done
        
#10;
$display("State = %b", core_state); // execute

#10; // Update state
decoded_return = 1; 
#10; 
$display("State = %b, done wire = %b", core_state, done);// state is done and done is 1

#20 $finish;
end
endmodule