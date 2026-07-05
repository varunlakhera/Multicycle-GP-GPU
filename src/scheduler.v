module scheduler #(parameter THREADS_PER_BLOCK = 4)
(input clk, reset, start, mem_read_enable, mem_write_enable, decoded_return,
input [2:0] fetcher_state, 
input [2*THREADS_PER_BLOCK - 1 : 0] lsu_states,
input [7:0] new_pc,
output reg [2:0] core_state,
output reg [7:0] current_pc,
output reg done
);


localparam IDLE = 3'b000, FETCH = 3'b001, DECODE = 3'b010, REQUEST = 3'b011,
WAIT = 3'b100, EXECUTE = 3'b101, UPDATE = 3'b110, DONE = 3'b111;

integer i, j;

reg any_lsu_waiting;
reg [1:0] lsu_state [THREADS_PER_BLOCK-1 : 0];
always @(*) begin
    for (i = 0; i<THREADS_PER_BLOCK; i = i+1) begin
        lsu_state [i] = lsu_states[(2*i) +: 2];
    end
end

always @(posedge clk) begin
    if(reset) begin
        core_state <= IDLE;
        current_pc <= 8'b0;
        done <= 0;
    end
    else begin
        case(core_state) 
            IDLE : begin
                if(start) begin
                    core_state <= FETCH;
                end
            end
            FETCH : begin
                if(fetcher_state == 3'b100) begin
                    core_state <= DECODE;
                end
            end
            DECODE : begin
                core_state <= REQUEST;
            end
            REQUEST : begin
                if (mem_read_enable || mem_write_enable) begin // this logic was in stage decode but it wasnt working prolly due to a cc mismatch as enables take some time to update
                    core_state <= WAIT; // we couldve done just all these states one by one too
                end else begin
                    core_state <= EXECUTE;
                end
            end
            WAIT : begin
                any_lsu_waiting = 0;
                for(j = 0 ; j<THREADS_PER_BLOCK; j = j + 1) begin
                    if(^lsu_state[j]) begin //lsu_state[j] == 2'b01 || lsu_state[j] == 2'b10 // just looks good ;)
                        any_lsu_waiting = 1;
                    end
                end

                if(!any_lsu_waiting) begin
                    core_state <= EXECUTE;
                end                
            end
            EXECUTE : begin
                core_state <= UPDATE;
            end
            UPDATE : begin
                if(decoded_return) begin
                    done <= 1;
                    core_state <= DONE;
                end else begin
                    current_pc <= new_pc; // not checking out the possiblities of branch divergence and will force this new pc to be the one from the ;ast thread
                    core_state <= FETCH;
                end
            end
            DONE : begin
                core_state <= DONE;
            end
        endcase
    end
end

endmodule