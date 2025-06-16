`timescale 1ns/1ps
module viterbi_pe #(
  parameter I = 3,            // number of states
  parameter W = 20            // fixed-point width
)(
  input                       clk,
  input                       rst_n,
  input  [$clog2(I)-1:0]      obs,            // current observation index
  input  signed [W*I-1:0]     delta_prev_flat, // δ[n-1,i] flattened
  input  signed [W*I-1:0]     logA_col_flat,   // logA[i][j] flattened
  input  signed [W-1:0]       logB_emit,       // logB[j][o[n]]
  output reg signed [W-1:0]   delta_out,       // δ[n,j]
  output reg  [$clog2(I)-1:0] psi_out          // argmax i
);

  // Direct wire assignments instead of arrays
  wire signed [W-1:0] delta_prev_0 = delta_prev_flat[W-1:0];
  wire signed [W-1:0] delta_prev_1 = delta_prev_flat[2*W-1:W];
  wire signed [W-1:0] delta_prev_2 = delta_prev_flat[3*W-1:2*W];
  
  wire signed [W-1:0] logA_col_0 = logA_col_flat[W-1:0];
  wire signed [W-1:0] logA_col_1 = logA_col_flat[2*W-1:W];
  wire signed [W-1:0] logA_col_2 = logA_col_flat[3*W-1:2*W];

  //------------------------------------------------------------------------
  // 1) Combinational search for best predecessor
  //------------------------------------------------------------------------
  reg signed [W-1:0] best_val_comb;
  reg  [$clog2(I)-1:0] best_idx_comb;

  // Synthesizable comparison logic
  reg signed [W-1:0] comp_val_0, comp_val_1, comp_val_2;
  
  always @* begin
    comp_val_0 = delta_prev_0 + logA_col_0;
    comp_val_1 = delta_prev_1 + logA_col_1;
    comp_val_2 = delta_prev_2 + logA_col_2;
  end

  always @* begin
    best_val_comb = comp_val_0;
    best_idx_comb = 0;
    
    if (comp_val_1 > best_val_comb) begin
      best_val_comb = comp_val_1;
      best_idx_comb = 1;
    end
    
    if (comp_val_2 > best_val_comb) begin
      best_val_comb = comp_val_2;
      best_idx_comb = 2;
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

