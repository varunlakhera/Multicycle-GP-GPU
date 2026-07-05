module fetcher (input clk, reset,
input mem_read_ready,
input [2:0] core_state, 
input [7:0] current_pc,
input [15:0] mem_read_data,
output reg [15:0] instruction,
output reg [7:0] mem_read_addr,
output reg [2:0] fetcher_state,
output reg mem_read_valid
);


localparam IDLE = 3'b000, FETCHING = 3'b010, FETCHED = 3'b100;
localparam FETCH = 3'b001, DECODE = 3'b010; 

always @(posedge clk) begin
    if(reset) begin
        instruction <= 16'b0;
        mem_read_addr <= 8'b0;
        mem_read_valid <= 0;
        fetcher_state <= IDLE;
    end else begin
        case(fetcher_state) 
            IDLE : begin
                if(core_state == FETCH) begin
                    fetcher_state <= FETCHING;
                    mem_read_valid <= 1;
                    mem_read_addr <= current_pc;
                end
            end
            FETCHING : begin
                if(mem_read_ready) begin
                    fetcher_state <= FETCHED;
                    mem_read_valid <= 0;
                    instruction <= mem_read_data;
                end
            end
            FETCHED : begin
                if(core_state == DECODE) begin
                    fetcher_state <= IDLE;
                end
            end
        endcase
    end
end

endmodule