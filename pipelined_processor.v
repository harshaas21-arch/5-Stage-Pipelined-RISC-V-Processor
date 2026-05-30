module pipelined_processor(
    input clk, 
    input rst
);

    // =========================================================================
    // 1. SIGNAL & ARCHITECTURAL REGISTERS DECLARATIONS
    // =========================================================================
    
    wire [31:0] Nxt_PC;
    reg  [31:0] PC_register;
    
    // Memory Sub-systems
    reg [7:0] Inst_memory [0:255]; 
    reg [7:0] Data_memory [0:255];
    
    // Core Decoding & Operational Wires
    wire [31:0] current_instruction;
    reg  MemRead, MemWrite;
    reg  RegWrite, MemtoReg;
    reg  [31:0] alu_result;
    wire [31:0] mem_read_data;
    wire [31:0] final_write_back_data;
    
    // Control Hazard Resolution Line
    wire PCSrc; 
    
    // Register File Storage & Ports
    reg  [31:0] Register_File [0:31];
    wire [31:0] reg_data1;
    wire [31:0] reg_data2;

    // -------------------------------------------------------------------------
    // PIPELINE REGISTER FIELDS (Stage Boundary Latches)
    // -------------------------------------------------------------------------
    
    // IF/ID Boundary Registers
    reg [31:0] IFID_instruction;
    reg [31:0] IFID_PC;
    
    // ID/EX Boundary Registers
    reg [31:0] IDEX_reg_data1;
    reg [31:0] IDEX_reg_data2;
    reg [31:0] IDEX_imm_ext;
    reg [4:0]  IDEX_rs1;
    reg [4:0]  IDEX_rs2;
    reg [4:0]  IDEX_rd;
    reg [2:0]  IDEX_funct3;
    reg [6:0]  IDEX_funct7;
    reg [6:0]  IDEX_opcode;
    reg [31:0] IDEX_PC;           
    reg        IDEX_MemRead;
    reg        IDEX_MemWrite;
    reg        IDEX_RegWrite;
    reg        IDEX_MemtoReg;
    
    // EX/MEM Boundary Registers
    reg [31:0] EXMEM_alu_result;
    reg [31:0] EXMEM_reg_data2;
    reg [4:0]  EXMEM_rd;
    reg [6:0]  EXMEM_opcode;
    reg        EXMEM_MemRead;
    reg        EXMEM_MemWrite;
    reg        EXMEM_RegWrite;
    reg        EXMEM_MemtoReg;
    
    // MEM/WB Boundary Registers
    reg [31:0] MEMWB_alu_result;
    reg [31:0] MEMWB_mem_read_data;
    reg [4:0]  MEMWB_rd;
    reg [6:0]  MEMWB_opcode;
    reg        MEMWB_RegWrite;
    reg        MEMWB_MemtoReg;

    // Asynchronous Hardware Power-On Reset Initialization
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            Register_File[i] = 32'h0;
        end
    end

    // =========================================================================
    // STAGE 1: INSTRUCTION FETCH (IF)
    // =========================================================================
    
    // Combinational Next PC Evaluation Loop (Chooses branch target if branch is taken)
    assign Nxt_PC = (PCSrc) ? (IDEX_PC + IDEX_imm_ext) : (PC_register + 4);

    // Synchronous PC Program Register State Machine
    always @(posedge clk) begin
        if (rst) 
            PC_register <= 32'h0;
        else
            PC_register <= Nxt_PC;
    end

    // Combinational Little-Endian Byte Stitching from Program ROM
    assign current_instruction = { Inst_memory[PC_register + 3], 
                                   Inst_memory[PC_register + 2], 
                                   Inst_memory[PC_register + 1], 
                                   Inst_memory[PC_register] };

    // Synchronous Pipeline Intermediary: IF/ID (With Control Hazard Flushing)
    always @(posedge clk) begin
        if (rst || PCSrc) begin
            IFID_instruction <= 32'h0;
            IFID_PC          <= 32'h0;
        end else begin
            IFID_instruction <= current_instruction;
            IFID_PC          <= PC_register;
        end
    end

    // =========================================================================
    // STAGE 2: INSTRUCTION DECODE / OPERAND FETCH (ID)
    // =========================================================================
    
    // Combinational Field Extraction Maps
    wire [6:0] opcode = IFID_instruction[6:0];
    wire [4:0] rd     = IFID_instruction[11:7];
    wire [2:0] funct3 = IFID_instruction[14:12];
    wire [4:0] rs1    = IFID_instruction[19:15];
    wire [4:0] rs2    = IFID_instruction[24:20];
    wire [6:0] funct7 = IFID_instruction[31:25];
    
    // Asymmetric Immediate Generator Logic (Supports I-Type, S-Type, and B-Type Layouts)
    reg [31:0] imm_ext;
    always @(*) begin
        if (opcode == 7'b0100011) begin
            // S-type instruction layout (sw)
            imm_ext = { {20{IFID_instruction[31]}}, IFID_instruction[31:25], IFID_instruction[11:7] };
        end else if (opcode == 7'b1100011) begin
            // B-type instruction layout (beq)
            imm_ext = { {20{IFID_instruction[31]}}, IFID_instruction[7], IFID_instruction[30:25], IFID_instruction[11:8], 1'b0 };
        end else begin
            // Standard I-type instruction layout (addi, lw, andi, ori)
            imm_ext = { {20{IFID_instruction[31]}}, IFID_instruction[31:20] };
        end
    end

    // Register File Asynchronous Dual Read Interface
    assign reg_data1 = (rs1 == 5'b0) ? 32'h0 : Register_File[rs1];
    assign reg_data2 = (rs2 == 5'b0) ? 32'h0 : Register_File[rs2];

    // Combinational Main Control Decoder 
    always @(*) begin
        MemRead  = 1'b0;
        MemWrite = 1'b0;
        RegWrite = 1'b0;
        MemtoReg = 1'b0;
        
        case (opcode)
            7'b0110011: begin // R-type (add, sub, and, or)
                RegWrite = 1'b1;
                MemtoReg = 1'b0;
            end
            7'b0010011: begin // I-type arithmetic & logic (addi, andi, ori)
                RegWrite = 1'b1;
                MemtoReg = 1'b0;
            end
            7'b0000011: begin // lw
                MemRead  = 1'b1;
                RegWrite = 1'b1;
                MemtoReg = 1'b1;
            end
            7'b0100011: begin // sw
                MemWrite = 1'b1;
                RegWrite = 1'b0;
                MemtoReg = 1'b0;
            end
            7'b1100011: begin // beq
                MemWrite = 1'b0;
                RegWrite = 1'b0;
                MemtoReg = 1'b0;
            end
        endcase
    end

    // Synchronous Pipeline Intermediary: ID/EX
    always @(posedge clk) begin
        if (rst) begin 
            IDEX_reg_data1 <= 32'h0;
            IDEX_reg_data2 <= 32'h0;
            IDEX_imm_ext   <= 32'h0;
            IDEX_rd        <= 5'h0;
            IDEX_funct3    <= 3'h0;
            IDEX_funct7    <= 7'h0;
            IDEX_opcode    <= 7'h0;
            IDEX_rs1       <= 5'h0;
            IDEX_rs2       <= 5'h0;
            IDEX_PC        <= 32'h0;
            IDEX_MemRead   <= 1'b0;
            IDEX_MemWrite  <= 1'b0;
            IDEX_RegWrite  <= 1'b0;
            IDEX_MemtoReg  <= 1'b0;
        end else begin
            IDEX_reg_data1 <= reg_data1;
            IDEX_reg_data2 <= reg_data2;
            IDEX_imm_ext   <= imm_ext;
            IDEX_rd        <= rd;
            IDEX_funct3    <= funct3;
            IDEX_funct7    <= funct7;
            IDEX_rs1       <= rs1;
            IDEX_rs2       <= rs2;
            IDEX_PC        <= IFID_PC;
            
            if (PCSrc) begin
                // Direct clean single-path NOP bubble override injection
                IDEX_opcode    <= 7'b0;
                IDEX_MemRead   <= 1'b0;
                IDEX_MemWrite  <= 1'b0;
                IDEX_RegWrite  <= 1'b0;
                IDEX_MemtoReg  <= 1'b0;
            end else begin
                IDEX_opcode    <= opcode;
                IDEX_MemRead   <= MemRead;
                IDEX_MemWrite  <= MemWrite;
                IDEX_RegWrite  <= RegWrite;
                IDEX_MemtoReg  <= MemtoReg;
            end
        end
    end

    // =========================================================================
    // STAGE 3: EXECUTE / ADDRESS GENERATION (EX)
    // =========================================================================
    
    reg [31:0] forwarded_val1;
    reg [31:0] forwarded_val2;
    wire [31:0] alu_operand2;

    // Operand 1 Forwarding Matrix Selector Loop
    always @(*) begin
        if (EXMEM_rd != 5'b0 && EXMEM_rd == IDEX_rs1 && EXMEM_RegWrite) begin
            forwarded_val1 = EXMEM_alu_result; // EX-to-EX Hazard
        end else if (MEMWB_rd != 5'b0 && MEMWB_rd == IDEX_rs1 && MEMWB_RegWrite) begin
            forwarded_val1 = final_write_back_data; // MEM-to-EX Hazard (Bridges WB to EX stage)
        end else begin
            forwarded_val1 = IDEX_reg_data1; 
        end
    end

    // Operand 2 Forwarding Matrix Selector Loop
    always @(*) begin
        if (EXMEM_rd != 5'b0 && EXMEM_rd == IDEX_rs2 && EXMEM_RegWrite) begin
            forwarded_val2 = EXMEM_alu_result; // FIXED: Successfully isolated from forwarded_val1
        end else if (MEMWB_rd != 5'b0 && MEMWB_rd == IDEX_rs2 && MEMWB_RegWrite) begin
            forwarded_val2 = final_write_back_data; // MEM-to-EX Hazard (Bridges WB to EX stage)
        end else begin
            forwarded_val2 = IDEX_reg_data2; 
        end
    end

    // ALU Secondary Operand Source Ingestion Selector Multiplexer
    assign alu_operand2 = (IDEX_opcode == 7'b0110011) ? forwarded_val2 : IDEX_imm_ext;

    // Control Hazard Decision: Assert PCSrc if instruction is a branch AND values match
    assign PCSrc = (IDEX_opcode == 7'b1100011) && (forwarded_val1 == forwarded_val2);

    // Expanded Mathematical ALU Calculation Engine (Nested Case Matrix)
    always @(*) begin
        alu_result = 32'h0;
        case (IDEX_opcode)
            7'b0110011: begin // R-type Instructions (Register-to-Register)
                case (IDEX_funct3)
                    3'b000: begin
                        if (IDEX_funct7 == 7'b0100000)
                            alu_result = forwarded_val1 - forwarded_val2; // sub
                        else
                            alu_result = forwarded_val1 + forwarded_val2; // add
                    end
                    3'b110:  alu_result = forwarded_val1 | forwarded_val2; // or
                    3'b111:  alu_result = forwarded_val1 & forwarded_val2; // and
                    default: alu_result = 32'h0;
                endcase
            end
            
            7'b0010011: begin // I-type Arithmetic & Logical Instructions (Register-Immediate)
                case (IDEX_funct3)
                    3'b000:  alu_result = forwarded_val1 + alu_operand2; // addi
                    3'b110:  alu_result = forwarded_val1 | alu_operand2; // ori
                    3'b111:  alu_result = forwarded_val1 & alu_operand2; // andi
                    default: alu_result = 32'h0;
                endcase
            end
            
            7'b0000011, 7'b0100011: begin 
                alu_result = forwarded_val1 + alu_operand2; // lw / sw Address Generation
            end
            
            default: alu_result = 32'h0;
        endcase
    end

    // Synchronous Pipeline Intermediary: EX/MEM
    always @(posedge clk) begin
        if (rst) begin
            EXMEM_alu_result <= 32'h0;
            EXMEM_reg_data2  <= 32'h0;
            EXMEM_rd         <= 5'h0;
            EXMEM_opcode     <= 7'h0;
            EXMEM_MemRead    <= 1'b0;
            EXMEM_MemWrite   <= 1'b0;
            EXMEM_RegWrite   <= 1'b0;
            EXMEM_MemtoReg   <= 1'b0;
        end else begin
            EXMEM_alu_result <= alu_result;
            EXMEM_reg_data2  <= forwarded_val2; 
            EXMEM_rd         <= IDEX_rd;
            
            if (PCSrc) begin
                // Wipes out trailing hazard control instructions smoothly
                EXMEM_opcode     <= 7'b0;
                EXMEM_MemRead    <= 1'b0;
                EXMEM_MemWrite   <= 1'b0;
                EXMEM_RegWrite   <= 1'b0;
                EXMEM_MemtoReg   <= 1'b0;
            end else begin
                EXMEM_opcode     <= IDEX_opcode;
                EXMEM_MemRead    <= IDEX_MemRead;
                EXMEM_MemWrite   <= IDEX_MemWrite;
                EXMEM_RegWrite   <= IDEX_RegWrite;
                EXMEM_MemtoReg   <= IDEX_MemtoReg;
            end
        end
    end

    // =========================================================================
    // STAGE 4: DATA MEMORY ACCESS (MEM)
    // =========================================================================
    assign mem_read_data = (EXMEM_MemRead) ? { Data_memory[EXMEM_alu_result + 3],
                                               Data_memory[EXMEM_alu_result + 2],
                                               Data_memory[EXMEM_alu_result + 1],
                                               Data_memory[EXMEM_alu_result] } : 32'h0;

    always @(posedge clk) begin
        if (EXMEM_MemWrite) begin
            Data_memory[EXMEM_alu_result]     <= EXMEM_reg_data2[7:0];
            Data_memory[EXMEM_alu_result + 1] <= EXMEM_reg_data2[15:8];
            Data_memory[EXMEM_alu_result + 2] <= EXMEM_reg_data2[23:16];
            Data_memory[EXMEM_alu_result + 3] <= EXMEM_reg_data2[31:24];
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            MEMWB_alu_result    <= 32'h0;
            MEMWB_mem_read_data <= 32'h0;
            MEMWB_rd            <= 5'h0;
            MEMWB_opcode        <= 7'h0;
            MEMWB_RegWrite      <= 1'b0;
            MEMWB_MemtoReg      <= 1'b0;
        end else begin
            MEMWB_alu_result    <= EXMEM_alu_result;
            MEMWB_mem_read_data <= mem_read_data;
            MEMWB_rd            <= EXMEM_rd;
            MEMWB_opcode        <= EXMEM_opcode;
            MEMWB_RegWrite      <= EXMEM_RegWrite;
            MEMWB_MemtoReg      <= EXMEM_MemtoReg;
        end
    end

    // =========================================================================
    // STAGE 5: WRITE-BACK (WB)
    // =========================================================================
    assign final_write_back_data = (MEMWB_MemtoReg) ? MEMWB_mem_read_data : MEMWB_alu_result;

    always @(posedge clk) begin
        if (!rst && MEMWB_RegWrite && MEMWB_rd != 5'b0) begin
            Register_File[MEMWB_rd] <= final_write_back_data;
        end
    end

endmodule
