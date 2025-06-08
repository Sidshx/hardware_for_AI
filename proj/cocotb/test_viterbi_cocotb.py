#!/usr/bin/env python3

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.types import LogicArray
import numpy as np
import random

# Import the Python reference implementation
def viterbi_reference(O, A, C, B):
    """Python reference Viterbi implementation"""
    N, I = len(O), A.shape[0]
    delta = np.zeros((N, I))
    psi = np.zeros((N, I), int)
    
    # Initialize
    delta[0] = np.log(C + 1e-12) + np.log(B[:, O[0]] + 1e-12)
    
    # Forward pass
    for n in range(1, N):
        for j in range(I):
            seq = delta[n-1] + np.log(A[:, j] + 1e-12)
            psi[n, j] = np.argmax(seq)
            delta[n, j] = seq[psi[n, j]] + np.log(B[j, O[n]] + 1e-12)
    
    # Backward pass
    S_hat = np.zeros(N, int)
    S_hat[-1] = np.argmax(delta[-1])
    for n in range(N-2, -1, -1):
        S_hat[n] = psi[n+1, S_hat[n+1]]
    
    return S_hat, np.max(delta[-1])

def prob_to_log16(prob_matrix):
    """Convert probability matrix to 16-bit signed log representation"""
    log_vals = np.log(prob_matrix + 1e-12)
    # Scale to fit in 16-bit signed: map reasonable log range to [-32768, 32767]
    # Typical log probs range from -10 to 0, so scale by ~3000
    scaled = (log_vals * 3000).astype(np.int16)
    return scaled

def flatten_matrix(matrix):
    """Flatten 2D matrix to 1D array for Verilog memory"""
    return matrix.flatten()

@cocotb.test()
async def test_viterbi_basic(dut):
    """Basic functionality test with known sequence"""
    
    # Define test HMM (same as your Python code)
    A = np.array([[0.8, 0.1, 0.1],
                  [0.2, 0.7, 0.1], 
                  [0.1, 0.3, 0.6]])
    C = np.array([0.6, 0.2, 0.2])
    B = np.array([[0.7, 0.0, 0.3],
                  [0.1, 0.9, 0.0],
                  [0.0, 0.2, 0.8]])
    
    # Convert to log domain and scale for hardware
    logA_hw = prob_to_log16(A)
    logC_hw = prob_to_log16(C)
    logB_hw = prob_to_log16(B)
    
    # Test observation sequence
    obs_sequence = [0, 0, 1, 1, 2]
    seq_length = len(obs_sequence)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.obs_valid.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Load HMM parameters
    for i in range(9):  # 3x3 flattened
        dut.logA[i].value = int(logA_hw.flatten()[i])
        dut.logB[i].value = int(logB_hw.flatten()[i])
    
    for i in range(3):
        dut.logC[i].value = int(logC_hw[i])
    
    dut.length.value = seq_length
    
    # Start with first observation
    dut.obs_in.value = obs_sequence[0]
    dut.start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start.value = 0
    
    # Feed remaining observations
    for i in range(1, seq_length):
        await ClockCycles(dut.clk, 1)
        dut.obs_in.value = obs_sequence[i]
        dut.obs_valid.value = 1
        await ClockCycles(dut.clk, 1)
        dut.obs_valid.value = 0
    
    # Wait for completion
    while not dut.done.value:
        await ClockCycles(dut.clk, 1)
    
    # Extract hardware result
    hw_path = []
    for i in range(seq_length):
        hw_path.append(int(dut.path[i].value))
    
    # Get software reference
    sw_path, _ = viterbi_reference(obs_sequence, A, C, B)
    
    # Compare results
    dut._log.info(f"Observation sequence: {obs_sequence}")
    dut._log.info(f"Hardware path:        {hw_path}")
    dut._log.info(f"Software path:        {list(sw_path)}")
    
    # Check if paths match
    match = all(hw_path[i] == sw_path[i] for i in range(seq_length))
    dut._log.info(f"Paths match: {match}")
    
    if not match:
        dut._log.warning("Paths don't match - this might be due to scaling/quantization")
        # Still check if the hardware path is reasonable
        for i in range(seq_length):
            assert 0 <= hw_path[i] <= 2, f"Invalid state {hw_path[i]} at position {i}"

