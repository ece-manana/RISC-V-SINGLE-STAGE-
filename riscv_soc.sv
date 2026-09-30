`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.09.2026 13:18:23
// Design Name: 
// Module Name: riscv_soc
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


module riscv_soc (
    input  logic clk,
    input  logic reset,
    output logic [31:0] final_debug_alu_result // Optional pin to watch on physical chip
);

    // Internal wires connecting the core to the memories
    logic [31:0] pc;
    logic [31:0] instr;
    logic        mem_write;
    logic [1:0]  mem_size;
    logic        mem_unsigned;
    logic [31:0] alu_result;
    logic [31:0] write_data;
    logic [31:0] read_data;

    // 1. Instantiate your verified Single-Cycle Core
    riscv_core core (
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instr(instr),
        .mem_write(mem_write),
        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned),
        .alu_result(alu_result),
        .write_data(write_data),
        .read_data(read_data)
    );

    // 2. Synthesizable Instruction Memory (Small Array)
    logic [31:0] imem [0:63]; // 64 instructions max for this small chip
    initial begin
        $readmemh("C:/Users/BIT/single_riscv/single_riscv.srcs/sim_1/new/program.hex", imem);
    end
    assign instr = imem[pc[31:2]]; // Word aligned

    // 3. Synthesizable Data Memory (Small Array mapped to Flip-Flops/Latches)
    logic [31:0] dmem [0:63];
    always_ff @(posedge clk) begin
        if (mem_write) begin
            dmem[alu_result[31:2]] <= write_data;
        end
    end
    assign read_data = dmem[alu_result[31:2]];
    
    assign final_debug_alu_result = alu_result;

endmodule
