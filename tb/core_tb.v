`timescale 1ns/1ps
`include "core.v"

module core_tb();

reg clk, reset, start;
reg [7:0] block_id;
reg [2:0] thread_count; // width is clog2(4)+1
reg program_mem_read_ready;
reg [15:0] program_mem_read_data;
reg [3:0] data_mem_read_ready;
reg [31:0] data_mem_read_datas;
reg [3:0] data_mem_write_ready;

wire program_mem_read_valid;
wire done;
wire [7:0] program_mem_read_addr;
wire [3:0] data_mem_read_valid;
wire [31:0] data_mem_read_addrs;
wire [3:0] data_mem_write_valid;
wire [31:0] data_mem_write_datas;
wire [31:0] data_mem_write_addrs;

core #(.THREADS_PER_BLOCK(4))
uut (clk, reset, start, block_id, thread_count, program_mem_read_ready,
program_mem_read_data, data_mem_read_ready, data_mem_read_datas, data_mem_write_ready,
program_mem_read_valid, done, program_mem_read_addr, data_mem_read_valid, data_mem_read_addrs, 
data_mem_write_valid, data_mem_write_datas, data_mem_write_addrs);


reg [15:0] program_memory [255:0];


always #5 clk = ~clk;

always @(posedge clk) begin
    if (program_mem_read_valid && !program_mem_read_ready) begin
        #10; // random mem delay
        program_mem_read_ready = 1;

        program_mem_read_data = program_memory[program_mem_read_addr];

        #10;
        program_mem_read_ready = 0;
    end
end


always @(negedge clk) begin //negedge as the core_state is getting updated at the posdge so we are looking at the changes at negedges
    if (!reset) begin
        case (uut.core_state) //delaying the print of signals by one state so if decodre we'll show result of fetch which is the instruction and...
            3'b010: $display("Current INST: %h", uut.instruction); // at decode stage we check what the instructoin is 
            3'b011: $display("DECODE Phase   | Rd = %d, Rs = %d, Rt = %d, Im = %d", uut.rd_addr, uut.rs_addr, uut.rt_addr, uut.immediate); // at request stage we see the decoded signals
            3'b101: $display("REG READ Phase | Thread0 Rs_Data = %d, Rt_Data = %d", uut.rs[0], uut.rt[0]); // at execute we see the requested results from register
            3'b110: $display("ALU Phase      | Thread0 ALU Output = %d which is getting saved to Reg %d", uut.alu_out[0], uut.rd_addr); //at update  we see the result afer execution
        endcase
    end
end

initial begin

    $dumpfile("core_tb.vcd");
    $dumpvars(0,core_tb);
    $readmemh("core.hex", program_memory);

    clk = 0; reset = 1; start = 0; block_id = 8'd2; //
    thread_count = 3'd3; // to check if thread 3 is at rest or no
    program_mem_read_ready = 0; program_mem_read_data = 0;
    data_mem_read_ready = 0; data_mem_read_datas = 0; data_mem_write_ready = 0;

    #10 reset = 0;

    #10 start = 1;
    $display("START");
    #10 start = 0;

    wait (done == 1);
    $display("DONE");

    #20 $finish;
end

endmodule
