// viterbi_top.sv
// simplified, synthesizable, two‐stage forward + backtrack
`timescale 1ns/1ps

module viterbi_top #(
    parameter N = 16,  // max sequence length
    parameter I = 3,   // number of states
    parameter K = 3,   // number of symbols
    parameter W = 20   // data width
)(
    input                   clk,
    input                   rst_n,
    input                   start,        // pulse to begin
    input  [$clog2(N)-1:0]  length,       // actual sequence length
    input  [$clog2(K)-1:0]  obs_in,       // current observation
    input                   obs_valid,    // obs_in is valid

    // HMM params (log‐domain)
    input  signed [W-1:0]   logA [0:I-1][0:I-1],
    input  signed [W-1:0]   logC [0:I-1],
    input  signed [W-1:0]   logB [0:I-1][0:K-1],

    output reg [$clog2(I)-1:0] path [0:N-1], // output sequence
    output reg               done
);

  // explicit two‐stage FSM states
  localparam IDLE    = 3'd0,
             INIT0   = 3'd1,
             CALC    = 3'd2,
             UPDATE  = 3'd3,
             BACK    = 3'd4,
             FINISH  = 3'd5;

  reg [2:0]                   state;
  reg [$clog2(N)-1:0]         t;
  reg signed [W-1:0]          delta_prev [0:I-1],
                              delta_next [0:I-1];
  reg [$clog2(I)-1:0]         psi_mem    [0:N-1][0:I-1];

  // wires from PEs
  wire signed [W-1:0] delta_out_w [0:I-1];
  wire [$clog2(I)-1:0] psi_out_w   [0:I-1];

  // instantiate I PEs
  genvar j, x;
  generate
    for (j = 0; j < I; j = j + 1) begin : PES
      // pull out column j of logA
      wire signed [W-1:0] col [0:I-1];
      for (x = 0; x < I; x = x + 1)
        assign col[x] = logA[x][j];

      viterbi_pe #(.I(I), .W(W)) pe (
        .clk        (clk),
        .rst_n      (rst_n),
        .obs        (obs_in),
        .delta_prev (delta_prev),
        .logA_col   (col),
        .logB_emit  (logB[j][obs_in]),
        .delta_out  (delta_out_w[j]),
        .psi_out    (psi_out_w[j])
      );
    end
  endgenerate

  integer i;
  reg signed [W-1:0] best_v;
  reg [$clog2(I)-1:0] best_i;

  // ------------------------------------------------------------------------
  // FSM: INIT0 → CALC → UPDATE → … → BACK → FINISH
  // ------------------------------------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done  <= 1'b0;
      t      <= 0;
      for (i = 0; i < I; i = i + 1)
        delta_prev[i] <= 0;
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          if (start) state <= INIT0;
        end

        INIT0: begin
          // δ[0,i] = logC[i] + logB[i][obs0]
          for (i = 0; i < I; i = i + 1)
            delta_prev[i] <= logC[i] + logB[i][obs_in];
          t     <= 1;
          state <= CALC;
        end

        CALC: if (obs_valid && t < length) begin
          // latch ψ pointers and compute next‐deltas
          for (i = 0; i < I; i = i + 1) begin
            psi_mem[t][i]  <= psi_out_w[i];
            delta_next[i]  <= delta_out_w[i];
          end
          state <= UPDATE;
        end else if (t == length) begin
          state <= BACK;
        end

        UPDATE: begin
          // move next→prev and advance time
          for (i = 0; i < I; i = i + 1)
            delta_prev[i] <= delta_next[i];
          t     <= t + 1;
          state <= CALC;
        end

        BACK: begin
          // pick best final state
          best_v = delta_prev[0];
          best_i = 0;
          for (i = 1; i < I; i = i + 1)
            if (delta_prev[i] > best_v) begin
              best_v = delta_prev[i];
              best_i = i;
            end

          // write last element of path
          path[t-1] <= best_i;

          // walk back through psi_mem
          for (i = t-1; i > 0; i = i - 1)
            path[i-1] <= psi_mem[i][ path[i] ];

          done  <= 1'b1;
          state <= FINISH;
        end

        FINISH: if (!start)
          state <= IDLE;

      endcase
    end
  end

endmodule
