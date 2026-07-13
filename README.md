# GP-GPU Architecture Implementation

## Overview
The design is a multi-core GPU architecture centered around a central dispatcher and memory controllers. This repository contains the complete Verilog source code and testbenches for the GPU implementation. 

The architecture is designed to be parameterizable; variables such as `NUM_CORE` and `THREADS_PER_BLOCK` can be adjusted prior to synthesis. This provides flexibility to scale the hardware footprint according to available resources or basic deployment needs.

## Hardware Hierarchy
The design is modular, breaking down into a top-level GPU module that routes into specific processing cores and their respective datapath components.

| Module | Description |
| ------ | ----------- |
| `gpu.v` | Top-level module. Contains the Dispatcher, Memory Controllers, DCR, and multiple Cores. |
| `dcr.v` | Device Control Register. The primary communication gateway between the host CPU and the GPU; captures the `thread_count`. |
| `dispatcher.v` | Responsible for workload distribution. Calculates blocks and assigns them to available cores. |
| `controller.v` | Memory controllers for Program and Data Memory. Arbitrates memory access between consumers via a state machine. |
| `core.v` | Instantiates and connects the core-level control modules and SIMT thread datapath components. |
| `fetcher.v` | Interfaces with global program memory to retrieve instructions. |
| `decoder.v` | Purely combinational logic that parses 16-bit instructions into control signals and register addresses. |
| `scheduler.v` | The central brain of the core. Manages the 8-state execution pipeline ensuring synchronous thread execution. |
| `regfile.v` | Manages thread-specific registers. Hardcodes `R[15]` with THREAD_ID, `R[14]` with THREADS_PER_BLOCK, and `R[13]` with BLOCK_ID. |
| `alu.v` | Handles arithmetic operations (ADD, SUB, MUL, DIV) and simultaneously calculates NZP condition flags. |
| `lsu.v` | Load/Store Unit. Handles read/write operations to the global data memory. |
| `pc.v` | Program counter logic. Calculates the next instruction address for the block. |

## Instruction Set Architecture (ISA)
The system utilizes a custom 16-bit instruction format. The fields generally extract the Opcode at bits `[15:12]`, Destination Register (Rd) at bits `[11:8]`, Source Register 1 (Rs) at bits `[7:4]`, and either Source Register 2 (Rt) at bits `[3:0]` or an 8-bit Immediate value at bits `[7:0]`.

| Mnemonic | Opcode (Binary) | Semantics |
| -------- | --------------- | --------- |
| **NOP** | `0000` | No Operation. `PC = PC + 1` |
| **BRnzp**| `0001` | Branch if Negative/Zero/Positive flags match condition. |
| **CMP** | `0010` | Set NZP flags: `NZP = sign(Rs - Rt)` |
| **ADD** | `0011` | `Rd = Rs + Rt` |
| **SUB** | `0100` | `Rd = Rs - Rt` |
| **MUL** | `0101` | `Rd = Rs * Rt` |
| **DIV** | `0110` | `Rd = Rs / Rt` (Outputs `0xFF` if dividing by zero) |
| **LDR** | `0111` | Load from memory: `Rd = data_mem[Rs]` |
| **STR** | `1000` | Store to memory: `data_mem[Rs] = Rt` |
| **CONST**| `1001` | Load constant: `Rd = IMM8` |
| **RET** | `1111` | Signal completion of thread execution. |

## Pipeline State Machines
The execution pipeline relies on the synchronization of multiple state machines across the core modules:
- **Scheduler States:** Cycles through `IDLE`, `FETCH`, `DECODE`, `REQUEST`, `WAIT`, `EXECUTE`, `UPDATE`, and `DONE`. Note: Memory instructions (`LDR`/`STR`) route to `WAIT` and bypass `EXECUTE` directly to `UPDATE` to protect ALU flags and save clock cycles.
- **Fetcher States:** Cycles between `IDLE`, `FETCHING` (waiting for memory), and `FETCHED` (instruction ready).
- **LSU States:** Handles memory latency via `IDLE`, `REQUESTING`, `WAITING`, and `DONE`.
- **Memory Controller:** Arbitrates memory access using states like `READ_WAITING`, `WRITE_WAITING`, `READ_RELAYING`, and `WRITE_RELAYING`.

## SIMT Execution & Thread Addressing
This GP-GPU follows a Single Instruction, Multiple Threads (SIMT) execution model. 
- **Thread Offsets (Software-Level):** Instead of hardware-level base + offset memory addressing, global thread addresses are calculated in software. Because the `regfile.v` initializes `R[15]` with the thread's hardware ID upon reset, assembly programs can use the ALU to calculate unique memory addresses before issuing memory operations.
- **Control Flow & The "Dictator" Thread:** To handle control flow without execution masking or a divergence stack, Thread 0 acts as the "Dictator Thread". Thread 0 drives the shared Program Counter (`new_pc`) for the entire block, meaning divergent threads are forcefully synchronized to Thread 0's execution path.

## Acknowledgements
This GPU was built with the inspiration and reference from the [tiny-GPU](https://github.com/adam-maj/tiny-gpu) by Adam Majmudar.
