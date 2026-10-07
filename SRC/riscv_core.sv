`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.09.2026 11:25:23
// Design Name: 
// Module Name: riscv_core
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


module riscv_core (
    input  logic        clk,
    input  logic        reset,
    // Instruction Memory
    output logic [31:0] pc,
    input  logic [31:0] instr,
    // Data Memory
    output logic        mem_write,
    output logic [1:0]  mem_size,      // 00=Byte, 01=Halfword, 10=Word
    output logic        mem_unsigned,  // 1=Zero-extend (LBU, LHU), 0=Sign-extend
    output logic [31:0] alu_result,
    output logic [31:0] write_data,
    input  logic [31:0] read_data
);

    // Internal Control Signals
    logic       reg_write, alu_src_b;
    logic [1:0] alu_src_a; // 00=Reg, 01=PC, 10=Zero
    logic [1:0] result_src;
    logic [2:0] imm_src;
    logic [3:0] alu_control;
    logic [2:0] branch_type;
    logic       jump, jump_reg;
    logic       take_branch;
    logic       branch;

    controller c (
        .opcode       (instr[6:0]),
        .funct3       (instr[14:12]),
        .funct7b5     (instr[30]),
        .take_branch  (take_branch),
        .result_src   (result_src),
        .mem_write    (mem_write),
        .mem_size     (mem_size),
        .mem_unsigned (mem_unsigned),
        .alu_src_a    (alu_src_a),
        .alu_src_b    (alu_src_b),
        .reg_write    (reg_write),
        .imm_src      (imm_src),
        .alu_control  (alu_control),
        .branch_type  (branch_type),
        .jump         (jump),
        .jump_reg     (jump_reg),
        .branch       (branch)
    );

    datapath dp (
        .clk          (clk),
        .reset        (reset),
        .result_src   (result_src),
        .alu_src_a    (alu_src_a),
        .alu_src_b    (alu_src_b),
        .reg_write    (reg_write),
        .imm_src      (imm_src),
        .alu_control  (alu_control),
        .branch_type  (branch_type),
        .jump         (jump),
        .jump_reg     (jump_reg),
        .take_branch  (take_branch),
        .branch       (branch),
        .pc           (pc),
        .instr        (instr),
        .alu_result   (alu_result),
        .write_data   (write_data),
        .read_data    (read_data)
    );
endmodule
