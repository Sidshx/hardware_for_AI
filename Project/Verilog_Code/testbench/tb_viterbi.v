`timescale 1ns/1ps

module tb_viterbi;

parameter N = 8, I = 3, K = 3, W = 16;

reg clk, rst_n, start, obs_valid;
reg [2:0] length;
reg [1:0] obs_in;

// Flattened arrays for synthesis compatibility
reg signed [W*9-1:0] logA_flat;
reg signed [W*3-1:0] logC_flat;
reg signed [W*9-1:0] logB_flat;

// Flattened output
wire [2*8-1:0] path_flat;
wire done;

// Test observation sequence
reg [1:0] obs_seq_0, obs_seq_1, obs_seq_2;
integer obs_idx;

// Clock generation
always #5 clk = ~clk;

// DUT instantiation
viterbi_top dut (
    .clk(clk), 
    .rst_n(rst_n), 
    .start(start), 
    .length(length),
    .obs_in(obs_in), 
    .obs_valid(obs_valid),
    .logA_flat(logA_flat), 
    .logC_flat(logC_flat), 
    .logB_flat(logB_flat),
    .path_flat(path_flat), 
    .done(done)
);

initial begin
    // Initialize
    clk = 0; rst_n = 0; start = 0; obs_valid = 0;
    obs_in = 0; length = 3; obs_idx = 0;

    // Simple HMM parameters
    logA_flat[W-1:0] = -16'd20;        
    logA_flat[2*W-1:W] = -16'd20;      
    logA_flat[3*W-1:2*W] = -16'd20;    
    logA_flat[4*W-1:3*W] = -16'd20;    
    logA_flat[5*W-1:4*W] = -16'd20;    
    logA_flat[6*W-1:5*W] = -16'd20;    
    logA_flat[7*W-1:6*W] = -16'd20;    
    logA_flat[8*W-1:7*W] = -16'd20;    
    logA_flat[9*W-1:8*W] = -16'd20;

    logC_flat[W-1:0] = -16'd20;        
    logC_flat[2*W-1:W] = -16'd20;      
    logC_flat[3*W-1:2*W] = -16'd20;

    // Strong emission preferences
    logB_flat[W-1:0] = 16'd0;          
    logB_flat[2*W-1:W] = -16'd1000;    
    logB_flat[3*W-1:2*W] = -16'd1000;  
    logB_flat[4*W-1:3*W] = -16'd1000;  
    logB_flat[5*W-1:4*W] = 16'd0;      
    logB_flat[6*W-1:5*W] = -16'd1000;  
    logB_flat[7*W-1:6*W] = -16'd1000;  
    logB_flat[8*W-1:7*W] = -16'd1000;  
    logB_flat[9*W-1:8*W] = 16'd0;

    // Test sequence: [0, 1, 2] should give [0, 1, 2]
    obs_seq_0 = 1; obs_seq_1 = 1; obs_seq_2 = 0;

    #10 rst_n = 1;
    #10;

    $display("=== Viterbi Test (Fixed Version) ===");
    $display("Observation sequence: %d %d %d", obs_seq_0, obs_seq_1, obs_seq_2);

    // Start with first observation
    obs_in = obs_seq_0;
    start = 1;
    #10 start = 0;

    // Feed remaining observations
    @(posedge clk);
    obs_in = obs_seq_1;
    obs_valid = 1;
    @(posedge clk);
    obs_valid = 0;
    
    @(posedge clk);
    obs_in = obs_seq_2;
    obs_valid = 1;
    @(posedge clk);
    obs_valid = 0;

    // Wait for completion
    wait(done);
    #20;

    $display("Decoded state sequence: %d %d %d", path_flat[1:0], path_flat[3:2], path_flat[5:4]);
    $display("Expected: 0 1 2");
    $display("Path flat output: 0x%h", path_flat);
    
    if (path_flat[1:0] == 0 && path_flat[3:2] == 1 && path_flat[5:4] == 2) begin
        $display("*** TEST PASSED ***");
    end else begin
        $display("*** TEST FAILED ***");
    end
    
    $display("=== Test Complete ===");
    #50 $finish;
end

// Monitor
always @(posedge clk) begin
    if (dut.state == 2) begin  // BACKWARD state
        $display("Backtrack: back_t=%d, current_state=%d, prev_state=%d", 
                 dut.back_t, dut.current_state, dut.prev_state);
    end
end

endmodule

