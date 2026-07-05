module dcr(input clk, reset,
input device_control_write_enable,
input [7:0] device_control_data,
output reg [7:0] thread_count
);

always @(posedge clk) begin
    if (reset) begin
        thread_count <= 8'b0;
    end else begin
        if (device_control_write_enable) begin
           thread_count <= device_control_data; 
        end
    end
end

endmodule