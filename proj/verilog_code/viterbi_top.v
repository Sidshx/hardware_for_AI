// viterbi_top.v
// Corrected, synthesizable, two-stage forward + backtrack
`timescale 1ns/1ps

module viterbi_top #(
    parameter N = 16,  // max sequence length
    parameter I = 3,   // number of states
    parameter K = 3,   // number of symbols
    parameter W = 20   // data width
)(
    input                      clk,
    input                      rst_n,
    input                      start,        // pulse to begin
    input  [$clog2(N)-1:0]     length,       // actual sequence length
    input  [$clog2(K)-1:0]     obs_in,       // current observation
    input                      obs_valid,    // obs_in is valid

    // HMM params (log-domain) - flattened for synthesis
    input  signed [W-1:0]      logA [0:I*I-1],  // logA[i*I+j] = logA[i][j]
    input  signed [W-1:0]      logC [0:I-1],
    input  signed [W-1:0]      logB [0:I*K-1],  // logB[i*K+k] = logB[i][k]

    output reg [$clog2(I)-1:0] path [0:N-1], // output sequence
    output reg                 done,
    output reg                 valid_out
);

  // FSM states
  localparam IDLE    = 3'd0,
             INIT0   = 3'd1,
             CALC    = 3'd2,
             UPDATE  = 3'd3,
             BACK    = 3'd4,
             BACK_LOOP = 3'd5,
             FINISH  = 3'd6;

  reg [2:0]                   state, next_state;
  reg [$clog2(N)-1:0]         t;
  reg [$clog2(N)-1:0]         back_idx;
  reg signed [W-1:0]          delta_prev [0:I-1];
  reg signed [W-1:0]          delta_next [0:I-1];
  reg [$clog2(I)-1:0]         psi_mem    [0:N-1][0:I-1];

  // wires from PEs
  wire signed [W-1:0]         delta_out_w [0:I-1];
  wire [$clog2(I)-1:0]        psi_out_w   [0:I-1];

  // Individual column wires for each PE
  wire signed [W-1:0]         pe0_col [0:I-1];
  wire signed [W-1:0]         pe1_col [0:I-1];
  wire signed [W-1:0]         pe2_col [0:I-1];
  
  // Assign columns manually for each PE
  genvar x;
  generate
    for (x = 0; x < I; x = x + 1) begin : COL_ASSIGN
      assign pe0_col[x] = logA[x*I + 0];  // Column 0 of logA
      assign pe1_col[x] = logA[x*I + 1];  // Column 1 of logA  
      assign pe2_col[x] = logA[x*I + 2];  // Column 2 of logA
    end
  endgenerate

  // PE0 instantiation
  viterbi_pe #(.I(I), .W(W)) pe0 (
    .clk        (clk),
    .rst_n      (rst_n),
    .obs        (obs_in),
    .delta_prev (delta_prev),
    .logA_col   (pe0_col),
    .logB_emit  (logB[0*K + obs_in]),
    .delta_out  (delta_out_w[0]),
    .psi_out    (psi_out_w[0])
  );

  // PE1 instantiation
  viterbi_pe #(.I(I), .W(W)) pe1 (
    .clk        (clk),
    .rst_n      (rst_n),
    .obs        (obs_in),
    .delta_prev (delta_prev),
    .logA_col   (pe1_col),
    .logB_emit  (logB[1*K + obs_in]),
    .delta_out  (delta_out_w[1]),
    .psi_out    (psi_out_w[1])
  );

  // PE2 instantiation
  viterbi_pe #(.I(I), .W(W)) pe2 (
    .clk        (clk),
    .rst_n      (rst_n),
    .obs        (obs_in),
    .delta_prev (delta_prev),
    .logA_col   (pe2_col),
    .logB_emit  (logB[2*K + obs_in]),
    .delta_out  (delta_out_w[2]),
    .psi_out    (psi_out_w[2])
  );

  integer i;
  reg signed [W-1:0]          best_v;
  reg [$clog2(I)-1:0]         best_i;
  reg [$clog2(I)-1:0]         current_state;

  // FSM
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done  <= 1'b0;
      valid_out <= 1'b0;
      t <= 0;
      back_idx <= 0;
      current_state <= 0;
      for (i = 0; i < I; i = i + 1) begin
        delta_prev[i] <= 0;
        delta_next[i] <= 0;
      end
      for (i = 0; i < N; i = i + 1) begin
        path[i] <= 0;
      end
    end else begin
      case (state)
        IDLE: begin
          done <= 1'b0;
          valid_out <= 1'b0;
          if (start) begin
            state <= INIT0;
            t <= 0;
          end
        end

        INIT0: begin
          // δ[0,i] = logC[i] + logB[i][obs0]
          for (i = 0; i < I; i = i + 1) begin
            delta_prev[i] <= logC[i] + logB[i*K + obs_in];
          end
          t <= 1;
          state <= CALC;
        end

        CALC: begin
          if (t >= length) begin
            state <= BACK;
          end else if (obs_valid) begin
            // latch ψ pointers and compute next-deltas
            for (i = 0; i < I; i = i + 1) begin
              psi_mem[t][i] <= psi_out_w[i];
              delta_next[i] <= delta_out_w[i];
            end
            state <= UPDATE;
          end
          // Stay in CALC if t < length but obs_valid is not asserted
        end

        UPDATE: begin
          // move next→prev and advance time
          for (i = 0; i < I; i = i + 1) begin
            delta_prev[i] <= delta_next[i];
          end
          t <= t + 1;
          state <= CALC;
        end

        BACK: begin
          // Find best final state
          best_v = delta_prev[0];
          best_i = 0;
          for (i = 1; i < I; i = i + 1) begin
            if (delta_prev[i] > best_v) begin
              best_v = delta_prev[i];
              best_i = i;
            end
          end
          
          // Set up for backtracking
          path[length-1] <= best_i;
          current_state <= best_i;
          back_idx <= length - 1;
          
          if (length > 1) begin
            state <= BACK_LOOP;
          end else begin
            done <= 1'b1;
            valid_out <= 1'b1;
            state <= FINISH;
          end
        end

        BACK_LOOP: begin
          if (back_idx > 0) begin
            current_state <= psi_mem[back_idx][current_state];
            path[back_idx-1] <= psi_mem[back_idx][current_state];
            back_idx <= back_idx - 1;
          end else begin
            done <= 1'b1;
            valid_out <= 1'b1;
            state <= FINISH;
          end
        end

        FINISH: begin
          if (!start) begin
            state <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule
