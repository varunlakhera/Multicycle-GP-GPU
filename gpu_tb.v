`timescale 1ns/1ns
`include "gpu.v"

module gpu_tb();

    // 1. Core Clock and Control
    reg clk;
    reg reset;
    reg start;
    reg device_control_write_enable;
    reg [7:0] device_control_data;

    // 2. Program Memory Bus (1 Channel)
    wire [0:0] program_mem_read_valid;
    reg  [0:0] program_mem_read_ready;
    wire [7:0] program_mem_read_addrs;
    reg  [15:0] program_mem_read_datas;

    // 3. Data Memory Bus (4 Channels)
    wire [3:0] data_mem_read_valid;
    wire [3:0] data_mem_write_valid;
    reg  [3:0] data_mem_read_ready;
    reg  [3:0] data_mem_write_ready;
    wire [31:0] data_mem_read_addrs;
    wire [31:0] data_mem_write_addrs;
    reg  [31:0] data_mem_read_datas;
    wire [31:0] data_mem_write_datas;

    wire done;

    // --- NEW: ACTUAL RAM ARRAYS IN THE TESTBENCH ---
    reg [15:0] prog_mem [0:255]; // 256 lines of 16-bit instructions
    reg [7:0]  data_mem [0:255]; // 256 lines of 8-bit data

    // 4. Instantiate the Top-Level GPU
    gpu #(
        .DATA_MEM_NUM_CHANNELS(4), .PROGRAM_MEM_NUM_CHANNELS(1), 
        .NUM_CORE(2), .THREADS_PER_BLOCK(4)
    ) uut (
        .clk(clk), .reset(reset), .start(start),
        .device_control_write_enable(device_control_write_enable),
        .device_control_data(device_control_data),
        
        .program_mem_read_valid(program_mem_read_valid), .program_mem_read_ready(program_mem_read_ready),
        .program_mem_read_addrs(program_mem_read_addrs), .program_mem_read_datas(program_mem_read_datas),
        
        .data_mem_read_valid(data_mem_read_valid), .data_mem_write_valid(data_mem_write_valid),
        .data_mem_read_ready(data_mem_read_ready), .data_mem_write_ready(data_mem_write_ready),
        .data_mem_read_addrs(data_mem_read_addrs), .data_mem_write_addrs(data_mem_write_addrs),
        .data_mem_read_datas(data_mem_read_datas), .data_mem_write_datas(data_mem_write_datas),
        
        .done(done)
    );

    always #5 clk = ~clk;

    // ---------------------------------------------------------
    // DYNAMIC EXTERNAL RAM CONTROLLER
    // ---------------------------------------------------------
    integer i;
    always @(posedge clk) begin
        // --- A. Program Memory (ROM) ---
        program_mem_read_ready[0] <= program_mem_read_valid[0]; 
        if (program_mem_read_valid[0] && !program_mem_read_ready[0]) begin
            // Serve the instruction directly from our loaded array!
            program_mem_read_datas[15:0] <= prog_mem[program_mem_read_addrs[7:0]];
        end

        // --- B. Data Memory (RAM) ---
        for(i = 0; i < 4; i = i + 1) begin
            data_mem_write_ready[i] <= data_mem_write_valid[i]; 
            data_mem_read_ready[i] <= data_mem_read_valid[i]; 
            
            // Handles Global Memory Reads (LDR instructions)
            if (data_mem_read_valid[i] && !data_mem_read_ready[i]) begin
                data_mem_read_datas[i*8 +: 8] <= data_mem[data_mem_read_addrs[i*8 +: 8]];
            end

            // Handles Global Memory Writes (STR instructions)
            if (data_mem_write_valid[i] && !data_mem_write_ready[i]) begin
                data_mem[data_mem_write_addrs[i*8 +: 8]] <= data_mem_write_datas[i*8 +: 8];
                $display("[%0t ns] MEM WRITE | Addr: %0d | Data: %0d", 
                         $time, data_mem_write_addrs[i*8 +: 8], data_mem_write_datas[i*8 +: 8]);
            end
        end
    end

    // ---------------------------------------------------------
    // MAIN EXECUTION SEQUENCE
    // ---------------------------------------------------------
    integer j;
    initial begin
        // NEW: Load the hex file into the program memory array!
        $readmemh("program.hex", prog_mem);

        // Clear data memory to 0
        for(j=0; j<256; j=j+1) data_mem[j] = 0;

        clk = 0; reset = 1; start = 0; device_control_write_enable = 0; device_control_data = 0;
        program_mem_read_ready = 0; program_mem_read_datas = 0;
        data_mem_read_ready = 0; data_mem_write_ready = 0; data_mem_read_datas = 0;

        #10 reset = 0;
        
        // Write to Device Control Register: We want 8 total threads
        device_control_write_enable = 1; device_control_data = 8'd8; 
        #10 device_control_write_enable = 0;
        
        $display("==================================================");
        $display(" EXECUTING EXTERNAL PROGRAM: program.hex");
        $display("==================================================");
        #10 start = 1;
        #10 start = 0;

        wait (done == 1);
        
        $display("==================================================");
        $display(" KERNEL COMPLETE.");
        $display("==================================================");
        #20 $finish;
    end
endmodule