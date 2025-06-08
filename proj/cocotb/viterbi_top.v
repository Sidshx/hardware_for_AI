`timescale 1ns/1ps

module viterbi_top #(
    parameter N = 8,   // max sequence length
    parameter I = 3,   // number of states
    parameter K = 3,   // number of symbols
    parameter W = 16   // data width (reduced for simplicity)
)(
    input                      clk,
    input                      rst_n,
    input                      start,
    input  [2:0]               length,       // sequence length (simplified)
    input  [1:0]               obs_in,       // current observation
    input                      obs_valid,

    // Simplified HMM params - just essential ones
    input  signed [W-1:0]      logA [0:8],   // flattened 3x3 transition matrix
    input  signed [W-1:0]      logC [0:2],   // initial state probs
    input  signed [W-1:0]      logB [0:8],   // flattened 3x3 emission matrix

    output reg [1:0]           path [0:7],   // output path
    output reg                 done
);

  // Simple FSM states
  localparam IDLE = 2'd0, FORWARD = 2'd1, BACKWARD = 2'd2, DONE = 2'd3;

  reg [1:0] state;
  reg [2:0] t;                    // time index
  reg [2:0] back_t;               // backtrack time index
  
  // Delta arrays for forward pass
  reg signed [W-1:0] delta_curr [0:2];
  reg signed [W-1:0] delta_next [0:2];
  
  // Psi memory for backtracking
  reg [1:0] psi [0:7][0:2];      // psi[time][state]
  
  // Temp variables
  reg signed [W-1:0] temp_val;
  reg [1:0] temp_idx;
  reg [1:0] best_state;
  reg signed [W-1:0] best_val;
  
  integer i, j;

  // Main FSM
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done <= 0;
      t <= 0;
      back_t <= 0;
      for (i = 0; i < 3; i = i + 1) begin
        delta_curr[i] <= 0;
        delta_next[i] <= 0;
      end
    end else begin
      case (state)
        
        IDLE: begin
          done <= 0;
          if (start) begin
            // Initialize first time step
            for (i = 0; i < 3; i = i + 1) begin
              delta_curr[i] <= logC[i] + logB[i*3 + obs_in];
            end
            t <= 1;
            state <= FORWARD;
          end
        end

        FORWARD: begin
          if (t >= length) begin
            // Forward pass complete, start backward pass
            // Find best final state
            best_val = delta_curr[0];
            best_state = 0;
            for (i = 1; i < 3; i = i + 1) begin
              if (delta_curr[i] > best_val) begin
                best_val = delta_curr[i];
                best_state = i;
              end
            end
            path[length-1] <= best_state;
            back_t <= length - 1;
            state <= BACKWARD;
          end else if (obs_valid) begin
            // Forward step: compute next deltas and store psi
            for (j = 0; j < 3; j = j + 1) begin
              // Find best previous state for current state j
              temp_val = delta_curr[0] + logA[0*3 + j];
              temp_idx = 0;
              for (i = 1; i < 3; i = i + 1) begin
                if (delta_curr[i] + logA[i*3 + j] > temp_val) begin
                  temp_val = delta_curr[i] + logA[i*3 + j];
                  temp_idx = i;
                end
              end
              delta_next[j] <= temp_val + logB[j*3 + obs_in];
              psi[t][j] <= temp_idx;
            end
            
            // Move to next time step
            for (i = 0; i < 3; i = i + 1) begin
              delta_curr[i] <= delta_next[i];
            end
            t <= t + 1;
          end
        end

        BACKWARD: begin
          if (back_t == 0) begin
            state <= DONE;
            done <= 1;
          end else begin
            path[back_t-1] <= psi[back_t][path[back_t]];
            back_t <= back_t - 1;
          end
        end

        DONE: begin
          if (!start) state <= IDLE;
        end

      endcase
    end
  end

endmodule
