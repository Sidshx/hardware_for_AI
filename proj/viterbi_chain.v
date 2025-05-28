// viterbi_chain.v
// Compute one column j of Viterbi at time-step n:
//   δ[n,j] = max_i (δ[n-1,i] + logA[i][j]) + logB[j,o_n]
//   ψ[n,j] = argmax_i (δ[n-1,i] + logA[i][j])

module viterbi_chain #(
  parameter I       = 8,    // number of states
  parameter FW      = 16    // fixed-point width
)(
  input                    clk,
  input                    rst_n,
  input                    start_step,    // pulse to begin this time-step
  input  [FW-1:0]          delta_prev [0:I-1], // all δ[n-1,i]
  input  [FW-1:0]          logA_col   [0:I-1], // this column logA[i][j]
  input  [FW-1:0]          logB_j,             // logB[j,o_n]
  output [FW-1:0]          delta_next,         // δ[n,j]
  output [$clog2(I)-1:0]   psi_index,          // ψ[n,j]
  output                   done                // high when delta_next valid
);

  // We'll chain I PEs
  wire                      pe_valid [0:I-1];
  wire [FW-1:0]             best_val [0:I-1];
  wire [$clog2(I)-1:0]      best_idx [0:I-1];

  genvar i;
  generate
    for (i = 0; i < I; i = i + 1) begin : PEs
      // The valid-in pulse shifts down the chain
      wire valid_in = (i == 0) ? start_step : pe_valid[i-1];

      viterbi_pe #(.FW(FW)) pe (
        .clk       (clk),
        .rst_n     (rst_n),
        .delta_in  (delta_prev[i]),
        .logA_ij   (logA_col[i]),
        .valid_in  (valid_in),
        .best_val  (best_val[i]),
        .best_idx  (best_idx[i]),
        .valid_out (pe_valid[i])
      );
    end
  endgenerate

  // When the last PE pulses valid_out, we have our answer
  assign done        = pe_valid[I-1];
  // Add the emission log-prob to get δ[n,j]
  assign delta_next  = best_val[I-1] + logB_j;
  assign psi_index   = best_idx[I-1];

endmodule
