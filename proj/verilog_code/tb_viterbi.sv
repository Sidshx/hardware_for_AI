//==============================================================================
// TESTBENCH
//==============================================================================

module tb_viterbi;

  parameter N = 8;   // sequence length  
  parameter I = 3;   // states
  parameter K = 3;   // symbols
  parameter W = 20;  // width

  // Testbench signals
  reg                      clk;
  reg                      rst_n;
  reg                      start;
  reg  [$clog2(N)-1:0]     length;
  reg  [$clog2(K)-1:0]     obs_in;
  reg                      obs_valid;
  reg  signed [W-1:0]      logA [0:I*I-1];
  reg  signed [W-1:0]      logC [0:I-1];
  reg  signed [W-1:0]      logB [0:I*K-1];
  wire [$clog2(I)-1:0]     path [0:N-1];
  wire                     done;
  wire                     valid_out;

  // Test sequence
  reg [$clog2(K)-1:0] test_obs [0:N-1];
  reg [$clog2(N)-1:0] obs_count;

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // DUT instantiation
  viterbi_top #(
    .N(N), .I(I), .K(K), .W(W)
  ) dut (
    .clk(clk),
    .rst_n(rst_n),
    .start(start),
    .length(length),
    .obs_in(obs_in),
    .obs_valid(obs_valid),
    .logA(logA),
    .logC(logC),
    .logB(logB),
    .path(path),
    .done(done),
    .valid_out(valid_out)
  );

  integer i, j, k;

  // Test stimulus
  initial begin
    // Initialize
    rst_n = 0;
    start = 0;
    obs_in = 0;
    obs_valid = 0;
    length = 5;
    obs_count = 0;

    // Initialize HMM parameters (simplified values)
    // logA: transition probabilities (log domain)
    for (i = 0; i < I*I; i = i + 1) begin
      logA[i] = -20'sd100; // Small transition prob
    end
    // Diagonal elements higher (stay in same state more likely)
    logA[0*I + 0] = -20'sd10;  // logA[0][0]
    logA[1*I + 1] = -20'sd10;  // logA[1][1] 
    logA[2*I + 2] = -20'sd10;  // logA[2][2]
    logA[0*I + 1] = -20'sd50;  // logA[0][1]
    logA[1*I + 2] = -20'sd50;  // logA[1][2]
    logA[2*I + 0] = -20'sd50;  // logA[2][0]

    // logC: initial state probabilities
    logC[0] = -20'sd10;
    logC[1] = -20'sd50;
    logC[2] = -20'sd50;

    // logB: emission probabilities
    for (i = 0; i < I*K; i = i + 1) begin
      logB[i] = -20'sd100;
    end
    // State 0 prefers obs 0, state 1 prefers obs 1, state 2 prefers obs 2
    logB[0*K + 0] = -20'sd5;   // logB[0][0]
    logB[1*K + 1] = -20'sd5;   // logB[1][1]
    logB[2*K + 2] = -20'sd5;   // logB[2][2]

    // Test observation sequence
    test_obs[0] = 0;
    test_obs[1] = 0;
    test_obs[2] = 1;
    test_obs[3] = 1;
    test_obs[4] = 2;

    // Reset
    #20 rst_n = 1;
    #20;

    $display("Starting Viterbi test...");
    $display("Test sequence: %d %d %d %d %d", 
             test_obs[0], test_obs[1], test_obs[2], test_obs[3], test_obs[4]);

    // Start processing  
    start = 1;
    obs_in = test_obs[0];
    obs_valid = 1;
    #10 start = 0;

    // Feed observations
    for (k = 1; k < length; k = k + 1) begin
      @(posedge clk);
      obs_in = test_obs[k];
      obs_valid = 1;
      #1; // Small delay
    end

    obs_valid = 0;

    // Wait for completion
    wait(done);
    @(posedge clk);

    $display("Viterbi decoding complete!");
    $display("Decoded path: %d %d %d %d %d", 
             path[0], path[1], path[2], path[3], path[4]);

    #50;
    $finish;
  end

  // Monitor
  initial begin
    $monitor("t=%0t state=%d t=%d obs_in=%d obs_valid=%d done=%d", 
             $time, dut.state, dut.t, obs_in, obs_valid, done);
  end

  // Waveform dump
  initial begin
    $dumpfile("viterbi_tb.vcd");
    $dumpvars(0, tb_viterbi_top);
  end

endmodule