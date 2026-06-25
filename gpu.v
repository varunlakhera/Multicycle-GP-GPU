`include "core.v"
`include "controller.v"
`include "dcr.v"
`include "dispatcher.v"

module gpu #(parameter DATA_MEM_NUM_CHANNELS = 4, PROGRAM_MEM_NUM_CHANNELS = 1, NUM_CORE = 2, THREADS_PER_BLOCK = 4)
(input clk, reset,
input start, device_control_write_enable,
input [7:0] device_control_data,

output [PROGRAM_MEM_NUM_CHANNELS - 1 : 0] program_mem_read_valid,
input [PROGRAM_MEM_NUM_CHANNELS - 1 : 0] program_mem_read_ready,
output [PROGRAM_MEM_NUM_CHANNELS*8 - 1 : 0] program_mem_read_addrs,
input [PROGRAM_MEM_NUM_CHANNELS*16 - 1 : 0] program_mem_read_datas,

output [DATA_MEM_NUM_CHANNELS - 1 : 0] data_mem_read_valid,
output [DATA_MEM_NUM_CHANNELS - 1 : 0] data_mem_write_valid,
input [DATA_MEM_NUM_CHANNELS - 1 : 0] data_mem_read_ready,
input [DATA_MEM_NUM_CHANNELS - 1 : 0] data_mem_write_ready,
output [DATA_MEM_NUM_CHANNELS*8 - 1 : 0] data_mem_read_addrs,
output [DATA_MEM_NUM_CHANNELS*8 - 1 : 0] data_mem_write_addrs,
input [DATA_MEM_NUM_CHANNELS*8 - 1 : 0] data_mem_read_datas,
output [DATA_MEM_NUM_CHANNELS*8 - 1 : 0] data_mem_write_datas,

output done
);

wire [7:0] program_mem_read_addr [PROGRAM_MEM_NUM_CHANNELS - 1 : 0];
wire [15:0] program_mem_read_data [PROGRAM_MEM_NUM_CHANNELS - 1 : 0];

wire [7:0] data_mem_read_addr [DATA_MEM_NUM_CHANNELS - 1 : 0];
wire [7:0] data_mem_write_addr [DATA_MEM_NUM_CHANNELS - 1 : 0];
wire [7:0] data_mem_read_data [DATA_MEM_NUM_CHANNELS - 1 : 0];
wire [7:0] data_mem_write_data [DATA_MEM_NUM_CHANNELS - 1 : 0];

genvar i;

generate
    for (i = 0 ; i < PROGRAM_MEM_NUM_CHANNELS ; i = i + 1) begin
        assign program_mem_read_addrs[8*i +: 8] = program_mem_read_addr[i];
        assign program_mem_read_data[i] = program_mem_read_datas[16*i +: 16];
    end
    for (i = 0 ; i < DATA_MEM_NUM_CHANNELS ; i = i + 1) begin
        assign data_mem_read_addrs[8*i +: 8] = data_mem_read_addr[i];
        assign data_mem_read_data[i] = data_mem_read_datas[8*i +: 8];
        assign data_mem_write_addrs[8*i +: 8] = data_mem_write_addr[i];
        assign data_mem_write_datas[8*i +: 8] = data_mem_write_data[i];
    end
endgenerate

localparam NUM_LSUS = NUM_CORE*THREADS_PER_BLOCK;

wire [7:0] thread_count;
wire [NUM_CORE - 1 : 0] core_done;
wire [NUM_CORE - 1 : 0] core_start;
wire [NUM_CORE - 1 : 0] core_reset;
wire [8*NUM_CORE - 1 : 0] core_block_ids;
wire [(NUM_CORE)*($clog2(THREADS_PER_BLOCK) + 1) - 1 : 0] core_thread_counts;

wire [NUM_LSUS - 1 : 0] lsu_read_valid;
wire [NUM_LSUS*8 - 1 : 0] lsu_read_addrs;
wire [NUM_LSUS*8 - 1 : 0] lsu_read_datas;
wire [NUM_LSUS - 1 : 0] lsu_read_ready;

