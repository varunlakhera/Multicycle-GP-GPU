module dispatcher#(parameter NUM_CORE = 2, THREADS_PER_BLOCK = 4)
(input  clk, reset, start,
input [7:0] thread_count,
input [NUM_CORE - 1 : 0] core_done,
output reg [NUM_CORE - 1 : 0] core_start,
output reg [NUM_CORE - 1 : 0] core_reset,
output reg [8*NUM_CORE - 1 : 0] core_block_ids,
output reg [(NUM_CORE)*($clog2(THREADS_PER_BLOCK) + 1) - 1 : 0] core_thread_counts,
output reg done
);

localparam width = $clog2(THREADS_PER_BLOCK) + 1;
reg [width - 1 : 0] core_thread_count [NUM_CORE - 1 : 0];
reg [7:0] core_block_id [NUM_CORE - 1 : 0];

wire [7:0] total_blocks;
reg [7:0] blocks_dispatched, blocks_done;
reg start_execution;


assign total_blocks = (thread_count + THREADS_PER_BLOCK - 1)/THREADS_PER_BLOCK;

integer i,j,k,p,q;
always @(*) begin
    for(i = 0; i<NUM_CORE; i = i + 1) begin
        core_thread_counts [i*width +: width] = core_thread_count[i];
        core_block_ids[8*i +: 8] = core_block_id [i];
    end
end

always @(posedge clk) begin
    if (reset) begin
        done <= 0;
        blocks_dispatched <= 8'b0;
        blocks_done <= 8'b0;
        start_execution <= 0;

        for(j = 0; j < NUM_CORE; j = j + 1) begin
            core_start[j] <= 0;
            core_reset[j] <= 1;
            core_block_id[j] <= 8'b0;
            core_thread_count[j] <= THREADS_PER_BLOCK;
        end
    end
    else begin
        if(start && !start_execution) begin
            start_execution <= 1;
                for(k = 0 ; k < NUM_CORE ; k = k + 1) begin
                    core_reset[k] <= 1;
                end
        end
        if(start || start_execution) begin
            
            if (blocks_done == total_blocks) begin
                done <= 1;
            end

            for(p = 0 ; p < NUM_CORE ; p = p + 1) begin
                if (core_reset[p]) begin
                    core_reset [p] <= 0;
                    if(blocks_dispatched < total_blocks) begin
                        core_start[p] <= 1;
                        core_block_id[p] <= blocks_dispatched;
                        core_thread_count[p] <= (blocks_dispatched == total_blocks - 1)? (thread_count - (blocks_dispatched*THREADS_PER_BLOCK)) : THREADS_PER_BLOCK;
                        blocks_dispatched = blocks_dispatched + 1;
                    end
                end
            end

            for (q = 0 ; q < NUM_CORE ; q = q + 1) begin
                if(core_start[q] && core_done[q]) begin
                    core_reset[q] <= 1;
                    core_start[q] <= 0;
                    blocks_done = blocks_done + 1;
                end
            end
        end
    end
end

endmodule