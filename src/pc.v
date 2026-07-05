module pc (input clk, reset, enable, 
input [2:0] core_state,
input nzp_write_enable, pc_out_mux, 
input [7:0] current_pc, immediate,
input [2:0] nzp_inst, nzp_out,
output reg [7:0] new_pc
);

localparam EXECUTE = 3'b101, UPDATE = 3'b110;

reg [2:0] nzp;


always @(posedge clk) begin

    if(reset) begin
        nzp <= 3'b000;
        new_pc <= 8'b0;
    end
    
    
    else if (enable) begin
        
        if(core_state == EXECUTE) begin
            if(pc_out_mux) begin
                if((nzp_inst & nzp) != 3'b000 ) begin
                    new_pc <= immediate;
                end else begin
                    new_pc <= current_pc + 1;
                end
            end else begin
                new_pc <= current_pc + 1;
            end
        end

        if(core_state == UPDATE) begin
            if(nzp_write_enable) begin
                nzp <= nzp_out;
            end
        end
    end
end

endmodule
