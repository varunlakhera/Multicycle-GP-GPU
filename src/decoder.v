module decoder(input clk, reset,
input [15:0] instruction,
input [2:0] core_state,
output reg [3:0] rs_addr, rt_addr, rd_addr,
output reg [2:0] nzp_inst,
output reg [7:0] immediate,
output reg mem_read_enable, mem_write_enable, reg_write_enable, nzp_write_enable,
output reg [1:0] reg_input_mux, alu_select, 
output reg pc_out_mux, decoded_return
);


localparam NOP = 4'b0000, BRNZP = 4'b0001, CMP = 4'b0010, ADD = 4'b0011, SUB = 4'b0100,
MUL = 4'b0101, DIV = 4'b0110, LDR = 4'b0111, STR = 4'b1000, CONST = 4'b1001, RET = 4'b1111;

localparam  ALU_ADD = 2'b00, ALU_SUB = 2'b01, ALU_MUL = 2'b10, ALU_DIV = 2'b11;

always @(posedge clk) begin
    if (reset) begin
        rs_addr <= 4'b0;
        rt_addr <= 4'b0;
        rd_addr <= 4'b0;
        nzp_inst <= 3'b0;
        immediate <= 8'b0;
        mem_read_enable <= 0;
        mem_write_enable <= 0;
        reg_write_enable <= 0;
        nzp_write_enable <= 0;
        reg_input_mux <= 2'b0;
        alu_select <= 2'b0;
        pc_out_mux <= 0;
        decoded_return <= 0;
    end else begin
        if (core_state == 3'b010) begin
            rs_addr <= instruction [7:4];
            rt_addr <= instruction [3:0];
            rd_addr <= instruction [11:8];
            nzp_inst <= instruction [11:9];
            immediate <= instruction [7:0];
            mem_read_enable <= 0;
            mem_write_enable <= 0;
            reg_write_enable <= 0;
            nzp_write_enable <= 0;
            reg_input_mux <= 2'b0;
            alu_select <= 2'b0;
            pc_out_mux <= 0;
            decoded_return <= 0; 
            case (instruction [15:12])
                NOP : begin
                end
                BRNZP : begin
                    pc_out_mux <= 1;
                end
                CMP : begin
                    nzp_write_enable <= 1;
                end
                ADD : begin
                    reg_input_mux <= 2'b00;
                    reg_write_enable <= 1;
                    alu_select <= ALU_ADD;
                end
                SUB : begin
                    reg_input_mux <= 2'b00;
                    reg_write_enable <= 1;
                    alu_select <= ALU_SUB;
                end
                MUL : begin
                    reg_input_mux <= 2'b00;
                    reg_write_enable <= 1;
                    alu_select <= ALU_MUL;
                end
                DIV : begin
                    reg_input_mux <= 2'b00;
                    alu_select <= ALU_DIV;
                    reg_write_enable <= 1;
                end
                LDR : begin
                    reg_input_mux <= 2'b01;
                    reg_write_enable <= 1;
                    mem_read_enable <= 1;
                end
                STR : begin
                    mem_write_enable <= 1;
                end
                CONST : begin
                    reg_input_mux <= 2'b10;
                    reg_write_enable <= 1;
                end
                RET : begin
                    decoded_return <= 1;
                end
            endcase
        end
    end
end

endmodule