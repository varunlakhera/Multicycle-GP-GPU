module controller #(parameter ADDR_BITS = 8, DATA_BITS = 16, NUM_CONSUMERS = 2, NUM_CHANNELS = 1, WRITE_ENABLE = 1)
(input clk, reset,
input [NUM_CONSUMERS - 1 : 0] consumer_read_valid,
input [NUM_CONSUMERS*ADDR_BITS - 1 : 0] consumer_read_addrs,
input [NUM_CONSUMERS - 1 : 0] consumer_write_valid,
input [NUM_CONSUMERS*ADDR_BITS - 1 : 0] consumer_write_addrs,
input [NUM_CONSUMERS*DATA_BITS - 1 : 0] consumer_write_datas,
input [NUM_CHANNELS - 1 : 0] mem_read_ready,
input [NUM_CHANNELS - 1 : 0] mem_write_ready,
input [NUM_CHANNELS*DATA_BITS - 1 : 0] mem_read_datas,

output reg [NUM_CONSUMERS - 1 : 0] consumer_read_ready,
output reg [NUM_CONSUMERS*DATA_BITS - 1 : 0] consumer_read_datas,
output reg [NUM_CONSUMERS - 1 : 0] consumer_write_ready,
output reg [NUM_CHANNELS - 1 : 0] mem_read_valid,
output reg [NUM_CHANNELS*ADDR_BITS - 1 : 0] mem_read_addrs,
output reg [NUM_CHANNELS - 1 : 0] mem_write_valid,
output reg [NUM_CHANNELS*ADDR_BITS - 1 : 0] mem_write_addrs,
output reg [NUM_CHANNELS*DATA_BITS - 1 : 0] mem_write_datas
);

reg [ADDR_BITS - 1 : 0] consumer_read_addr [NUM_CONSUMERS - 1 : 0];
reg [ADDR_BITS - 1 : 0] consumer_write_addr [NUM_CONSUMERS - 1 : 0];
reg [DATA_BITS - 1 : 0] consumer_read_data [NUM_CONSUMERS - 1 : 0];
reg [DATA_BITS - 1 : 0] consumer_write_data [NUM_CONSUMERS - 1 : 0];

reg [ADDR_BITS - 1 : 0] mem_read_addr [NUM_CHANNELS - 1 : 0];
reg [ADDR_BITS - 1 : 0] mem_write_addr [NUM_CHANNELS - 1 : 0];
reg [DATA_BITS - 1 : 0] mem_read_data [NUM_CHANNELS - 1 : 0];
reg [DATA_BITS - 1 : 0] mem_write_data [NUM_CHANNELS - 1 : 0];

integer i, j, k;
reg found;
localparam  IDLE = 3'b000, READ_WAITING = 3'b001, WRITE_WAITING = 3'b010, READ_RELAYING = 3'b011, WRITE_RELAYING = 3'b100;

always @(*) begin
    for (i = 0 ; i< NUM_CONSUMERS ; i = i + 1 ) begin
        consumer_read_addr[i] = consumer_read_addrs[i*ADDR_BITS +: ADDR_BITS];
        consumer_write_addr[i] = consumer_write_addrs[i*ADDR_BITS +: ADDR_BITS];
        consumer_read_datas [i*DATA_BITS +: DATA_BITS] = consumer_read_data[i];
        consumer_write_data[i] = consumer_write_datas [i*DATA_BITS +: DATA_BITS]; 
    end

    for (i = 0; i < NUM_CHANNELS ; i = i + 1) begin
        mem_read_addrs[i*ADDR_BITS +: ADDR_BITS] = mem_read_addr[i];
        mem_write_addrs[i*ADDR_BITS +: ADDR_BITS] = mem_write_addr[i];
        mem_read_data[i] = mem_read_datas[i*DATA_BITS +: DATA_BITS];
        mem_write_datas[i*DATA_BITS +: DATA_BITS] = mem_write_data[i];
    end
end

reg [2:0] controller_state [NUM_CHANNELS - 1 :0];
reg [$clog2(NUM_CONSUMERS) - 1 : 0] current_consumer [NUM_CHANNELS - 1 : 0];
reg [NUM_CONSUMERS - 1 : 0] channel_serving_consumer;

always @(posedge clk) begin
    if (reset) begin
        mem_read_valid <= 0;
        mem_write_valid <= 0;

        consumer_read_ready <= 0;
        consumer_write_ready <= 0;

        channel_serving_consumer <= 0;

        for (j = 0 ; j < NUM_CONSUMERS ; j = j + 1) begin
            consumer_read_data[j] <= 0;
        end

        for (j = 0 ; j < NUM_CHANNELS ; j = j + 1) begin
            mem_write_addr[j] <= 0;
            mem_read_addr[j] <= 0;
            mem_write_data[j] <= 0;
            current_consumer[j] <= 0;
            controller_state[j] <= IDLE;
        end
    end
    else begin 
        for (j = 0 ; j < NUM_CHANNELS ; j = j + 1) begin
            case (controller_state [j]) 
                IDLE : begin

                    found = 0;

                    for(k = 0 ; k < NUM_CONSUMERS ; k = k + 1) begin
                        if(!found) begin
                             if (consumer_read_valid[k] && !channel_serving_consumer[k]) begin

                                found = 1;

                                channel_serving_consumer[k] = 1;
                                current_consumer[j] <= k;
                                
                                mem_read_valid [j] <= 1;
                                mem_read_addr[j] <= consumer_read_addr[k];

                                controller_state[j] <= READ_WAITING;
                             end   
                             else if(WRITE_ENABLE && consumer_write_valid[k] && !channel_serving_consumer[k]) begin
                                found = 1;

                                channel_serving_consumer[k] = 1;
                                current_consumer[j] <= k;

                                mem_write_valid[j] <= 1;
                                mem_write_addr[j] <= consumer_write_addr[k];
                                mem_write_data[j] <= consumer_write_data[k];

                                controller_state[j] <= WRITE_WAITING;
                             end                              
                        end
                    end
                end
                READ_WAITING : begin
                    if(mem_read_ready[j]) begin
                        mem_read_valid[j] <= 0;
                        consumer_read_ready[current_consumer[j]] <= 1;
                        consumer_read_data[current_consumer[j]] <= mem_read_data[j];
                        controller_state[j] <= READ_RELAYING;
                    end
                end
                WRITE_WAITING : begin
                    if (mem_write_ready[j]) begin
                        mem_write_valid[j] <= 0;
                        consumer_write_ready[current_consumer[j]] <= 1;
                        controller_state[j] <= WRITE_RELAYING; 
                    end
                end
                READ_RELAYING : begin
                    if(!consumer_read_valid[current_consumer[j]]) begin
                        channel_serving_consumer[current_consumer[j]] = 0;
                        consumer_read_ready[current_consumer[j]] <= 0;
                        controller_state[j] <= IDLE;
                    end
                end
                WRITE_RELAYING : begin
                    if (!consumer_write_valid[current_consumer[j]]) begin
                        channel_serving_consumer[current_consumer[j]] = 0;
                        consumer_write_ready[current_consumer[j]] <= 0;
                        controller_state[j] <= IDLE; 
                    end
                end
            endcase
        end
    end
end
endmodule