`timescale 1ns/1ps

module tb_viterbi;
  
  parameter W = 16;
  
  reg clk, rst_n, start, obs_valid;
  reg [2:0] length;
  reg [1:0] obs_in;
  
  // Individual pin connections
  reg signed [W-1:0] logA_0, logA_1, logA_2, logA_3, logA_4, logA_5, logA_6, logA_7, logA_8;
  reg signed [W-1:0] logC_0, logC_1, logC_2;
  reg signed [W-1:0] logB_0, logB_1, logB_2, logB_3, logB_4, logB_5, logB_6, logB_7, logB_8;
  
  wire [1:0] path_0, path_1, path_2, path_3, path_4;
  wire done;

  always #5 clk = ~clk;

  viterbi_top dut (
    .clk(clk), .rst_n(rst_n), .start(start), .length(length),
    .obs_in(obs_in), .obs_valid(obs_valid),
    .logA_0(logA_0), .logA_1(logA_1), .logA_2(logA_2),
    .logA_3(logA_3), .logA_4(logA_4), .logA_5(logA_5),
    .logA_6(logA_6), .logA_7(logA_7), .logA_8(logA_8),
    .logC_0(logC_0), .logC_1(logC_1), .logC_2(logC_2),
    .logB_0(logB_0), .logB_1(logB_1), .logB_2(logB_2),
    .logB_3(logB_3), .logB_4(logB_4), .logB_5(logB_5),
    .logB_6(logB_6), .logB_7(logB_7), .logB_8(logB_8),
    .path_0(path_0), .path_1(path_1), .path_2(path_2), 
    .path_3(path_3), .path_4(path_4), .path_5(), .path_6(), .path_7(),
    .done(done)
  );

  initial begin
    clk = 0; rst_n = 0; start = 0; obs_valid = 0;

    // Simple HMM parameters - each state strongly prefers its own observation
    // Transition matrix A (strong self-transitions)
    logA_0 = -16'd5;   logA_1 = -16'd50;  logA_2 = -16'd50;  // from state 0
    logA_3 = -16'd50;  logA_4 = -16'd5;   logA_5 = -16'd50;  // from state 1
    logA_6 = -16'd50;  logA_7 = -16'd50;  logA_8 = -16'd5;   // from state 2

    // Initial state probabilities (equal)
    logC_0 = -16'd10;  logC_1 = -16'd10;  logC_2 = -16'd10;

    // Emission matrix B (each state prefers its observation)
    logB_0 = -16'd1;   logB_1 = -16'd50;  logB_2 = -16'd50;  // state 0 prefers obs 0
    logB_3 = -16'd50;  logB_4 = -16'd1;   logB_5 = -16'd50;  // state 1 prefers obs 1
    logB_6 = -16'd50;  logB_7 = -16'd50;  logB_8 = -16'd1;   // state 2 prefers obs 2

    #10 rst_n = 1;
    #10;

    $display("=== Simple Test: [0, 1, 2] ===");
    $display("Expected: [0, 1, 2] (each state prefers its observation)");
    
    length = 3;
    
    // Test sequence: 0, 1, 2
    obs_in = 0;
    start = 1;
    #10 start = 0;

    @(posedge clk); obs_in = 1; obs_valid = 1;
    @(posedge clk); obs_valid = 0;
    @(posedge clk); obs_in = 2; obs_valid = 1;
    @(posedge clk); obs_valid = 0;

    wait(done);
    #20;

    $display("Result: [%d, %d, %d]", path_0, path_1, path_2);
    
    if (path_0 == 0 && path_1 == 1 && path_2 == 2)
      $display("PASS: Correct result");
    else
      $display("FAIL: Incorrect result");
    
    #50 $finish;
  end

  // Debug monitor
  always @(posedge clk) begin
    if (dut.state == 1) // FORWARD
      $display("Time=%0t t=%d obs=%d deltas=[%d,%d,%d] state=%d", 
               $time, dut.t, obs_in, 
               dut.delta_0, dut.delta_1, dut.delta_2, dut.state);
    if (dut.state == 2) // BACKWARD
      $display("Time=%0t BACKWARD back_t=%d paths=[%d,%d,%d]", 
               $time, dut.back_t, path_0, path_1, path_2);
  end

endmodule

