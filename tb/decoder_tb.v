`timescale 1ns/1ps
`include "decoder.v"
module decoder_tb();

reg clk, reset;
reg [15:0] instruction;
reg [2:0] core_state;
wire [3:0] rs_addr,rt_addr, rd_addr;
wire [2:0] nzp_inst;
wire [7:0] immediate;
wire mem_read_enable, mem_write_enable, reg_write_enable, nzp_write_enable;
wire [1:0] reg_input_mux, alu_select;
wire pc_out_mux, decoded_return;

localparam DECODE = 3'b010;

decoder uut(clk, reset, instruction, core_state, rs_addr, rt_addr, rd_addr,
nzp_inst, immediate, mem_read_enable, mem_write_enable, reg_write_enable, nzp_write_enable,
reg_input_mux, alu_select, pc_out_mux, decoded_return);

always #5 clk = ~clk;


initial begin

    $dumpfile("decoder_tb.vcd");
    $dumpvars(0,decoder_tb);

    clk = 0; reset = 1; instruction = 16'b0; core_state = 3'b000;
    #10; 
    reset = 0; core_state = DECODE;

    //  0011 | 0001 | 0010 | 0011
    //  Hex = 3123
    #10;
    instruction = 16'h3123;
    #10;
    $display("Reg_Input_Mux = %b, Reg_Write = %b, ALU_Sel=%b, rs=%b, rt=%b, rd=%b", 
    reg_input_mux, reg_write_enable, alu_select, rs_addr, rt_addr, rd_addr);

    // 0111 | 0100 | 0101 | 0000(xxxx)
    //Hex =  7450
    #10;
    instruction = 16'h7450;
    #10;
    $display("Mem_Read=%b, Reg_Write=%b, Reg_Input_Mux=%b ", 
    mem_read_enable, reg_write_enable, reg_input_mux);

    //0001 |  101 | 11111111 FF
    // Hex = 1AFF
    #10;
    instruction = 16'h1AFF;
    #10;
    $display("PC_Mux=%b , NZP_Inst=%b, Imm=%h", 
    pc_out_mux, nzp_inst, immediate);

    #20;
    $finish;
end

endmodule