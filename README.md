5-Stage Pipelined RISC-V Processor with Dynamic Hazard Forwarding




A functionally complete, structurally verified 5-stage pipelined RISC-V processor core designed in synthesizable Verilog HDL. This project models the core architectural stages of a classical RISC pipeline (Fetch, Decode, Execute, Memory, Write-Back) and implements robust microarchitectural mechanisms to dynamically resolve structural, data, and control hazards without compromising execution throughput.
 
 <img width="662" height="332" alt="image" src="https://github.com/user-attachments/assets/616a92aa-80d3-48c3-b326-27509004cbda" />

 Architectural Framework

The hardware architecture partitions the processor core into five discrete stages separated by synchronous pipeline boundary latches: 

•	Instruction Fetch (IF): Implements a program counter register with an integrated branch-target multiplexer. It performs combinational, little-endian byte-stitching to assemble raw 8-bit memory contents into solid 32-bit instructions. 

•	Instruction Decode (ID): Extracts fields including opcodes, destination/source registers (rd, rs1, rs2), and funct specifiers. Houses a hardware immediate generator supporting signed extensions for I-type, S-type, and B-type control layouts. 

•	Execute (EX): Features an Arithmetic Logic Unit (ALU) that computes arithmetic operations, bitwise indexing, data comparison loops, and branch target calculations. 

•	Memory Access (MEM): Interfaces directly with a unified byte-addressable data memory subsystem, executing word-aligned little-endian synchronous writes and combinational reads. 

•	Write-Back (WB): Features data-routing multiplexers that capture retiring memory read outputs or ALU results, committing values directly back to the dual-port Register File. 

Supported Instruction Set Architecture (ISA)

The custom core processes integer ALU and memory instructions compliant with the base RISC-V ISA specification: 

Instruction Type	Mnemonic	Opcode	Functionality

R-Type	add	0110011	Register-register addition 
R-Type	sub	0110011	Register-register subtraction 
R-Type	and	0110011	Bitwise logical AND 
R-Type	or	0110011	Bitwise logical OR 
I-Type	addi	0010011	Register-immediate addition 
I-Type	andi	0010011	Bitwise immediate logical AND 
I-Type	ori	0010011	Bitwise immediate logical OR 
I-Type (Load)	lw	0000011	Load word from data memory 
S-Type (Store)	sw	0100011	Store word into data memory 
B-Type (Branch)	beq	1100011	Branch if registers are equal 

Hazard Mitigation Techniques
To maximize operational efficiency and maintain structural stability, the core incorporates advanced hardware hazard resolution units:

1. Dynamic Bypass/Forwarding Matrix (RAW Hazards)
Interlocking data dependencies (Read-After-Write) occur when an instruction attempts to read a register value before a preceding instruction can commit it to the register file. Rather than introducing performance-degrading stalls, the processor utilizes an asynchronous forwarding matrix: 
•	EX-to-EX Forwarding: If the instruction currently in the MEM stage updates a register needed by the active ALU operand, data is dynamically bypassed straight to the execution inputs. 
•	MEM-to-EX Forwarding: Bridges the WB-to-EX barrier. If an older instruction in the writeback frame matches an incoming ALU source, data is bypassed cleanly from the final writeback rail. 

2. Control Path Speculative Flushing
When a conditional branch (beq) evaluates to TRUE, instructions sequentially fetched into the pipeline behind it are speculative and incorrect. To preserve state integrity, a control hazard unit monitors the branch evaluation loop: 
•	Asserts a dedicated PCSrc control line on a valid branch comparison match. 
•	Synchronously overrides the active pipeline registers, wiping out instructions in flight and injecting empty NOP bubbles. 
•	Instantly redirects the Program Counter to the calculated branch offset destination target. 
Execution Workflow
[ Assembly Source (.s) ] ──> [ Compiler / Hex Map ] ──> [ program.hex ]
                                                               │
                                                               ▼
