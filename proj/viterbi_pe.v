// viterbi_pe.v
// A single Processing Element (PE) in a 1D systolic chain for Viterbi.
// Each PE holds logA[i][j], receives delta_prev[i], and contributes to the max-plus reduction.
//
// Parameters:
//   FW : fixed-point width
module viterbi_pe #(
  parameter FW = 16
)(
  input                    clk,
  input                    rst_n,
  input         [FW-1:0]   delta_in,    // δ[n-1, i]
  input         [FW-1:0]   logA_ij,     // logA[i, j]
  input                    valid_in,    // pulses all PEs to start new n,j
  output reg   [FW-1:0]    best_val,    // running max
  output reg   [31:0]      best_idx,    // running argmax
  output reg               valid_out    // pulses at end of reduction
);

  // Internal registers
  reg   [FW-1:0]  sum;        // delta_in + logA_ij
  reg             first;      // first element flag
  reg   [31:0]    idx_count;  // counts which PE index we’re at

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      best_val   <= {FW{1'b0}};
      best_idx   <= 0;
      valid_out  <= 0;
      idx_count  <= 0;
      first      <= 1;
    end else if (valid_in) begin
      // Compute candidate
      sum = $signed(delta_in) + $signed(logA_ij);

      // If first element in chain, initialize best_val/best_idx
      if (first) begin
        best_val  <= sum;
        best_idx  <= idx_count;
        first     <= 0;
      end else if ($signed(sum) > $signed(best_val)) begin
        best_val  <= sum;
        best_idx  <= idx_count;
      end

      idx_count <= idx_count + 1;

      // If this is the last PE in the chain, emit valid_out
      // (Assume the instantiating wrapper resets idx_count for each new valid_in)
      // You’ll manage generation of valid_in and detection of chain-end in the wrapper.
    end
  end

endmodule