wire [NUM_LSUS - 1 : 0] lsu_write_valid;
wire [NUM_LSUS*8 - 1 : 0] lsu_write_addrs;
wire [NUM_LSUS*8 - 1 : 0] lsu_write_datas;
wire [NUM_LSUS - 1 : 0] lsu_write_ready;


localparam NUM_FETCHERS = NUM_CORE;
wire [NUM_FETCHERS - 1 : 0] fetcher_read_valid;
wire [NUM_FETCHERS*8 - 1 : 0] fetcher_read_addrs;
wire [NUM_FETCHERS*16 - 1 : 0] fetcher_read_datas;
wire [NUM_FETCHERS - 1 : 0] fetcher_read_ready;
 
dcr gpu_dcr(
    .clk(clk),
    .reset(reset),
    .device_control_write_enable(device_control_write_enable),
    .device_control_data(device_control_data),
    .thread_count(thread_count)
);

dispatcher #(.NUM_CORE(NUM_CORE), .THREADS_PER_BLOCK(THREADS_PER_BLOCK))
gpu_dispatcher(
    .clk(clk),
    .reset(reset),
    .start(start),
    .thread_count(thread_count),
    .core_done(core_done),
    .core_start(core_start),
    .core_reset(core_reset), 
    .core_block_ids(core_block_ids),
    .core_thread_counts(core_thread_counts),
    .done(done)
);

controller #(.ADDR_BITS(8), .DATA_BITS(16), .NUM_CONSUMERS(NUM_FETCHERS), .NUM_CHANNELS(PROGRAM_MEM_NUM_CHANNELS), .WRITE_ENABLE(0))
gpu_program_mem_controller(
    .clk(clk),
    .reset(reset),
    .consumer_read_valid(fetcher_read_valid),
    .consumer_read_addrs(fetcher_read_addrs),
    //.consumer_write_valid(),
    //.consumer_write_addrs(),
    //.consumer_write_datas(),
    .mem_read_ready(program_mem_read_ready),
    //.mem_write_ready(),
    .mem_read_datas(program_mem_read_datas),

    .consumer_read_ready(fetcher_read_ready),
    .consumer_read_datas(fetcher_read_datas),
    //.consumer_write_ready(),
    .mem_read_valid(program_mem_read_valid),
    .mem_read_addrs(program_mem_read_addrs)
    //.mem_write_valid(),
    //.mem_write_addrs(),
    //.mem_write_datas()
);

controller #(.ADDR_BITS(8), .DATA_BITS(8), .NUM_CONSUMERS(NUM_LSUS), .NUM_CHANNELS(DATA_MEM_NUM_CHANNELS), .WRITE_ENABLE(1))
gpu_data_mem_controller(
    .clk(clk),
    .reset(reset),
    .consumer_read_valid(lsu_read_valid),
    .consumer_read_addrs(lsu_read_addrs),
    .consumer_write_valid(lsu_write_valid),
    .consumer_write_addrs(lsu_write_addrs),
    .consumer_write_datas(lsu_write_datas),
    .mem_read_ready(data_mem_read_ready),
    .mem_write_ready(data_mem_write_ready),
    .mem_read_datas(data_mem_read_datas),

    .consumer_read_ready(lsu_read_ready),
    .consumer_read_datas(lsu_read_datas),
    .consumer_write_ready(lsu_write_ready),
    .mem_read_valid(data_mem_read_valid),
    .mem_read_addrs(data_mem_read_addrs),
    .mem_write_valid(data_mem_write_valid),
    .mem_write_addrs(data_mem_write_addrs),
    .mem_write_datas(data_mem_write_datas)
);


//wire [7 : 0] lsu_read_addr [NUM_LSUS - 1 : 0];
//wire [7 : 0] lsu_read_data [NUM_LSUS - 1 : 0];

