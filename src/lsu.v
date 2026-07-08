module lsu (input clk, reset, enable,
input [2:0] core_state, 
input mem_read_enable, mem_write_enable,
input [7:0] rs_out, rt_out, mem_read_data,
input mem_read_ready, mem_write_ready,
output reg [7:0] mem_read_addr, mem_write_addr, mem_write_data,
output reg [1:0] lsu_state, 
output reg [7:0] lsu_out,
output reg mem_read_valid, mem_write_valid
);

localparam  IDLE = 2'b00, REQUESTING = 2'b01, WAITING = 2'b10, DONE = 2'b11;
localparam  REQUEST = 3'b011, UPDATE = 3'b110;

always @(posedge clk) begin
    if(reset) begin
        lsu_state <= IDLE;
        lsu_out <= 8'b0;
        mem_read_addr <= 8'b0;
        mem_write_addr <= 8'b0;
        mem_write_data <= 8'b0;
        mem_write_valid <= 0;
        mem_read_valid <= 0;
    end
    else if(enable) begin
        
        if(mem_read_enable) begin
            case(lsu_state) 
                IDLE : begin
                    if(core_state == REQUEST) begin
                        lsu_state <= REQUESTING;
                    end
                end
                REQUESTING : begin
                    lsu_state <= WAITING;
                    mem_read_addr <= rs_out;
                    mem_read_valid <= 1;
                end
                WAITING : begin
                    if(mem_read_ready) begin
                        lsu_state <= DONE;
                        mem_read_valid <= 0;
                        lsu_out <= mem_read_data;
                    end
                end
                DONE : begin
                    if(core_state == UPDATE) begin
                        lsu_state <= IDLE;
                    end
                end
            endcase
        end

        if(mem_write_enable) begin
            case(lsu_state) 
                IDLE : begin
                    if(core_state == REQUEST) begin
                        lsu_state <= REQUESTING;
                    end
                end
                REQUESTING : begin
                    lsu_state <= WAITING;
                    mem_write_valid <= 1;
                    mem_write_addr <= rs_out;
                    mem_write_data <= rt_out;
                end
                WAITING : begin
                    if(mem_write_ready) begin
                        lsu_state <= DONE;
                        mem_write_valid <= 0;
                    end
                end
                DONE : begin
                    if(core_state == UPDATE) begin
                        lsu_state <= IDLE;
                    end
                end
            endcase
        end
    end
end
endmodule
