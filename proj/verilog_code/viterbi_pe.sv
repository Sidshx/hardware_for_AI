
// Simple Viterbi PE: does max over I inputs and adds emission log
`timescale 1ns/1ps
module viterbi_pe #(
  parameter I = 3,
  parameter W = 20
)(
  input                   clk,
  input                   rst_n,
  input      [$clog2(I)-1:0] obs,             // current observation index
  input signed [W-1:0]   delta_prev [0:I-1],  // δ[n-1,i]
  input signed [W-1:0]   logA_col   [0:I-1],  // logA[i][j]
  input signed [W-1:0]   logB_emit,           // logB[j][ o[n] ]
  output reg signed [W-1:0] delta_out,        // δ[n,j]
  output reg [$clog2(I)-1:0] psi_out          // argmax i
);

  integer k;
  reg signed [W-1:0] best_val;
  reg [$clog2(I)-1:0] best_idx;

  // combinational: find best predecessor
  always @(posedge clk) begin
    best_val = delta_prev[0] + logA_col[0];
    best_idx = 0;
    for (k = 1; k < I; k = k+1) begin
      if (delta_prev[k] + logA_col[k] > best_val) begin
        best_val = delta_prev[k] + logA_col[k];
        best_idx = k;
      end
    end
  end

  // register outputs
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      delta_out <= 0;
      psi_out   <= 0;
    end else begin
      delta_out <= best_val + logB_emit;
      psi_out   <= best_idx;
    end
  end

endmodule
