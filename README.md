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
Bash
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

