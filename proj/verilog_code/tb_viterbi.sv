
`timescale 1ns/1ps

module tb_viterbi;

  //-----------------------------------------------------------------------------
  // Parameters must match your RTL
  //-----------------------------------------------------------------------------
  localparam int I = 3;   // # hidden states
  localparam int K = 3;   // # observation symbols
  localparam int N = 5;   // length of test sequence
  localparam int W = 20;  // fixed-point bit-width

  //-----------------------------------------------------------------------------
  // DUT interface signals
  //-----------------------------------------------------------------------------
  reg                       clk;
  reg                       rst_n;
  reg                       start;
  reg  [$clog2(N)-1:0]      length;
  reg  [$clog2(K)-1:0]      obs_in;
  reg                       obs_valid;

  // HMM parameters (must be regs so we can drive them)
  reg signed [W-1:0]        logA [0:I-1][0:I-1];
  reg signed [W-1:0]        logC [0:I-1];
  reg signed [W-1:0]        logB [0:I-1][0:K-1];

  // DUT outputs
  wire [$clog2(I)-1:0]      path [0:N-1];
  wire                      done;

  //-----------------------------------------------------------------------------
  // Instantiate your top-level (viterbi_top)
  //-----------------------------------------------------------------------------
  viterbi_top #(
    .I(I),
    .K(K),
    .N(N),
    .W(W)
  ) uut (
    .clk       (clk),
    .rst_n     (rst_n),
    .start     (start),
    .length    (length),
    .obs_in    (obs_in),
    .obs_valid (obs_valid),
    .logA      (logA),
    .logC      (logC),
    .logB      (logB),
    .path      (path),
    .done      (done)
  );

  //-----------------------------------------------------------------------------
  // Clock generator: 10 ns period
  //-----------------------------------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  integer i;

  //-----------------------------------------------------------------------------
  // Test sequence
  //-----------------------------------------------------------------------------
  initial begin
    // 1) Drive reset *before* any posedge clk
    rst_n     = 1;
    start     = 0;
    obs_valid = 0;
    length    = 0;
    #1;             // let nets settle
    rst_n     = 0;  // assert
    #20;            // hold for two full clock cycles
    rst_n     = 1;  // release just before the 3rd rising edge

    // 2) Initialize HMM parameters
    logC[0] = 20;  logC[1] = 18;  logC[2] = 16;
    logA[0][0] = 20; logA[0][1] = 10; logA[0][2] =  5;
    logA[1][0] = 10; logA[1][1] = 20; logA[1][2] =  5;
    logA[2][0] =  5; logA[2][1] = 10; logA[2][2] = 20;
    logB[0][0] = 15; logB[0][1] = 10; logB[0][2] =  5;
    logB[1][0] = 10; logB[1][1] = 20; logB[1][2] =  5;
    logB[2][0] =  5; logB[2][1] = 15; logB[2][2] = 20;

    // 3) Kick off a Viterbi run of length N
    length = N;
    start  = 1;
    #10;
    start  = 0;

    // 4) Stream N observations: 0,1,2,0,1
    for (i = 0; i < N; i = i + 1) begin
      obs_valid = 1;
      obs_in    = i % K;
      #10;
    end
    obs_valid = 0;

    // 5) Wait for done, then one extra cycle so back–pointer writes path[0]
    wait(done);
    #10;

    // 6) Print out the decoded path
    $display("\n=== Viterbi accelerator result ===");
    for (i = 0; i < N; i = i + 1)
      $display(" path[%0d] = %0d", i, path[i]);

    $finish;
  end

endmodule
