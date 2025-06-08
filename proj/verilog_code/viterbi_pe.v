`timescale 1ns/1ps
module viterbi_pe #(
  parameter I = 3,            // number of states
  parameter W = 20            // fixed-point width
)(
  input                       clk,
  input                       rst_n,
  input  [$clog2(I)-1:0]      obs,            // current observation index
  input  signed [W-1:0]       delta_prev [0:I-1], // δ[n-1,i]
  input  signed [W-1:0]       logA_col   [0:I-1], // logA[i][j]
  input  signed [W-1:0]       logB_emit,          // logB[j][o[n]]
  output reg signed [W-1:0]   delta_out,       // δ[n,j]
  output reg  [$clog2(I)-1:0] psi_out          // argmax i
);

  //------------------------------------------------------------------------
  // 1) Combinational search for best predecessor
  //------------------------------------------------------------------------
  integer k;
  reg signed [W-1:0] best_val_comb;
  reg  [$clog2(I)-1:0] best_idx_comb;

  always @* begin
    best_val_comb = delta_prev[0] + logA_col[0];
    best_idx_comb = 0;
    for (k = 1; k < I; k = k + 1) begin
      if (delta_prev[k] + logA_col[k] > best_val_comb) begin
        best_val_comb = delta_prev[k] + logA_col[k];
        best_idx_comb = k;
      end
    end
  end

  //------------------------------------------------------------------------
  // 2) Register the combinational result
  //------------------------------------------------------------------------
  reg signed [W-1:0] best_val_reg;
  reg  [$clog2(I)-1:0] best_idx_reg;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      best_val_reg <= 0;
      best_idx_reg <= 0;
    end else begin
      best_val_reg <= best_val_comb;
      best_idx_reg <= best_idx_comb;
    end
  end

  //------------------------------------------------------------------------
  // 3) Compute δ[n,j] = best_val_reg + logB_emit  (and register outputs)
  //------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      delta_out <= 0;
      psi_out   <= 0;
    end else begin
      delta_out <= best_val_reg + logB_emit;
      psi_out   <= best_idx_reg;
    end
  end

endmodule
