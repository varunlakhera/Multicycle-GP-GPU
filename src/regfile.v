module regfile #(parameter THREAD_ID = 0, THREADS_PER_BLOCK = 4)
(input clk, reset, enable,
input reg_write_enable, 
input [2:0] core_state,
input [7:0] alu_out, lsu_out, immediate, block_id, 
input [1:0] reg_input_mux,
input [3:0] rs_addr, rt_addr, rd_addr,
output reg [7:0] rs_data, rt_data
);

reg [7:0] R [15:0];
integer i;
//R[15] thread Id, R[13] block ID
localparam REQUEST = 3'b011, UPDATE = 3'b110;

//assign rs_data = R[rs_addr];
//assign rt_data = R[rt_addr];

always @(posedge clk) begin 
    if(reset) begin
        rs_data <= 8'b0;
        rt_data <= 8'b0;
        for(i = 0; i<13; i++ ) begin
            R[i] <= 8'b0;
        end
        R[13] <= 8'b0;
        R[14] <= THREADS_PER_BLOCK;
        R[15] <= THREAD_ID;
    end
    else if(enable) begin

        R[13] <= block_id;

        if(core_state == REQUEST) begin
            rs_data <= R[rs_addr];
            rt_data <= R[rt_addr];
        end 
        
        if(core_state == UPDATE) begin
            if(reg_write_enable && rd_addr<13) begin
                case(reg_input_mux) 
                    2'b00 : R[rd_addr] <= alu_out;
                    2'b01 : R[rd_addr] <= lsu_out;
                    2'b10 : R[rd_addr] <= immediate;
                    default : R[rd_addr] <= R[rd_addr];
                endcase
            end
        end
    end
end


endmodule
