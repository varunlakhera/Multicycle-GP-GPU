`timescale 1ns/1ns
`include "gpu.v"

module gpu_tb();


reg clk, reset, start, device_control_write_enable;
reg [7:0] device_control_data;
wire [0:0] program_mem_read_valid;
reg [0:0] program_mem_read_ready;
wire [7:0] program_mem_read_addrs;
reg [15:0] program_mem_read_datas;
wire [3:0] data_mem_read_valid;
wire [3:0] data_mem_write_valid;
reg [3:0] data_mem_read_ready;
reg [3:0] data_mem_write_ready;
wire [31:0] data_mem_read_addrs;
wire [31:0] data_mem_write_addrs;
reg [31:0] data_mem_read_datas;
wire [31:0] data_mem_write_datas;
wire done;


localparam NUM_CORE = 2, THREADS_PER_BLOCK = 4;

//imitating imem and dmem
reg [15:0] prog_mem [255:0];
reg [7:0]  data_mem [255:0];

    
gpu #(.DATA_MEM_NUM_CHANNELS(4), .PROGRAM_MEM_NUM_CHANNELS(1), .NUM_CORE(NUM_CORE), .THREADS_PER_BLOCK(THREADS_PER_BLOCK)) 
uut (clk, reset, start, device_control_write_enable, device_control_data,
program_mem_read_valid, program_mem_read_ready, program_mem_read_addrs, program_mem_read_datas,
data_mem_read_valid, data_mem_write_valid, data_mem_read_ready, data_mem_write_ready,
data_mem_read_addrs, data_mem_write_addrs, data_mem_read_datas, data_mem_write_datas,
done);

always #5 clk = ~clk;
   
integer i;
always @(posedge clk) begin
    program_mem_read_ready[0] <= program_mem_read_valid[0]; 
    if (program_mem_read_valid[0] && !program_mem_read_ready[0]) begin
        program_mem_read_datas[15:0] <= prog_mem[program_mem_read_addrs[7:0]];
    end

    for(i = 0; i < 4; i = i + 1) begin
        data_mem_write_ready[i] <= data_mem_write_valid[i]; 
        data_mem_read_ready[i] <= data_mem_read_valid[i]; 

        if (data_mem_read_valid[i] && !data_mem_read_ready[i]) begin
            data_mem_read_datas[i*8 +: 8] <= data_mem[data_mem_read_addrs[i*8 +: 8]];
        end

        if (data_mem_write_valid[i] && !data_mem_write_ready[i]) begin
            data_mem[data_mem_write_addrs[i*8 +: 8]] <= data_mem_write_datas[i*8 +: 8];
            $display("Writing %0d(DATA) at %0d(ADDR)", data_mem_write_datas[i*8 +: 8], data_mem_write_addrs[i*8 +: 8]);
        end
    end
end

    
integer j;
initial begin
    $dumpfile("gpu_tb.vcd");
    $dumpvars(0,gpu_tb);

    $readmemh("cmem.hex", prog_mem);

    for(j=0; j<256; j=j+1) begin
        data_mem[j] = 0;
    end 

    clk = 0; reset = 1; start = 0; device_control_write_enable = 0; device_control_data = 0;
    program_mem_read_ready = 0; program_mem_read_datas = 0;
    data_mem_read_ready = 0; data_mem_write_ready = 0; data_mem_read_datas = 0;

    #10 reset = 0;
        
    // write how many threads we want total
    device_control_write_enable = 1; device_control_data = 8'd8; 
    #10 device_control_write_enable = 0;
          
    #10 start = 1;
    $display("START");
    #10 start = 0;

    wait (done == 1);
    $writememh("dmem.hex",data_mem);
        
    $display("DONE");

    #20 $finish;
end
endmodule