//wire [7 : 0] lsu_write_addr [NUM_LSUS - 1 : 0];
//wire [7 : 0] lsu_write_data [NUM_LSUS - 1 : 0];//not assigned

wire [7 : 0] core_block_id [NUM_CORE - 1 : 0];
wire [$clog2(THREADS_PER_BLOCK) : 0] core_thread_count [NUM_CORE - 1 : 0];

wire [7 : 0] fetcher_read_addr [NUM_CORE - 1 : 0];
wire [15 : 0] fetcher_read_data [NUM_CORE - 1 : 0];

genvar j;
generate
    for(j = 0 ; j < NUM_CORE ; j = j + 1) begin : cores
    
        wire [THREADS_PER_BLOCK - 1 : 0] core_lsu_read_valid;
        wire [THREADS_PER_BLOCK*8 - 1 : 0] core_lsu_read_addrs;
        wire [THREADS_PER_BLOCK - 1 : 0] core_lsu_read_ready;
        wire [THREADS_PER_BLOCK*8 - 1 : 0] core_lsu_read_datas;

        wire [THREADS_PER_BLOCK - 1 : 0] core_lsu_write_valid;
        wire [THREADS_PER_BLOCK*8 - 1 : 0] core_lsu_write_addrs;
        wire [THREADS_PER_BLOCK - 1 : 0] core_lsu_write_ready;
        wire [THREADS_PER_BLOCK*8 - 1 : 0] core_lsu_write_datas;

        assign core_block_id[j] = core_block_ids[8*j +: 8]; 
        assign core_thread_count[j] = core_thread_counts[j*($clog2(THREADS_PER_BLOCK)+1) +: ($clog2(THREADS_PER_BLOCK)+1)];
        assign fetcher_read_data[j] = fetcher_read_datas[j*16 +: 16]; 
        assign fetcher_read_addrs[j*8 +: 8] = fetcher_read_addr[j]; 

        genvar k;
        for (k = 0 ; k < THREADS_PER_BLOCK ; k = k + 1) begin : threads
            localparam lsu_index = j*THREADS_PER_BLOCK + k;
            
            assign lsu_read_valid[lsu_index] = core_lsu_read_valid[k];
            assign lsu_write_valid[lsu_index] = core_lsu_write_valid[k];

            assign core_lsu_read_ready[k] = lsu_read_ready[lsu_index];
            assign core_lsu_write_ready[k] = lsu_write_ready[lsu_index];

            assign lsu_read_addrs[lsu_index*8 +: 8] = core_lsu_read_addrs[k*8 +: 8];
            assign lsu_write_addrs[lsu_index*8 +: 8] = core_lsu_write_addrs[k*8 +: 8];
            
            assign core_lsu_read_datas[k*8 +: 8] = lsu_read_datas[lsu_index*8 +: 8];
            assign lsu_write_datas[lsu_index*8 +: 8] = core_lsu_write_datas[k*8 +: 8];
        end

        core #(.THREADS_PER_BLOCK(THREADS_PER_BLOCK))
        gpu_core(
            .clk(clk),
            .reset(core_reset[j]),
            .start(core_start[j]),
            .done(core_done[j]),
            .block_id(core_block_id[j]),
            .thread_count(core_thread_count[j]),
            .program_mem_read_ready(fetcher_read_ready[j]),
            .program_mem_read_data(fetcher_read_data[j]),
            .program_mem_read_valid(fetcher_read_valid[j]),
            .program_mem_read_addr(fetcher_read_addr[j]),

            .data_mem_read_ready(core_lsu_read_ready),
            .data_mem_read_datas(core_lsu_read_datas),
            .data_mem_read_valid(core_lsu_read_valid),
            .data_mem_read_addrs(core_lsu_read_addrs),
            .data_mem_write_ready(core_lsu_write_ready),
            .data_mem_write_datas(core_lsu_write_datas),
            .data_mem_write_valid(core_lsu_write_valid),
            .data_mem_write_addrs(core_lsu_write_addrs)
        );

    end
endgenerate

endmodule