`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.09.2026 13:23:21
// Design Name: 
// Module Name: tb_riscv_soc
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


`timescale 1ns / 1ps

module tb_riscv_soc();

    // Testbench signals
    logic clk;
    logic reset;
    logic [31:0] final_debug_alu_result;

    // Instantiate the SoC (which now contains the core AND memories)
    riscv_soc uut (
        .clk                    (clk),
        .reset                  (reset),
        .final_debug_alu_result (final_debug_alu_result)
    );

    // Clock Generation (e.g., 10ns period -> 100 MHz)
    always begin
        #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;

        // Hold reset for 20ns
        #20;
        reset = 0;

        // Run the simulation long enough for instructions to execute
        #500;
        
        // End simulation
        $stop;
    end

endmodule
