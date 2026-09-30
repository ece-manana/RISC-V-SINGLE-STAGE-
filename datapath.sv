`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.09.2026 11:12:03
// Design Name: 
// Module Name: datapath
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


module datapath (
    input  logic        clk, reset,
    input  logic [1:0]  result_src, alu_src_a,
    input  logic        alu_src_b, reg_write,
    input  logic [2:0]  imm_src, branch_type,
    input  logic [3:0]  alu_control,
    input  logic        jump, jump_reg,
    output logic        take_branch,
    output logic [31:0] pc,
    input  logic [31:0] instr,
    output logic [31:0] alu_result, write_data,
    input  logic [31:0] read_data,
    input logic        branch
);

    logic [31:0] pc_next, pc_plus4, pc_target, pc_branch_jump;
    logic [31:0] imm_ext;
    logic [31:0] rf_a, rf_b; // Data directly out of RegFile
    logic [31:0] src_a, src_b;
    logic [31:0] result;
    
    // --- Program Counter Logic ---
    always_ff @(posedge clk or posedge reset) begin
        if (reset) pc <= 32'h00000000;
        else       pc <= pc_next;
    end
    
    assign pc_plus4  = pc + 32'd4;
    assign pc_target = pc + imm_ext;
    
    // PC Muxing: Branch/JAL use pc_target, JALR uses ALU result (rs1 + imm)
    always_comb begin
        if (jump_reg)                 pc_next = {alu_result[31:1], 1'b0}; // Clear LSB for JALR
        else if (jump | (branch&take_branch))  pc_next = pc_target;
        else                          pc_next = pc_plus4;
    end

    // --- Register File ---
    logic [31:0] rf [31:1]; 
    
    always_comb begin // Async Read
        rf_a = (instr[19:15] == 5'b0) ? 32'b0 : rf[instr[19:15]];
        rf_b = (instr[24:20] == 5'b0) ? 32'b0 : rf[instr[24:20]];
    end

    always_ff @(posedge clk) begin // Sync Write
        if (reg_write && instr[11:7] != 5'b0) begin
            rf[instr[11:7]] <= result;
        end
    end
    
    assign write_data = rf_b; // Data sent to memory for Stores

    // --- Immediate Extension ---
    always_comb begin
        case(imm_src)
            3'b000: imm_ext = {{20{instr[31]}}, instr[31:20]};                         // I-type
            3'b001: imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};            // S-type
            3'b010: imm_ext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}; // B-type
            3'b011: imm_ext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}; // J-type
            3'b100: imm_ext = {instr[31:12], 12'b0};                                   // U-type
            default: imm_ext = 32'b0;
        endcase
    end

    // --- Branch Evaluator ---
    always_comb begin
        case (branch_type)
            3'b000: take_branch = (rf_a == rf_b);                   // BEQ
            3'b001: take_branch = (rf_a != rf_b);                   // BNE
            3'b100: take_branch = ($signed(rf_a) < $signed(rf_b));  // BLT
            3'b101: take_branch = ($signed(rf_a) >= $signed(rf_b)); // BGE
            3'b110: take_branch = (rf_a < rf_b);                    // BLTU
            3'b111: take_branch = (rf_a >= rf_b);                   // BGEU
            default: take_branch = 1'b0;
        endcase
    end

    // --- ALU Source Muxes ---
    always_comb begin
        case(alu_src_a)
            2'b00: src_a = rf_a;       // Normal operations
            2'b01: src_a = pc;         // AUIPC
            2'b10: src_a = 32'b0;      // LUI (0 + imm)
            default: src_a = rf_a;
        endcase
    end
    
    assign src_b = alu_src_b ? imm_ext : rf_b;

    // --- ALU ---
    always_comb begin
        case(alu_control)
            4'b0000: alu_result = src_a + src_b;                          // ADD
            4'b1000: alu_result = src_a - src_b;                          // SUB
            4'b0001: alu_result = src_a << src_b[4:0];                    // SLL
            4'b0010: alu_result = ($signed(src_a) < $signed(src_b)) ? 1:0; // SLT
            4'b0011: alu_result = (src_a < src_b) ? 1:0;                  // SLTU
            4'b0100: alu_result = src_a ^ src_b;                          // XOR
            4'b0101: alu_result = src_a >> src_b[4:0];                    // SRL
            4'b1101: alu_result = $signed(src_a) >>> src_b[4:0];          // SRA
            4'b0110: alu_result = src_a | src_b;                          // OR
            4'b0111: alu_result = src_a & src_b;                          // AND
            default: alu_result = 32'bx;
        endcase
    end

    // --- Result Multiplexer ---
    always_comb begin
        case(result_src)
            2'b00: result = alu_result;   // R-type, I-type ALU
            2'b01: result = read_data;    // Loads
            2'b10: result = pc_plus4;     // JAL, JALR
            2'b11: result = imm_ext;      // LUI
        endcase
    end

endmodule