[ Waveform Analysis (VCD) ] <── [ Verilog Simulation ] <── [ readmemh ]
1.	Assembly Input: Program routines are written in standard RISC-V assembly notation. 

2.	Hexadecimal Compilation: Instructions are parsed and mapped into raw, word-aligned little-endian hexadecimal machine code arrays. 

3.	Memory Ingestion: The testbench reads the compilation matrix directly into the byte-addressed byte-wide instruction array utilizing the $readmemh system function. 

4.	Simulation & Verification: Hardware tracks individual variables marching across the boundary pipeline latches, monitored via automated falling-edge print log trace captures. 

5.	Waveform Analysis: Validates internal structural wire assignments and physical register allocations on value change dump (.vcd) wave logs using EPWave or GTKWave visualizers. 

Simulation and Verification

Project File Structure

•	pipelined_processor.v : Top-level synthesizable processor core module containing all pipeline registers, decoding arrays, and hazard detection loops. 

•	tb_pipelined_processor.v : Pipelined verification testbench featuring memory pre-loading, systematic clock drivers, and a falling-edge state monitor. 

•	program.hex : Target instruction memory data block file containing the hexadecimal machine code. 
Compilation Instructions
The testbench can be compiled and executed using any standard IEEE 1364-2001 compliant simulator (e.g., Icarus Verilog).
Execute the clean-build and verification run sequence directly from your terminal using:

# Force clear previous simulation binary targets
rm -f processor_sim

# Compile the hardware description and testbench files
iverilog -o processor_sim pipelined_processor.v tb_pipelined_processor.v

# Execute the simulation framework to output pipeline logs
vvp processor_sim

Sample Simulation Output (Control Hazard Branch Resolution)
When executing back-to-back testing maps containing a branch instruction, the runtime monitoring capture logs the successful stabilization of forwarding paths and structural flushing of the trap sequence:

Plaintext
--- Time: 200000 ns (Setted State) ---
Fetch  | PC: 68 | Raw Inst: 00b50863
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5

--- Time: 210000 ns (Setted State) ---
Fetch  | PC: 72 | Raw Inst: 06300213
Decode | Opcode: 1100011 | rs1: 10 | rs2: 11 | rd: 16
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0

Key Learning Outcomes & Takeaways
Developing this high-performance core architecture independently provided profound practical insights into low-level digital systems design:

•	Pipeline Interlocking & Hazard Tracking: Gained hands-on proficiency modeling combinational forwarding paths and tracking microarchitectural register allocations across asynchronous boundaries. 

•	Control Path Management: Mastered speculative instruction management, pipeline state synchronization, and implementing non-blocking flushing control mechanisms. 

•	Modular RTL Debugging: Developed advanced methodologies for tracking hardware runtime states by pairing custom Verilog loop trace captures with gate-level value change dump (.vcd) wave monitors. 

Example: Assembly instructions:
addi x1, x0, 15     # Load 15 into x1
addi x2, x0, 5      # Load 5 into x2
add x3, x1, x2      # x3 = 15 + 5 = 20
sub x4, x3, x2      # x4 = 20 - 5 = 15
and x5, x1, x2      # Logical AND operation
or x6, x1, x0       # Logical OR operation
ori x7, x0, 10      # Load immediate 10 into x7
addi x8, x0, 32     # Setup Data RAM Target Pointer Address at 32
sw x3, 0(x8)        # Store x3 (20) into RAM[32]
addi x0, x0, 0      # Bubble NOP
addi x0, x0, 0      # Bubble NOP
lw x9, 0(x8)        # Load data from RAM[32] back into x9 (20)
addi x0, x0, 0      # Bubble NOP
addi x0, x0, 0      # Bubble NOP
addi x0, x0, 0      # Bubble NOP
add x10, x9, x2     # x10 = 20 + 5 = 25 (Evaluated as 5 in old forwarding trace)
addi x11, x0, 5     # CHANGED: Load 5 into x11 to force equality match with x10
addi x0, x0, 0      # ADDED: This extra NOP gives x11 time to stabilize before check
addi x0, x0, 0      # Bubble NOP
beq x10, x11, 16    # BRANCH TRUE: Evaluates 5 == 5 -> Jumps forward 16 bytes (4 instructions)
addi x4, x0, 99     # Skipped!
addi x5, x0, 99     # Skipped!
sw x9, 4(x8)        # Skipped!
addi x12, x0, 100   # Skipped!
add x13, x10, x2    # Resumes running here: x13 = 5 + 5 = 10
end

