//==============================================================================
// SIMPLE TESTBENCH
//==============================================================================

module tb_viterbi;
  
  parameter N = 8, I = 3, K = 3, W = 16;
  
  reg clk, rst_n, start, obs_valid;
  reg [2:0] length;
  reg [1:0] obs_in;
  reg signed [W-1:0] logA [0:8];
  reg signed [W-1:0] logC [0:2]; 
  reg signed [W-1:0] logB [0:8];
  wire [1:0] path [0:7];
  wire done;

  // Test observation sequence
  reg [1:0] obs_seq [0:4];
  integer obs_idx;

  // Clock
  always #5 clk = ~clk;

  // DUT
  viterbi_top dut (
    .clk(clk), .rst_n(rst_n), .start(start), .length(length),
    .obs_in(obs_in), .obs_valid(obs_valid),
    .logA(logA), .logC(logC), .logB(logB),
    .path(path), .done(done)
  );

  integer i;

  initial begin
    // Initialize
    clk = 0; rst_n = 0; start = 0; obs_valid = 0;
    obs_in = 0; length = 5; obs_idx = 0;

    // Simple HMM parameters (small negative numbers in log domain)
    // Transition matrix logA (prefer staying in same state)
    logA[0] = -16'd10;  logA[1] = -16'd50;  logA[2] = -16'd50;  // from state 0
    logA[3] = -16'd50;  logA[4] = -16'd10;  logA[5] = -16'd50;  // from state 1  
    logA[6] = -16'd50;  logA[7] = -16'd50;  logA[8] = -16'd10;  // from state 2

    // Initial state probs (favor state 0)
    logC[0] = -16'd5;   logC[1] = -16'd50;  logC[2] = -16'd50;

    // Emission matrix logB (each state prefers different observation)
    logB[0] = -16'd5;   logB[1] = -16'd50;  logB[2] = -16'd50;  // state 0 prefers obs 0
    logB[3] = -16'd50;  logB[4] = -16'd5;   logB[5] = -16'd50;  // state 1 prefers obs 1
    logB[6] = -16'd50;  logB[7] = -16'd50;  logB[8] = -16'd5;   // state 2 prefers obs 2

    // Test sequence
    obs_seq[0] = 0; obs_seq[1] = 0; obs_seq[2] = 1; obs_seq[3] = 1; obs_seq[4] = 2;

    // Reset
    #10 rst_n = 1;
    #10;

    $display("=== Viterbi Test ===");
    $display("Observation sequence: %d %d %d %d %d", 
             obs_seq[0], obs_seq[1], obs_seq[2], obs_seq[3], obs_seq[4]);

    // Start with first observation
    obs_in = obs_seq[0];
    start = 1;
    #10 start = 0;

    // Feed remaining observations
    for (obs_idx = 1; obs_idx < 5; obs_idx = obs_idx + 1) begin
      @(posedge clk);
      obs_in = obs_seq[obs_idx];
      obs_valid = 1;
      @(posedge clk);
      obs_valid = 0;
    end

    // Wait for completion
    wait(done);
    #20;

    $display("Decoded state sequence: %d %d %d %d %d", 
             path[0], path[1], path[2], path[3], path[4]);
    $display("=== Test Complete ===");
    
    #50 $finish;
  end

  // Simple monitor
  always @(posedge clk) begin
    if (dut.state != 0) 
      $display("Time=%0t State=%d t=%d obs=%d done=%d", 
               $time, dut.state, dut.t, obs_in, done);
  end

//  initial begin
//    $dumpfile("viterbi.vcd");
//    $dumpvars(0, tb_viterbi);
//  end

endmodule
