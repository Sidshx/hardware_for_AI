`timescale 1ns/1ps

module viterbi_top #(
    parameter N = 8,   // max sequence length
    parameter I = 3,   // number of states
    parameter K = 3,   // number of symbols
    parameter W = 16   // data width
)(
    input                      clk,
    input                      rst_n,
    input                      start,
    input  [2:0]               length,
    input  [1:0]               obs_in,
    input                      obs_valid,

    // Individual pins for OpenLane compatibility
    // Transition matrix logA (3x3 = 9 elements)
    input  signed [W-1:0]      logA_0,  logA_1,  logA_2,
    input  signed [W-1:0]      logA_3,  logA_4,  logA_5,
    input  signed [W-1:0]      logA_6,  logA_7,  logA_8,
    
    // Initial state probabilities (3 elements)
    input  signed [W-1:0]      logC_0,  logC_1,  logC_2,
    
    // Emission matrix logB (3x3 = 9 elements)
    input  signed [W-1:0]      logB_0,  logB_1,  logB_2,
    input  signed [W-1:0]      logB_3,  logB_4,  logB_5,
    input  signed [W-1:0]      logB_6,  logB_7,  logB_8,

    // Individual path outputs
    output reg [1:0]           path_0,
    output reg [1:0]           path_1,
    output reg [1:0]           path_2,
    output reg [1:0]           path_3,
    output reg [1:0]           path_4,
    output reg [1:0]           path_5,
    output reg [1:0]           path_6,
    output reg [1:0]           path_7,
    output reg                 done
);

  // FSM states
  localparam IDLE = 2'd0, FORWARD = 2'd1, BACKWARD = 2'd2, DONE = 2'd3;

  reg [1:0] state;
  reg [2:0] t;                    
  reg [2:0] back_t;               
  
  // Delta arrays
  reg signed [W-1:0] delta_0, delta_1, delta_2;
  
  // Psi memory - individual registers
  reg [1:0] psi_1_0, psi_1_1, psi_1_2;  
  reg [1:0] psi_2_0, psi_2_1, psi_2_2;  
  reg [1:0] psi_3_0, psi_3_1, psi_3_2;  
  reg [1:0] psi_4_0, psi_4_1, psi_4_2;  
  reg [1:0] psi_5_0, psi_5_1, psi_5_2;  
  reg [1:0] psi_6_0, psi_6_1, psi_6_2;  
  reg [1:0] psi_7_0, psi_7_1, psi_7_2;  

  // Sequential logic
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      done <= 0;
      t <= 0;
      back_t <= 0;
      delta_0 <= 0;
      delta_1 <= 0;
      delta_2 <= 0;
      path_0 <= 0; path_1 <= 0; path_2 <= 0; path_3 <= 0;
      path_4 <= 0; path_5 <= 0; path_6 <= 0; path_7 <= 0;
      // Initialize all psi registers
      psi_1_0 <= 0; psi_1_1 <= 0; psi_1_2 <= 0;
      psi_2_0 <= 0; psi_2_1 <= 0; psi_2_2 <= 0;
      psi_3_0 <= 0; psi_3_1 <= 0; psi_3_2 <= 0;
      psi_4_0 <= 0; psi_4_1 <= 0; psi_4_2 <= 0;
      psi_5_0 <= 0; psi_5_1 <= 0; psi_5_2 <= 0;
      psi_6_0 <= 0; psi_6_1 <= 0; psi_6_2 <= 0;
      psi_7_0 <= 0; psi_7_1 <= 0; psi_7_2 <= 0;
    end else begin
      case (state)
        
        IDLE: begin
          done <= 0;
          if (start) begin
            // Initialize first time step
            case (obs_in)
              2'd0: begin
                delta_0 <= logC_0 + logB_0;  // state 0, obs 0
                delta_1 <= logC_1 + logB_3;  // state 1, obs 0
                delta_2 <= logC_2 + logB_6;  // state 2, obs 0
              end
              2'd1: begin
                delta_0 <= logC_0 + logB_1;  // state 0, obs 1
                delta_1 <= logC_1 + logB_4;  // state 1, obs 1
                delta_2 <= logC_2 + logB_7;  // state 2, obs 1
              end
              2'd2: begin
                delta_0 <= logC_0 + logB_2;  // state 0, obs 2
                delta_1 <= logC_1 + logB_5;  // state 1, obs 2
                delta_2 <= logC_2 + logB_8;  // state 2, obs 2
              end
              default: begin
                delta_0 <= logC_0 + logB_0;
                delta_1 <= logC_1 + logB_3;
                delta_2 <= logC_2 + logB_6;
              end
            endcase
            t <= 1;
            state <= FORWARD;
          end
        end

        FORWARD: begin
          if (t >= length) begin
            // Find the state with the highest delta value
            if (delta_0 >= delta_1 && delta_0 >= delta_2) begin
              case (length)
                3'd1: path_0 <= 0;
                3'd2: path_1 <= 0;
                3'd3: path_2 <= 0;
                3'd4: path_3 <= 0;
                3'd5: path_4 <= 0;
                3'd6: path_5 <= 0;
                3'd7: path_6 <= 0;
                default: path_7 <= 0;
              endcase
            end else if (delta_1 >= delta_2) begin
              case (length)
                3'd1: path_0 <= 1;
                3'd2: path_1 <= 1;
                3'd3: path_2 <= 1;
                3'd4: path_3 <= 1;
                3'd5: path_4 <= 1;
                3'd6: path_5 <= 1;
                3'd7: path_6 <= 1;
                default: path_7 <= 1;
              endcase
            end else begin
              case (length)
                3'd1: path_0 <= 2;
                3'd2: path_1 <= 2;
                3'd3: path_2 <= 2;
                3'd4: path_3 <= 2;
                3'd5: path_4 <= 2;
                3'd6: path_5 <= 2;
                3'd7: path_6 <= 2;
                default: path_7 <= 2;
              endcase
            end
            
            back_t <= length - 1;
            state <= BACKWARD;
            
          end else if (obs_valid) begin
            // Forward step calculation
            reg signed [W-1:0] new_delta_0, new_delta_1, new_delta_2;
            reg [1:0] new_psi_0, new_psi_1, new_psi_2;
            reg signed [W-1:0] emission_0, emission_1, emission_2;
            
            // Get emission probabilities
            case (obs_in)
              2'd0: begin
                emission_0 = logB_0; emission_1 = logB_3; emission_2 = logB_6;
              end
              2'd1: begin
                emission_0 = logB_1; emission_1 = logB_4; emission_2 = logB_7;
              end
              2'd2: begin
                emission_0 = logB_2; emission_1 = logB_5; emission_2 = logB_8;
              end
              default: begin
                emission_0 = logB_0; emission_1 = logB_3; emission_2 = logB_6;
              end
            endcase
            
            // Calculate new delta for state 0
            new_delta_0 = delta_0 + logA_0; // from state 0
            new_psi_0 = 0;
            if (delta_1 + logA_3 > new_delta_0) begin // from state 1
              new_delta_0 = delta_1 + logA_3;
              new_psi_0 = 1;
            end
            if (delta_2 + logA_6 > new_delta_0) begin // from state 2
              new_delta_0 = delta_2 + logA_6;
              new_psi_0 = 2;
            end
            new_delta_0 = new_delta_0 + emission_0;
            
            // Calculate new delta for state 1
            new_delta_1 = delta_0 + logA_1; // from state 0
            new_psi_1 = 0;
            if (delta_1 + logA_4 > new_delta_1) begin // from state 1
              new_delta_1 = delta_1 + logA_4;
              new_psi_1 = 1;
            end
            if (delta_2 + logA_7 > new_delta_1) begin // from state 2
              new_delta_1 = delta_2 + logA_7;
              new_psi_1 = 2;
            end
            new_delta_1 = new_delta_1 + emission_1;
            
            // Calculate new delta for state 2
            new_delta_2 = delta_0 + logA_2; // from state 0
            new_psi_2 = 0;
            if (delta_1 + logA_5 > new_delta_2) begin // from state 1
              new_delta_2 = delta_1 + logA_5;
              new_psi_2 = 1;
            end
            if (delta_2 + logA_8 > new_delta_2) begin // from state 2
              new_delta_2 = delta_2 + logA_8;
              new_psi_2 = 2;
            end
            new_delta_2 = new_delta_2 + emission_2;
            
            // Update deltas
            delta_0 <= new_delta_0;
            delta_1 <= new_delta_1;
            delta_2 <= new_delta_2;
            
            // Store psi values
            case (t)
              3'd1: begin
                psi_1_0 <= new_psi_0; psi_1_1 <= new_psi_1; psi_1_2 <= new_psi_2;
              end
              3'd2: begin
                psi_2_0 <= new_psi_0; psi_2_1 <= new_psi_1; psi_2_2 <= new_psi_2;
              end
              3'd3: begin
                psi_3_0 <= new_psi_0; psi_3_1 <= new_psi_1; psi_3_2 <= new_psi_2;
              end
              3'd4: begin
                psi_4_0 <= new_psi_0; psi_4_1 <= new_psi_1; psi_4_2 <= new_psi_2;
              end
              3'd5: begin
                psi_5_0 <= new_psi_0; psi_5_1 <= new_psi_1; psi_5_2 <= new_psi_2;
              end
              3'd6: begin
                psi_6_0 <= new_psi_0; psi_6_1 <= new_psi_1; psi_6_2 <= new_psi_2;
              end
              3'd7: begin
                psi_7_0 <= new_psi_0; psi_7_1 <= new_psi_1; psi_7_2 <= new_psi_2;
              end
            endcase
            
            t <= t + 1;
          end
        end

        BACKWARD: begin
          if (back_t == 0) begin
            state <= DONE;
            done <= 1;
          end else begin
            // Backtracking logic
            case (back_t)
              3'd1: begin
                case (path_1)
                  2'd0: path_0 <= psi_1_0;
                  2'd1: path_0 <= psi_1_1;
                  2'd2: path_0 <= psi_1_2;
                  default: path_0 <= 0;
                endcase
              end
              3'd2: begin
                case (path_2)
                  2'd0: path_1 <= psi_2_0;
                  2'd1: path_1 <= psi_2_1;
                  2'd2: path_1 <= psi_2_2;
                  default: path_1 <= 0;
                endcase
              end
              3'd3: begin
                case (path_3)
                  2'd0: path_2 <= psi_3_0;
                  2'd1: path_2 <= psi_3_1;
                  2'd2: path_2 <= psi_3_2;
                  default: path_2 <= 0;
                endcase
              end
              3'd4: begin
                case (path_4)
                  2'd0: path_3 <= psi_4_0;
                  2'd1: path_3 <= psi_4_1;
                  2'd2: path_3 <= psi_4_2;
                  default: path_3 <= 0;
                endcase
              end
              3'd5: begin
                case (path_5)
                  2'd0: path_4 <= psi_5_0;
                  2'd1: path_4 <= psi_5_1;
                  2'd2: path_4 <= psi_5_2;
                  default: path_4 <= 0;
                endcase
              end
              3'd6: begin
                case (path_6)
                  2'd0: path_5 <= psi_6_0;
                  2'd1: path_5 <= psi_6_1;
                  2'd2: path_5 <= psi_6_2;
                  default: path_5 <= 0;
                endcase
              end
              3'd7: begin
                case (path_7)
                  2'd0: path_6 <= psi_7_0;
                  2'd1: path_6 <= psi_7_1;
                  2'd2: path_6 <= psi_7_2;
                  default: path_6 <= 0;
                endcase
              end
            endcase
            back_t <= back_t - 1;
          end
        end

        DONE: begin
          if (!start) begin
            state <= IDLE;
            t <= 0;
            back_t <= 0;
          end
        end

      endcase
    end
  end

endmodule

