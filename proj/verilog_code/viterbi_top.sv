
// viterbi_top.sv
// Top‐level Viterbi forward + real backtrack using stored ψ pointers
`timescale 1ns/1ps

module viterbi_top #(
  parameter N = 16,        // max sequence length
  parameter I = 3,         // number of states
  parameter K = 3,         // number of observation symbols
  parameter W = 20         // fixed‐point width
)(
  input                   clk,
  input                   rst_n,
  input                   start,        // pulse to begin decoding
  input  [$clog2(N)-1:0]  length,       // actual sequence length
  input  [$clog2(K)-1:0]  obs_in,       // current observation
  input                   obs_valid,    // obs_in is valid this cycle

  // preloaded HMM parameters (in log‐domain)
  input signed [W-1:0]    logA [0:I-1][0:I-1],
  input signed [W-1:0]    logC [0:I-1],
  input signed [W-1:0]    logB [0:I-1][0:K-1],

  output reg [$clog2(I)-1:0] path [0:N-1], // recovered hidden‐state path
  output reg               done
);

  // ------------------------------------------------------------------------
  // Internal memories
  // ------------------------------------------------------------------------
  reg signed [W-1:0] delta_prev [0:I-1];
  reg signed [W-1:0] delta_next [0:I-1];
  reg [$clog2(I)-1:0] psi_mem    [0:N-1][0:I-1];

  // wires from PEs
  wire signed [W-1:0] delta_out_w [0:I-1];
  wire [$clog2(I)-1:0] psi_out_w   [0:I-1];

  // instantiate I PEs
  genvar j, x;
  generate
    for (j = 0; j < I; j = j + 1) begin : PES
      // assemble column j of logA
      wire signed [W-1:0] logA_col [0:I-1];
      for (x = 0; x < I; x = x + 1)
        assign logA_col[x] = logA[x][j];

      viterbi_pe #(.I(I), .W(W)) pe (
        .clk        (clk),
        .rst_n      (rst_n),
        .obs        (obs_in),
        .delta_prev (delta_prev),
        .logA_col   (logA_col),
        .logB_emit  (logB[j][obs_in]),
        .delta_out  (delta_out_w[j]),
        .psi_out    (psi_out_w[j])
      );
    end
  endgenerate

  // FSM variables
  typedef enum {IDLE, INIT0, FORWARD, BACKTRACK, DONE} state_t;
  state_t st;
  integer t, i;

  // temporaries for backtrack
  reg signed [W-1:0] best_v;
  reg [$clog2(I)-1:0] best_i;

  // ------------------------------------------------------------------------
  // Main FSM
  // ------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st         <= IDLE;
      done       <= 1'b0;
      t          <= 0;
      for (i = 0; i < I; i = i + 1)
        delta_prev[i] <= 0;
    end else begin
      case (st)
        IDLE: if (start) st <= INIT0;

        INIT0: begin
          // δ[0,i] = logC[i] + logB[i][obs_in]
          for (i = 0; i < I; i = i + 1)
            delta_prev[i] <= logC[i] + logB[i][obs_in];
          t  <= 1;
          st <= FORWARD;
        end

        FORWARD: begin
          if (obs_valid && t < length) begin
            // capture forward outputs & store ψ
            for (i = 0; i < I; i = i + 1) begin
              delta_prev[i] <= delta_out_w[i];
              psi_mem[t][i] <= psi_out_w[i];
            end
            t <= t + 1;
          end else if (t == length) begin
            st <= BACKTRACK;
          end
        end

        BACKTRACK: begin
          // 1) pick best final state
          best_v = delta_prev[0];
          best_i = 0;
          for (i = 1; i < I; i = i + 1) begin
            if (delta_prev[i] > best_v) begin
              best_v = delta_prev[i];
              best_i = i;
            end
          end

          // 2) write last state
          path[t-1] <= best_i;

          // 3) walk backwards
          for (i = t-1; i > 0; i = i - 1)
            path[i-1] <= psi_mem[i][ path[i] ];

          done <= 1'b1;
          st   <= DONE;
        end

        DONE: ; // stay until host lowers 'start'
      endcase
    end
  end

endmodule
