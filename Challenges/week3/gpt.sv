
// In-Place Q-Table Updater (Simplified)
// BOARD_ROWS=5, BOARD_COLS=5, ACTIONS=4

module q_learning_hw #(
  parameter ROWS    = 5,
  parameter COLS    = 5,
  parameter ACTIONS = 4,
  parameter DW      = 16  // data width for Q-values, fixed-point
) (
  input  logic                     clk,
  input  logic                     rst_n,
  // Inputs for current state & action
  input  logic [$clog2(ROWS)-1:0]  state_row,
  input  logic [$clog2(COLS)-1:0]  state_col,
  input  logic [$clog2(ACTIONS)-1:0] action,
  input  logic signed [DW-1:0]     reward,
  // Parameters α, γ as fixed-point
  input  logic signed [DW-1:0]     alpha,
  input  logic signed [DW-1:0]     gamma
);

  // -------------------------------------------------------------------
  // Dual-port SRAM for Q-table [row][col][act]
  // -------------------------------------------------------------------
  logic signed [DW-1:0] q_mem [0:ROWS-1][0:COLS-1][0:ACTIONS-1];

  // Read all action Q-values in one cycle
  logic signed [DW-1:0] q_vals [0:ACTIONS-1];
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      // Optionally init to zero
    end else begin
      for (int a = 0; a < ACTIONS; a++) begin
        q_vals[a] <= q_mem[state_row][state_col][a];
      end
    end
  end

  // -------------------------------------------------------------------
  // Max-Value Unit: comparator tree to find Q_max
  // -------------------------------------------------------------------
  logic signed [DW-1:0] q_max;
  always_comb begin
    q_max = q_vals[0];
    for (int a = 1; a < ACTIONS; a++) begin
      if (q_vals[a] > q_max)
        q_max = q_vals[a];
    end
  end

  // -------------------------------------------------------------------
  // Q-Update Unit: FMAC pipeline registers
  // -------------------------------------------------------------------
  logic signed [DW-1:0] q_curr, q_new;
  logic signed [2*DW-1:0] mac1, mac2, mac3;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      q_curr <= '0;
      q_new  <= '0;
    end else begin
      // Stage 1: fetch current Q
      q_curr <= q_mem[state_row][state_col][action];
      // Stage 2: compute (1-α)*q_curr
      mac1   <= ({{DW{1'b0}}, q_curr} * {{DW{1'b0}}, ({{DW-1{1'b0}},1'b1} << (DW-1)) - alpha});
      // Stage 3: compute reward + γ*q_max
      mac2   <= {{DW{1'b0}}, reward} + {{DW{1'b0}}, q_max} * {{DW{1'b0}}, gamma};
      // Stage 4: α * (R+γQ_max)
      mac3   <= alpha * mac2[DW-1:0];
      // Stage 5: final sum and normalize back to DW bits
      q_new  <= (mac1[DW-1:0] + mac3[DW-1:0]) >>> (DW/2);
    end
  end

  // -------------------------------------------------------------------
  // Direct Write-Back: update SRAM
  // -------------------------------------------------------------------
  always_ff @(posedge clk) begin
    if (rst_n) begin
      q_mem[state_row][state_col][action] <= q_new;
    end
  end

endmodule
