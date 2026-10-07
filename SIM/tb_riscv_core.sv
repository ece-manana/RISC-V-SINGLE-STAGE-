`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.09.2026 11:51:33
// Design Name: 
// Module Name: tb_riscv_core
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


// --- Instruction Memory ---
module instruction_memory (
    input  logic [31:0] address,
    output logic [31:0] read_data
);
    logic [31:0] mem [0:255]; // 1KB Memory

    initial begin
        // Loads a hex file containing compiled RISC-V machine code
        $readmemh("C:/Users/BIT/Desktop/manana/program.hex.txt", mem);
    end

    // Word-aligned read (ignores bottom 2 bits of address)
    assign read_data = mem[address[9:2]]; 
endmodule

// --- Data Memory ---
module data_memory (
    input  logic        clk,
    input  logic [31:0] address,
    input  logic [31:0] write_data,
    input  logic        write_enable,
    input  logic [1:0]  mem_size,      // 00=Byte, 01=Halfword, 10=Word
    input  logic        mem_unsigned,
    output logic [31:0] read_data
);
    logic [31:0] mem [0:255]; // 1KB Memory

    // Initialize memory to zero to avoid X states in simulation
    initial begin
        for (int i = 0; i < 256; i++) mem[i] = 32'b0;
    end

    // Synchronous Write
    always_ff @(posedge clk) begin
        if (write_enable) begin
            // Simplified for this testbench: assumes Word writes (SW)
            // A full implementation would mask bytes based on mem_size
            mem[address[9:2]] <= write_data;
        end
    end

    // Asynchronous Read
    assign read_data = mem[address[9:2]];
endmodule
module tb_riscv_core;

    // Simulation Signals
    logic        clk;
    logic        reset;
    
    // Core to Memory Interconnect Wires
    logic [31:0] pc;
    logic [31:0] instr;
    logic        mem_write;
    logic [1:0]  mem_size;
    logic        mem_unsigned;
    logic [31:0] alu_result;
    logic [31:0] write_data;
    logic [31:0] read_data;

    // 1. Instantiate the Processor Core
    riscv_core uut (
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

    // 2. Instantiate the Instruction Memory
    instruction_memory imem (
        .address(pc),
        .read_data(instr)
    );

    // 3. Instantiate the Data Memory
    data_memory dmem (
        .clk(clk),
        .address(alu_result),
        .write_data(write_data),
        .write_enable(mem_write),
        .mem_size(mem_size),
        .mem_unsigned(mem_unsigned),
        .read_data(read_data)
    );

    // Clock Generation (50 MHz -> 20ns period)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // Test Sequence
    initial begin
        $display("=== Starting RISC-V Single Cycle Simulation ===");
        
        // Setup waveform dumping for tools like SimVision or GTKWave
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_riscv_core);

        // Apply Reset
        reset = 1;
        #25; 
        reset = 0;

        // Let the processor run for a set amount of time
        // Adjust this depending on how long your assembly program is
        #1000; 

        // Self-Checking Mechanism
        // Assuming your assembly program writes its final computed result to memory address 100
        if (dmem.mem[25] == 32'd42) begin // 100 divided by 4 for word alignment is 25
            $display("SUCCESS: Final result matches expected value.");
        end else begin
            $display("FAILED: Expected 42, got %0d", dmem.mem[25]);
        end

        $display("=== Simulation Complete ===");
        $finish;
    end

endmodule
