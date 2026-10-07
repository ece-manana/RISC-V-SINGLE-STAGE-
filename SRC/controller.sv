`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.09.2026 11:11:05
// Design Name: 
// Module Name: controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module controller (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic       funct7b5,
    input  logic       take_branch,
    output logic [1:0] result_src,   // 00=ALU, 01=DataMem, 10=PC+4, 11=ImmExt (LUI)
    output logic       mem_write,
    output logic [1:0] mem_size,
    output logic       mem_unsigned,
    output logic [1:0] alu_src_a,    // 00=rs1, 01=PC (AUIPC), 10=Zero (LUI)
    output logic       alu_src_b,    // 0=rs2, 1=Imm
    output logic       reg_write,
    output logic [2:0] imm_src,      // 000=I, 001=S, 010=B, 011=J, 100=U
    output logic [3:0] alu_control,  // Expanded to 4 bits for shifts/xor
    output logic [2:0] branch_type,  // Connects directly to funct3 for branches
    output logic       jump,         // JAL
    output logic       jump_reg,     // JALR
    output logic       branch
);

    logic [1:0] alu_op; // 00=Add, 01=Sub, 10=Decode funct3/7

    always_comb begin
        // Defaults to avoid latches
        reg_write    = 1'b0; mem_write = 1'b0; 
        jump         = 1'b0; jump_reg  = 1'b0;
        alu_src_a    = 2'b00; alu_src_b = 1'b0; 
        result_src   = 2'b00; imm_src = 3'b000;
        alu_op       = 2'b00; branch_type = 3'b000;
        mem_size     = 2'b10; mem_unsigned = 1'b0;
        branch = 1'b0;
        case (opcode)
            7'b0110111: begin // LUI (U-type)
                reg_write = 1'b1; imm_src = 3'b100; result_src = 2'b11;
            end
            7'b0010111: begin // AUIPC (U-type)
                reg_write = 1'b1; imm_src = 3'b100; alu_src_a = 2'b01; alu_src_b = 1'b1; alu_op = 2'b00;
            end
            7'b1101111: begin // JAL (J-type)
                reg_write = 1'b1; imm_src = 3'b011; jump = 1'b1; result_src = 2'b10;
            end
            7'b1100111: begin // JALR (I-type)
                reg_write = 1'b1; imm_src = 3'b000; jump_reg = 1'b1; result_src = 2'b10;
            end
            7'b1100011: begin // Branches (B-type)
                imm_src = 3'b010; branch_type = funct3;branch = 1'b1; 
            end
            7'b0000011: begin // Loads (I-type)
                reg_write = 1'b1; imm_src = 3'b000; alu_src_b = 1'b1; result_src = 2'b01;
                mem_size = funct3[1:0]; mem_unsigned = funct3[2];
            end
            7'b0100011: begin // Stores (S-type)
                mem_write = 1'b1; imm_src = 3'b001; alu_src_b = 1'b1;
                mem_size = funct3[1:0];
            end
            7'b0010011: begin // ALU Immediate (I-type)
                reg_write = 1'b1; imm_src = 3'b000; alu_src_b = 1'b1; alu_op = 2'b10;
            end
            7'b0110011: begin // ALU Register (R-type)
                reg_write = 1'b1; alu_op = 2'b10;
            end
            // 7'b1110011: ECALL, EBREAK - Default to NOPs in this design
            default: ; 
        endcase
    end

    // ALU Decoder: Maps funct3 and funct7 to a 4-bit control signal
    always_comb begin
        case (alu_op)
            2'b00: alu_control = 4'b0000; // ADD (Loads, Stores, AUIPC)
            2'b01: alu_control = 4'b1000; // SUB (Used internally if needed)
            2'b10: begin
                case (funct3)
                    3'b000: if (funct7b5 && opcode == 7'b0110011) alu_control = 4'b1000; // SUB
                            else                                  alu_control = 4'b0000; // ADD/ADDI
                    3'b001: alu_control = 4'b0001; // SLL/SLLI
                    3'b010: alu_control = 4'b0010; // SLT/SLTI
                    3'b011: alu_control = 4'b0011; // SLTU/SLTIU
                    3'b100: alu_control = 4'b0100; // XOR/XORI
                    3'b101: if (funct7b5) alu_control = 4'b1101; // SRA/SRAI
                            else          alu_control = 4'b0101; // SRL/SRLI
                    3'b110: alu_control = 4'b0110; // OR/ORI
                    3'b111: alu_control = 4'b0111; // AND/ANDI
                endcase
            end
            default: alu_control = 4'b0000;
        endcase
    end
endmodule