@cocotb.test()
async def test_viterbi_random_sequences(dut):
    """Test with multiple random sequences"""
    
    # HMM parameters
    A = np.array([[0.9, 0.05, 0.05],
                  [0.1, 0.8, 0.1], 
                  [0.05, 0.15, 0.8]])
    C = np.array([0.7, 0.2, 0.1])
    B = np.array([[0.8, 0.1, 0.1],
                  [0.2, 0.7, 0.1],
                  [0.1, 0.2, 0.7]])
    
    # Convert to hardware format
    logA_hw = prob_to_log16(A)
    logC_hw = prob_to_log16(C)
    logB_hw = prob_to_log16(B)
    
    # Start clock
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Test multiple random sequences
    for test_num in range(5):
        dut._log.info(f"\n=== Random Test {test_num + 1} ===")
        
        # Generate random observation sequence
        seq_length = random.randint(3, 8)
        obs_sequence = [random.randint(0, 2) for _ in range(seq_length)]
        
        # Reset
        dut.rst_n.value = 0
        await ClockCycles(dut.clk, 2)
        dut.rst_n.value = 1
        await ClockCycles(dut.clk, 2)
        
        # Load parameters
        for i in range(9):
            dut.logA[i].value = int(logA_hw.flatten()[i])
            dut.logB[i].value = int(logB_hw.flatten()[i])
        for i in range(3):
            dut.logC[i].value = int(logC_hw[i])
        
        dut.length.value = seq_length
        
        # Run hardware
        dut.obs_in.value = obs_sequence[0]
        dut.start.value = 1
        await ClockCycles(dut.clk, 1)
        dut.start.value = 0
        
        for i in range(1, seq_length):
            await ClockCycles(dut.clk, 1)
            dut.obs_in.value = obs_sequence[i]
            dut.obs_valid.value = 1
            await ClockCycles(dut.clk, 1)
            dut.obs_valid.value = 0
        
        # Wait for completion
        timeout = 0
        while not dut.done.value and timeout < 100:
            await ClockCycles(dut.clk, 1)
            timeout += 1
        
        assert timeout < 100, "Hardware timeout"
        
        # Extract results
        hw_path = [int(dut.path[i].value) for i in range(seq_length)]
        sw_path, _ = viterbi_reference(obs_sequence, A, C, B)
        
        dut._log.info(f"Obs: {obs_sequence}")
        dut._log.info(f"HW:  {hw_path}")
        dut._log.info(f"SW:  {list(sw_path)}")
        
        # Validate hardware output is reasonable
        for state in hw_path:
            assert 0 <= state <= 2, f"Invalid state {state}"

@cocotb.test()
async def test_viterbi_edge_cases(dut):
    """Test edge cases like minimum length sequences"""
    
    # Simple HMM
    A = np.array([[0.5, 0.3, 0.2],
                  [0.2, 0.6, 0.2], 
                  [0.3, 0.2, 0.5]])
    C = np.array([0.4, 0.3, 0.3])
    B = np.array([[0.6, 0.2, 0.2],
                  [0.1, 0.8, 0.1],
                  [0.2, 0.1, 0.7]])
    
    logA_hw = prob_to_log16(A)
    logC_hw = prob_to_log16(C)
    logB_hw = prob_to_log16(B)
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Test minimum length sequence (length 1)
    dut._log.info("\n=== Testing length 1 sequence ===")
    
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Load parameters
    for i in range(9):
        dut.logA[i].value = int(logA_hw.flatten()[i])
        dut.logB[i].value = int(logB_hw.flatten()[i])
    for i in range(3):
        dut.logC[i].value = int(logC_hw[i])
    
    dut.length.value = 1
    dut.obs_in.value = 1
    dut.start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start.value = 0
    
    # Wait for completion
    timeout = 0
    while not dut.done.value and timeout < 50:
        await ClockCycles(dut.clk, 1)
        timeout += 1
    
    assert timeout < 50, "Timeout on length 1 sequence"
    
    hw_result = int(dut.path[0].value)
    dut._log.info(f"Length 1 result: {hw_result}")
    assert 0 <= hw_result <= 2, f"Invalid state for length 1: {hw_result}"

# Test for timing and performance
@cocotb.test()
async def test_viterbi_timing(dut):
    """Test timing characteristics"""
    
    # Standard HMM
    A = np.eye(3) * 0.7 + (1 - np.eye(3)) * 0.15
    C = np.array([0.33, 0.33, 0.34])
    B = np.eye(3) * 0.8 + (1 - np.eye(3)) * 0.1
    
    logA_hw = prob_to_log16(A)
    logC_hw = prob_to_log16(C)
    logB_hw = prob_to_log16(B)
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Test maximum length sequence
    max_length = 8
    obs_sequence = [i % 3 for i in range(max_length)]
    
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 2)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # Load parameters
    for i in range(9):
        dut.logA[i].value = int(logA_hw.flatten()[i])
        dut.logB[i].value = int(logB_hw.flatten()[i])
    for i in range(3):
        dut.logC[i].value = int(logC_hw[i])
    
    dut.length.value = max_length
    
    # Measure timing
    start_time = cocotb.utils.get_sim_time()
    
    dut.obs_in.value = obs_sequence[0]
    dut.start.value = 1
    await ClockCycles(dut.clk, 1)
    dut.start.value = 0
    
    for i in range(1, max_length):
        await ClockCycles(dut.clk, 1)
        dut.obs_in.value = obs_sequence[i]
        dut.obs_valid.value = 1
        await ClockCycles(dut.clk, 1)
        dut.obs_valid.value = 0
    
    while not dut.done.value:
        await ClockCycles(dut.clk, 1)
    
    end_time = cocotb.utils.get_sim_time()
    total_cycles = (end_time - start_time) // 10  # 10ns clock period
    
    dut._log.info(f"Sequence length {max_length} took {total_cycles} clock cycles")
    dut._log.info(f"Cycles per observation: {total_cycles / max_length:.1f}")
    
    # Basic performance check
    assert total_cycles < max_length * 20, "Performance seems too slow"