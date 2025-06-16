`timescale 1ns/1ps

module tb_viterbi_pe;

  localparam I = 3;
  localparam W = 20;

  // Inputs
  reg clk;
  reg rst_n;
  reg [$clog2(I)-1:0] obs;
  reg signed [W-1:0] delta_prev [0:I-1];
  reg signed [W-1:0] logA_col [0:I-1];
  reg signed [W-1:0] logB_emit;

  // Outputs
  wire signed [W-1:0] delta_out;
  wire [$clog2(I)-1:0] psi_out;

  // DUT
  viterbi_pe #(I, W) dut (
    .clk(clk),
    .rst_n(rst_n),
    .obs(obs),
    .delta_prev(delta_prev),
    .logA_col(logA_col),
    .logB_emit(logB_emit),
    .delta_out(delta_out),
    .psi_out(psi_out)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  integer i;

  // Test sequence
  initial begin
    $display("=== Viterbi PE Testbench ===");

    rst_n = 0;
    obs = 0;
    #10;
    rst_n = 1;

    // Initialize test inputs
    delta_prev[0] = 10;
    delta_prev[1] = 20;
    delta_prev[2] = 15;

    logA_col[0] = 5;   // 10+5 = 15
    logA_col[1] = 3;   // 20+3 = 23 ← max
    logA_col[2] = 2;   // 15+2 = 17

    logB_emit = 4;     // Add this to best_val for delta_out

    // Observe for 2 clock cycles
    #10;
    #10;

    $display("Expected psi_out = 1");
    $display("Expected delta_out = 23 + 4 = 27");

    $display("Result: psi_out = %0d, delta_out = %0d", psi_out, delta_out);

    $finish;
  end

endmodule