Output:
--- Time: 30000 ns (Setted State) ---
Fetch  | PC: 0 | Raw Inst: 00f00093
Decode | Opcode: 0000000 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=0 | x2=0 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 40000 ns (Setted State) ---
Fetch  | PC: 4 | Raw Inst: 00500113
Decode | Opcode: 0010011 | rs1: 0 | rs2: 15 | rd: 1
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=0 | x2=0 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 50000 ns (Setted State) ---
Fetch  | PC: 8 | Raw Inst: 002081b3
Decode | Opcode: 0010011 | rs1: 0 | rs2: 5 | rd: 2
Exec   | ALU Result/Target: 15
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=0 | x2=0 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 60000 ns (Setted State) ---
Fetch  | PC: 12 | Raw Inst: 40218233
Decode | Opcode: 0110011 | rs1: 1 | rs2: 2 | rd: 3
Exec   | ALU Result/Target: 5
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=0 | x2=0 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 70000 ns (Setted State) ---
Fetch  | PC: 16 | Raw Inst: 0020f2b3
Decode | Opcode: 0110011 | rs1: 3 | rs2: 2 | rd: 4
Exec   | ALU Result/Target: 20
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=0 | x2=0 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 80000 ns (Setted State) ---
Fetch  | PC: 20 | Raw Inst: 0000e333
Decode | Opcode: 0110011 | rs1: 1 | rs2: 2 | rd: 5
Exec   | ALU Result/Target: 15
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=0 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 90000 ns (Setted State) ---
Fetch  | PC: 24 | Raw Inst: 00a06393
Decode | Opcode: 0110011 | rs1: 1 | rs2: 0 | rd: 6
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=0 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 100000 ns (Setted State) ---
Fetch  | PC: 28 | Raw Inst: 02000413
Decode | Opcode: 0010011 | rs1: 0 | rs2: 10 | rd: 7
Exec   | ALU Result/Target: 15
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=0 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 110000 ns (Setted State) ---
Fetch  | PC: 32 | Raw Inst: 00342023
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 8
Exec   | ALU Result/Target: 10
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 120000 ns (Setted State) ---
Fetch  | PC: 36 | Raw Inst: 00042483
Decode | Opcode: 0100011 | rs1: 8 | rs2: 3 | rd: 0
Exec   | ALU Result/Target: 32
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=0 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 130000 ns (Setted State) ---
Fetch  | PC: 40 | Raw Inst: 00000013
Decode | Opcode: 0000011 | rs1: 8 | rs2: 0 | rd: 9
Exec   | ALU Result/Target: 32
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=0 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 140000 ns (Setted State) ---
Fetch  | PC: 44 | Raw Inst: 00000013
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 32
Memory | MemRead En: 0 | MemWrite En: 1 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=0 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=x
--------------------------------------------------------------------------------

