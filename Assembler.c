#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int parse_reg(const char *reg_str) {
    int reg_num = 0;
    if (reg_str[0] == 'x' || reg_str[0] == 'X') {
        reg_num = atoi(&reg_str[1]);
    } else {
        reg_num = atoi(reg_str);
    }
    return reg_num & 0x1F;
}

int main() {
    char line[100];
    char op[10], token1[10], token2[10], token3[10];
    
    FILE *hex_file = fopen("program.hex", "w");
    if (hex_file == NULL) {
        printf("Error: Could not create program.hex file.\n");
        return 1;
    }

    printf("=== Interactive RISC-V Assembler for WSL ===\n");
    printf("Supports standard format: op rs2, rs1, imm OR space separated: op rs2 rs1 imm\n");
    printf("Type 'end' on a new line and press Enter to compile and finish.\n\n");

    while (1) {
        printf("asm > ");
        if (!fgets(line, sizeof(line), stdin)) break;

        line[strcspn(line, "\n")] = 0;

        if (strcmp(line, "end") == 0 || strcmp(line, "END") == 0) {
            break;
        }

        if (strlen(line) == 0) continue;

        char clean_line[100];
        int k = 0;
        for (int i = 0; line[i] != '\0'; i++) {
            if (line[i] != ',' && line[i] != '(' && line[i] != ')') {
                clean_line[k++] = line[i];
            } else {
                clean_line[k++] = ' '; // Convert punctuation symbols to clean whitespace delimiters
            }
        }
        clean_line[k] = '\0';

        int parse_count = sscanf(clean_line, "%s %s %s %s", op, token1, token2, token3);
        if (parse_count < 4) {
            printf("Format error! Use: op rs2, rs1, imm OR op rs2, imm(rs1)\n");
            continue;
        }

        unsigned int instr = 0;

        // =====================================================================
        // I-TYPE INSTR SUMMARY (addi, andi, ori, lw)
        // Format: op rd, rs1, imm -> sscanf maps: token1=rd, token2=rs1, token3=imm
        // Exception: lw rd, imm(rs1) -> sscanf maps: token1=rd, token2=imm, token3=rs1
        // =====================================================================
        if (strcmp(op, "addi") == 0 || strcmp(op, "andi") == 0 || strcmp(op, "ori") == 0) {
            int rd  = parse_reg(token1);
            int rs1 = parse_reg(token2);
            int imm = atoi(token3) & 0xFFF;
            int funct3 = (strcmp(op, "andi") == 0) ? 0x7 : ((strcmp(op, "ori") == 0) ? 0x6 : 0x0);
            
            instr = (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x13;
        } 
        else if (strcmp(op, "lw") == 0) {
            int rd  = parse_reg(token1);
            int imm = atoi(token2) & 0xFFF;
            int rs1 = parse_reg(token3);
            
            instr = (imm << 20) | (rs1 << 15) | (0x2 << 12) | (rd << 7) | 0x03;
        }
        // =====================================================================
        // R-TYPE INSTR SUMMARY (add, sub, and, or)
        // Format: op rd, rs1, rs2 -> sscanf maps: token1=rd, token2=rs1, token3=rs2
        // =====================================================================
        else if (strcmp(op, "sub") == 0 || strcmp(op, "add") == 0 || strcmp(op, "and") == 0 || strcmp(op, "or") == 0) {
            int rd  = parse_reg(token1);
            int rs1 = parse_reg(token2);
            int rs2 = parse_reg(token3);
            int funct7 = (strcmp(op, "sub") == 0) ? 0x20 : 0x00;
            int funct3 = (strcmp(op, "and") == 0) ? 0x7 : ((strcmp(op, "or") == 0) ? 0x6 : 0x0);
            
            instr = (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | 0x33;
        } 
        // =====================================================================
        // S-TYPE INSTR SUMMARY (sw)
        // Format: sw rs2, imm(rs1) OR sw rs2 rs1 imm 
        // Sscanf maps out: token1=rs2, token2=imm, token3=rs1
        // =====================================================================
        else if (strcmp(op, "sw") == 0) {
            int rs2 = parse_reg(token1);
            int imm = atoi(token2) & 0xFFF;
            int rs1 = parse_reg(token3);
            
            instr = ((imm & 0xFE0) << 20) | (rs2 << 20) | (rs1 << 15) | (0x2 << 12) | ((imm & 0x01F) << 7) | 0x23;
        }
        // =====================================================================
        // B-TYPE INSTR SUMMARY (beq)
        // Format: beq rs1, rs2, imm -> sscanf maps: token1=rs1, token2=rs2, token3=imm
        // =====================================================================
        else if (strcmp(op, "beq") == 0) {
            int rs1 = parse_reg(token1);
            int rs2 = parse_reg(token2);
            int imm = atoi(token3) & 0x1FFF;
            
            unsigned int imm12   = (imm >> 12) & 0x1;
            unsigned int imm11   = (imm >> 11) & 0x1;
            unsigned int imm10_5 = (imm >> 5)  & 0x3F;
            unsigned int imm4_1  = (imm >> 1)  & 0xF;
            
            instr = (imm12 << 31) | (imm10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (0x0 << 12) | (imm4_1 << 8) | (imm11 << 7) | 0x63;
        }
        else {
            printf("Instruction unknown or unsupported!\n");
            continue;
        }

        fprintf(hex_file, "%02x\n", (instr & 0xFF));
        fprintf(hex_file, "%02x\n", ((instr >> 8) & 0xFF));
        fprintf(hex_file, "%02x\n", ((instr >> 16) & 0xFF));
        fprintf(hex_file, "%02x\n", ((instr >> 24) & 0xFF));
    }

    // Zero-pad instruction blocks
    for (int pad = 0; pad < 16; pad++) {
        fprintf(hex_file, "00\n00\n00\n00\n");
    }

    fclose(hex_file);
    printf("\nCompilation finished successfully! Hex image saved to 'program.hex'.\n");
    return 0;
}
