`timescale 1ns / 1ps

module tb_pipelined_processor();

    reg clk;
    reg rst;

    pipelined_processor uut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_pipelined_processor);
    end
  
    always begin
        #5 clk = ~clk;
    end

    // Dynamic File Ingestion Routine
    initial begin
        $readmemh("program.hex", uut.Inst_memory);
    end

    initial begin
        clk = 0;
        rst = 1;
        #20;
        @(posedge clk);
        #1 rst = 0;
        
        repeat (30) @(posedge clk);
        $finish;
    end

    // =========================================================================
    // CORRECTED FALLING EDGE MONITOR: Captures settled, accurate states
    // =========================================================================
    always @(negedge clk) begin
        if (!rst) begin
            $display("--- Time: %0t ns (Setted State) ---", $time);
            
            // 1. Fetch Stage: Look at the actual un-latched wire values
            $display("Fetch  | PC: %0d | Raw Inst: %h", uut.PC_register, uut.current_instruction);
            
            // 2. Decode Stage: Look at what is CURRENTLY inside the IFID register being decoded
            $display("Decode | Opcode: %b | rs1: %0d | rs2: %0d | rd: %0d", uut.opcode, uut.rs1, uut.rs2, uut.rd);
            
            // 3. Execute Stage: Look at the live ALU output calculation right now
            $display("Exec   | ALU Result/Target: %0d", uut.alu_result);
            
            // 4. Memory Stage: Look at the active RAM pins right now
            $display("Memory | MemRead En: %b | MemWrite En: %b | Raw RAM Read Out: %0d", uut.EXMEM_MemRead, uut.EXMEM_MemWrite, uut.mem_read_data);
            
            // 5. Architectural State Snapshots
            $display("Status | Register File Snapshot:");
            $display("       | x1=%0d | x2=%0d | x3=%0d | x4=%0d | x5=%0d", uut.Register_File[1], uut.Register_File[2], uut.Register_File[3], uut.Register_File[4], uut.Register_File[5]);
            $display("       | x6=%0d | x7=%0d | x8=%0d | x9=%0d | x10=%0d", uut.Register_File[6], uut.Register_File[7], uut.Register_File[8], uut.Register_File[9], uut.Register_File[10]);
            $display("       | x11=%0d | x12=%0d | x13=%0d | x14=%0d | x15=%0d", uut.Register_File[11], uut.Register_File[12], uut.Register_File[13], uut.Register_File[14], uut.Register_File[15]);
            
            $display("Status | Target Data Memory Segments:");
            $display("       | RAM[0]=%0d | RAM[4]=%0d | RAM[32]=%0d", uut.Data_memory[0], uut.Data_memory[4], uut.Data_memory[32]);
            $display("--------------------------------------------------------------------------------\n");
        end
    end
endmodule