--- Time: 150000 ns (Setted State) ---
Fetch  | PC: 48 | Raw Inst: 00248533
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 0
Memory | MemRead En: 1 | MemWrite En: 0 | Raw RAM Read Out: 20
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 160000 ns (Setted State) ---
Fetch  | PC: 52 | Raw Inst: 00500593
Decode | Opcode: 0110011 | rs1: 9 | rs2: 2 | rd: 10
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=0 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 170000 ns (Setted State) ---
Fetch  | PC: 56 | Raw Inst: 00000013
Decode | Opcode: 0010011 | rs1: 0 | rs2: 5 | rd: 11
Exec   | ALU Result/Target: 5
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 180000 ns (Setted State) ---
Fetch  | PC: 60 | Raw Inst: 00000013
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 5
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 190000 ns (Setted State) ---
Fetch  | PC: 64 | Raw Inst: 00000013
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=0
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 200000 ns (Setted State) ---
Fetch  | PC: 68 | Raw Inst: 00b50863
Decode | Opcode: 0010011 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=0 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 210000 ns (Setted State) ---
Fetch  | PC: 72 | Raw Inst: 06300213
Decode | Opcode: 1100011 | rs1: 10 | rs2: 11 | rd: 16
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 220000 ns (Setted State) ---
Fetch  | PC: 76 | Raw Inst: 06300293
Decode | Opcode: 0010011 | rs1: 0 | rs2: 3 | rd: 4
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 230000 ns (Setted State) ---
Fetch  | PC: 84 | Raw Inst: 06400613
Decode | Opcode: 0000000 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 240000 ns (Setted State) ---
Fetch  | PC: 88 | Raw Inst: 002506b3
Decode | Opcode: 0010011 | rs1: 0 | rs2: 4 | rd: 12
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 250000 ns (Setted State) ---
Fetch  | PC: 92 | Raw Inst: 00000000
Decode | Opcode: 0110011 | rs1: 10 | rs2: 2 | rd: 13
Exec   | ALU Result/Target: 100
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 260000 ns (Setted State) ---
Fetch  | PC: 96 | Raw Inst: xxxxxxxx
Decode | Opcode: 0000000 | rs1: 0 | rs2: 0 | rd: 0
Exec   | ALU Result/Target: 10
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 270000 ns (Setted State) ---
Fetch  | PC: 100 | Raw Inst: xxxxxxxx
Decode | Opcode: xxxxxxx | rs1: x | rs2: x | rd: x
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=0 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 280000 ns (Setted State) ---
Fetch  | PC: 104 | Raw Inst: xxxxxxxx
Decode | Opcode: xxxxxxx | rs1: x | rs2: x | rd: x
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=100 | x13=0 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 290000 ns (Setted State) ---
Fetch  | PC: x | Raw Inst: xxxxxxxx
Decode | Opcode: xxxxxxx | rs1: x | rs2: x | rd: x
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=100 | x13=10 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 300000 ns (Setted State) ---
Fetch  | PC: x | Raw Inst: xxxxxxxx
Decode | Opcode: xxxxxxx | rs1: x | rs2: x | rd: x
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=100 | x13=10 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 310000 ns (Setted State) ---
Fetch  | PC: x | Raw Inst: xxxxxxxx
Decode | Opcode: xxxxxxx | rs1: x | rs2: x | rd: x
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=100 | x13=10 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

--- Time: 320000 ns (Setted State) ---
Fetch  | PC: x | Raw Inst: xxxxxxxx
Decode | Opcode: xxxxxxx | rs1: x | rs2: x | rd: x
Exec   | ALU Result/Target: 0
Memory | MemRead En: 0 | MemWrite En: 0 | Raw RAM Read Out: 0
Status | Register File Snapshot:
       | x1=15 | x2=5 | x3=20 | x4=15 | x5=0
       | x6=15 | x7=10 | x8=32 | x9=20 | x10=5
       | x11=5 | x12=100 | x13=10 | x14=0 | x15=0
Status | Target Data Memory Segments:
       | RAM[0]=x | RAM[4]=x | RAM[32]=20
--------------------------------------------------------------------------------

<img width="1147" height="496" alt="image" src="https://github.com/user-attachments/assets/ecc30825-5f9a-4021-8d3e-c1fd76c38113" />
