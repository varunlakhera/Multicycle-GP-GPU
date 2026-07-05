// synchronous high reset

module alu(input clk, reset, enable,
input [7:0] rs, rt,
input [1:0] alu_op,
input [2:0] core_state,
output reg [7:0] alu_out,
output reg [2:0] alu_nzp
);

localparam  ADD = 2'b00, SUB = 2'b01, MUL = 2'b10, DIV = 2'b11, EXECUTE = 3'b101;


always @(posedge clk) begin
    if(reset) begin
        alu_out <= 8'b0;
        alu_nzp <= 3'b0;
    end
    else if(enable) begin
        if(core_state == EXECUTE) begin
            alu_nzp <= {(rs > rt), (rs == rt), (rs < rt )};
            case(alu_op) 
                ADD : alu_out <= rs + rt;
                SUB : alu_out <= rs - rt;
                MUL : alu_out <= rs * rt;
                DIV :  begin
                    if(!rt) begin
                        alu_out <= 8'hFF;
                    end
                    else begin
                    alu_out <= rs / rt;
                    end
                end
            endcase
        end
    end
end

endmodule