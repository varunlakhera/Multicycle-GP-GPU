`include "alu.v"
`include "pc.v"
`include "regfile.v"
`include "decoder.v"
`include "scheduler.v"
`include "fetcher.v"
`include "lsu.v"

module core #(parameter THREADS_PER_BLOCK = 4)
(input clk, reset, start,
input [7:0] block_id,
input [$clog2(THREADS_PER_BLOCK) : 0] thread_count,
input program_mem_read_ready,
input [15:0] program_mem_read_data,
input [THREADS_PER_BLOCK-1 : 0] data_mem_read_ready,
input [8*THREADS_PER_BLOCK - 1 : 0] data_mem_read_datas,
input [THREADS_PER_BLOCK - 1 : 0] data_mem_write_ready,

output program_mem_read_valid,
output done,
output [7:0] program_mem_read_addr,
output [THREADS_PER_BLOCK - 1 : 0] data_mem_read_valid,
output [8*THREADS_PER_BLOCK - 1 : 0] data_mem_read_addrs,
output [THREADS_PER_BLOCK - 1 : 0] data_mem_write_valid,
output [8*THREADS_PER_BLOCK - 1 : 0] data_mem_write_datas,
output [8*THREADS_PER_BLOCK - 1 : 0] data_mem_write_addrs
);

wire [2:0] core_state;
wire [7:0] current_pc;
wire [15:0] instruction;
wire [2:0] fetcher_state;
wire [3:0] rs_addr, rt_addr, rd_addr;
wire [7:0] immediate;
wire mem_read_enable, mem_write_enable, reg_write_enable, nzp_write_enable;
wire [1:0] reg_input_mux, alu_select;
wire decoded_return;
wire [2:0]nzp_inst;
wire pc_out_mux;

wire [7:0] rs[THREADS_PER_BLOCK - 1 : 0];
wire [7:0] rt[THREADS_PER_BLOCK - 1 : 0];
wire [7:0] rd[THREADS_PER_BLOCK - 1 : 0];
wire [1:0] lsu_state[THREADS_PER_BLOCK - 1 : 0];
wire [2*THREADS_PER_BLOCK - 1 : 0] lsu_states;

wire [7:0] new_pc [THREADS_PER_BLOCK - 1 : 0];
wire [7:0] alu_out [THREADS_PER_BLOCK - 1 : 0];
wire [2:0] alu_nzp [THREADS_PER_BLOCK - 1 : 0];
wire [7:0] lsu_out [THREADS_PER_BLOCK - 1 : 0];
wire [7:0] data_mem_read_data [THREADS_PER_BLOCK - 1 : 0];
wire [7:0] data_mem_read_addr [THREADS_PER_BLOCK - 1 : 0];
wire [7:0] data_mem_write_data [THREADS_PER_BLOCK - 1 : 0];
wire [7:0] data_mem_write_addr [THREADS_PER_BLOCK - 1 : 0];

fetcher core_fetcher(.clk(clk),
.reset(reset),
.mem_read_ready(program_mem_read_ready),
.core_state(core_state),
.current_pc(current_pc),
.mem_read_data(program_mem_read_data),
.instruction(instruction),
.mem_read_addr(program_mem_read_addr),
.fetcher_state(fetcher_state),
.mem_read_valid(program_mem_read_valid)
);

decoder core_decoder(.clk(clk),
.reset(reset),
.instruction(instruction),
.core_state(core_state),
.rs_addr(rs_addr),
.rt_addr(rt_addr),
.rd_addr(rd_addr),
.nzp_inst(nzp_inst),
.immediate(immediate),
.mem_read_enable(mem_read_enable),
.mem_write_enable(mem_write_enable),
.reg_write_enable(reg_write_enable),
.nzp_write_enable(nzp_write_enable),
.reg_input_mux(reg_input_mux),
.alu_select(alu_select),//alu_op
.pc_out_mux(pc_out_mux),
.decoded_return(decoded_return)
);

scheduler core_scheduler(.clk(clk),
.reset(reset),
.start(start),
.mem_read_enable(mem_read_enable),
.mem_write_enable(mem_write_enable),
.decoded_return(decoded_return),
.fetcher_state(fetcher_state),
.lsu_states(lsu_states),
.new_pc(new_pc[THREADS_PER_BLOCK - 1]), // forcing it be the new pc of whatever the last thread is, dictator thing....
.core_state(core_state),
.current_pc(current_pc),
.done(done)
);

genvar i;

generate
    for(i=0; i<THREADS_PER_BLOCK; i= i + 1) begin : THREADS
        
        //assign lsu_state [i] = lsu_states[(2*i) +: 2];
        assign data_mem_read_data [i] = data_mem_read_datas[(8*i) +: 8];
        assign data_mem_read_addrs[(8*i) +: 8] = data_mem_read_addr [i];
        assign data_mem_write_datas[(8*i) +: 8] = data_mem_write_data [i] ;
        assign data_mem_write_addrs[(8*i) +: 8] = data_mem_write_addr [i];
        assign lsu_states[(2*i) +: 2] = lsu_state[i];
        
        alu core_alu(.clk(clk),
        .reset(reset),
        .enable(i<thread_count),
        .rs(rs[i]),
        .rt(rt[i]),
        .alu_op(alu_select),
        .core_state(core_state),
        .alu_out(alu_out[i]),
        .alu_nzp(alu_nzp[i])
        );

        regfile #(.THREAD_ID(i),.THREADS_PER_BLOCK(THREADS_PER_BLOCK))
        core_regfile (.clk(clk),
        .reset(reset),
        .enable(i<thread_count),
        .reg_write_enable(reg_write_enable),
        .core_state(core_state),
        .alu_out(alu_out[i]),
        .lsu_out(lsu_out[i]),
        .immediate(immediate),
        .block_id(block_id),
        .reg_input_mux(reg_input_mux),
        .rs_addr(rs_addr),
        .rt_addr(rt_addr),
        .rd_addr(rd_addr),
        .rs_data(rs[i]),
        .rt_data(rt[i])
        );

        pc core_pc(.clk(clk),
        .reset(reset),
        .enable(i<thread_count),
        .core_state(core_state),
        .nzp_write_enable(nzp_write_enable),
        .pc_out_mux(pc_out_mux),
        .current_pc(current_pc),
        .immediate(immediate),
        .nzp_inst(nzp_inst),
        .nzp_out(alu_nzp[i]),
        .new_pc(new_pc[i])
        );

        lsu core_lsu(.clk(clk),
        .reset(reset),
        .enable(i<thread_count),
        .core_state(core_state),
        .mem_read_enable(mem_read_enable),
        .mem_write_enable(mem_write_enable),
        .rs_out(rs[i]),
        .rt_out(rt[i]),
        .mem_read_data(data_mem_read_data[i]),
        .mem_read_ready(data_mem_read_ready[i]),
        .mem_write_ready(data_mem_write_ready[i]),
        .mem_read_addr(data_mem_read_addr[i]),
        .mem_write_addr(data_mem_write_addr[i]),
        .mem_write_data(data_mem_write_data[i]),
        .lsu_state(lsu_state[i]),
        .mem_read_valid(data_mem_read_valid[i]),
        .mem_write_valid(data_mem_write_valid[i])
        );

    end
endgenerate



endmodule


