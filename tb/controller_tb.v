`timescale 1ns/1ns
`include "controller.v"

module controller_tb();

reg clk, reset;
reg [1:0] consumer_read_valid;
reg [15:0] consumer_read_addrs;
reg [1:0] consumer_write_valid;
reg [15:0] consumer_write_addrs;
reg [31:0] consumer_write_datas;
reg [0:0] mem_read_ready, mem_write_ready;
reg [15:0] mem_read_datas;

wire [1:0] consumer_read_ready;
wire [31:0] consumer_read_datas;
wire [1:0] consumer_write_ready;
wire [0:0] mem_read_valid;
wire [7:0] mem_read_addrs;
wire [0:0] mem_write_valid;
wire [7:0] mem_write_addrs;
wire [15:0] mem_write_datas;


controller #(8,16,2,1,1)
uut(clk, reset, consumer_read_valid, consumer_read_addrs,
consumer_write_valid, consumer_write_addrs, consumer_write_datas,
mem_read_ready, mem_write_ready, mem_read_datas, consumer_read_ready,
consumer_read_datas, consumer_write_ready, mem_read_valid, mem_read_addrs,
mem_write_valid, mem_write_addrs, mem_write_datas);

always #5 clk = ~clk;

initial begin
    $dumpfile("controller_tb.vcd");
    $dumpvars(0,controller_tb);
    
    clk = 0; reset = 1;
    consumer_read_valid = 0; consumer_read_addrs = 0;
    consumer_write_valid = 0; consumer_write_addrs = 0; consumer_write_datas = 0;
    mem_read_ready = 0; mem_read_datas = 0; mem_write_ready = 0;

    #10 reset = 0;

    #10;
    consumer_read_valid = 2'b11; 
    consumer_read_addrs = {8'd99, 8'd10}; //addr1 | addr0
        
    #20;
    $display("Mem valid = %b, Addr = %d", mem_read_valid, mem_read_addrs); // addr should be that of 0
        
    // response for consumer 0
    #20; mem_read_ready = 1; mem_read_datas = 16'hAAAA;
    #10; mem_read_ready = 0;
        
    #20;
    $display("Consumer 0 Ready = %b, Data = %h", consumer_read_ready[0], consumer_read_datas[15:0]);
    consumer_read_valid[0] = 0; //consumer0 acknowledges 

    // controller now goes to consumer 1
    #30;
    $display("Mem valid = %b, Addr = %d", mem_read_valid, mem_read_addrs);// addr should be that of 1
                 
    // respond for consumer 1
    #20; mem_read_ready = 1; mem_read_datas = 16'hBBBB;
    #10; mem_read_ready = 0;
        
    #20;
    $display("Consumer 1 Ready = %b, Data = %h", consumer_read_ready[1], consumer_read_datas[31:16]);
    consumer_read_valid[1] = 0; 
        
    #30; // consumer now goes to IDLE

      
        
   
    consumer_write_valid = 2'b11;
    consumer_write_addrs = {8'd100,8'd200};
    consumer_write_datas = {16'hABCD,16'hDCBA}; 

    #20; // some time for controller to go from idle to write waiting
        
    $display("Mem Valid = %b, Addr = %d, Data = %h", mem_write_valid, mem_write_addrs, mem_write_datas);

    #20; 
    mem_write_ready = 1;
    #10;
    mem_write_ready = 0;
        
    $display("consumer 0 Write Ready = %b", consumer_write_ready[0]);
    #10;// time to simulate random delays
    consumer_write_valid[0] = 0;


    // now controller goes to consumer 1
    #30;
    $display("Mem Valid = %b, Addr = %d, Data = %h", mem_write_valid, mem_write_addrs, mem_write_datas);
    
    #20;
    mem_write_ready = 1;
    #10 mem_write_ready = 0;
    $display("consumer 1 Write Ready = %b", consumer_write_ready[1]);
    consumer_write_valid[1] = 0;

    #20; //controller goes to idle
    $display("Consumer Write Ready = %b", consumer_write_ready); // should be 00 as it should be in idle

    #20 $finish;
end
endmodule