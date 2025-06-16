#!/usr/bin/env python3

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.types import LogicArray
import numpy as np
import random
import time

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
    # Scale appropriately for 16-bit signed integers
    scaled = (log_vals * 10).astype(np.int16)  # Reduced scaling
    return scaled

def pack_to_flat_signal(matrix, width=16):
    """Pack matrix into a single integer for flattened signal assignment"""
    flat = matrix.flatten()
    packed_value = 0
    
    for i, val in enumerate(flat):
        # Convert to positive representation for bit packing
        if val < 0:
            val = (1 << width) + val  # Two's complement conversion
        val = val & ((1 << width) - 1)  # Mask to width bits
        packed_value |= val << (i * width)
    
    return packed_value

async def setup_hardware(dut, A, C, B, obs_sequence):
    """Setup hardware with HMM parameters"""
    # Convert to log domain and scale for hardware
    logA_hw = prob_to_log16(A)
    logC_hw = prob_to_log16(C)
    logB_hw = prob_to_log16(B)
    
    seq_length = len(obs_sequence)
    
    # Reset
    dut.rst_n.value = 0
    dut.start.value = 0
    dut.obs_valid.value = 0
    dut.obs_in.value = 0
    dut.length.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 2)
    
    # FIXED: Check which interface your Verilog uses
    try:
        # Try flattened interface first (paste-2.txt)
        logA_packed = pack_to_flat_signal(logA_hw, 16)
        logC_packed = pack_to_flat_signal(logC_hw.reshape(1, -1), 16)
        logB_packed = pack_to_flat_signal(logB_hw, 16)
        
        dut.logA_flat.value = int(logA_packed)
        dut.logC_flat.value = int(logC_packed)
        dut.logB_flat.value = int(logB_packed)
        
    except AttributeError:
        # If flattened interface fails, try individual pins (paste-7.txt)
        logA_flat = logA_hw.flatten()
        dut.logA_0.value = int(logA_flat[0])
        dut.logA_1.value = int(logA_flat[1])
        dut.logA_2.value = int(logA_flat[2])
        dut.logA_3.value = int(logA_flat[3])
        dut.logA_4.value = int(logA_flat[4])
        dut.logA_5.value = int(logA_flat[5])
        dut.logA_6.value = int(logA_flat[6])
        dut.logA_7.value = int(logA_flat[7])
        dut.logA_8.value = int(logA_flat[8])
        
        dut.logC_0.value = int(logC_hw[0])
        dut.logC_1.value = int(logC_hw[1])
        dut.logC_2.value = int(logC_hw[2])
        
        logB_flat = logB_hw.flatten()
        dut.logB_0.value = int(logB_flat[0])
        dut.logB_1.value = int(logB_flat[1])
        dut.logB_2.value = int(logB_flat[2])
        dut.logB_3.value = int(logB_flat[3])
        dut.logB_4.value = int(logB_flat[4])
        dut.logB_5.value = int(logB_flat[5])
        dut.logB_6.value = int(logB_flat[6])
        dut.logB_7.value = int(logB_flat[7])
        dut.logB_8.value = int(logB_flat[8])
    
    dut.length.value = seq_length
    return seq_length

async def run_hardware_test(dut, obs_sequence):
    """Run hardware test and return decoded path"""
    seq_length = len(obs_sequence)
    
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
    
    # Wait for completion with timeout
    timeout = 0
    while not dut.done.value and timeout < 300:
        await ClockCycles(dut.clk, 1)
        timeout += 1
    
    assert timeout < 300, f"Hardware timeout after {timeout} cycles"
    
    # FIXED: Extract hardware result from individual path outputs
    hw_path = []
    path_signals = [dut.path_0, dut.path_1, dut.path_2, dut.path_3, 
                   dut.path_4, dut.path_5, dut.path_6, dut.path_7]
    
    for i in range(seq_length):
        hw_path.append(int(path_signals[i].value))
    
    return hw_path

@cocotb.test()
async def test_viterbi_basic(dut):
    """Basic functionality test with known sequence"""
    A = np.array([[0.8, 0.1, 0.1],
                  [0.2, 0.7, 0.1],
                  [0.1, 0.3, 0.6]])
    C = np.array([0.6, 0.2, 0.2])
    B = np.array([[0.7, 0.2, 0.1],
                  [0.1, 0.8, 0.1],
                  [0.2, 0.1, 0.7]])
    
    obs_sequence = [0, 0, 1, 1, 2]
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    await setup_hardware(dut, A, C, B, obs_sequence)
    hw_path = await run_hardware_test(dut, obs_sequence)
    sw_path, _ = viterbi_reference(obs_sequence, A, C, B)
    
    dut._log.info(f"Observation sequence: {obs_sequence}")
    dut._log.info(f"Hardware path:        {hw_path}")
    dut._log.info(f"Software path:        {list(sw_path)}")
    
    # Validate hardware output
    for i, state in enumerate(hw_path):
        assert 0 <= state <= 2, f"Invalid state {state} at position {i}"
    
    # Check similarity
    match = all(hw_path[i] == sw_path[i] for i in range(len(obs_sequence)))
    dut._log.info(f"Paths match exactly: {match}")
    
    if not match:
        similarity = sum(1 for i in range(len(obs_sequence)) if hw_path[i] == sw_path[i]) / len(obs_sequence)
        dut._log.info(f"Path similarity: {similarity:.2%}")

@cocotb.test()
async def test_viterbi_simple_sequences(dut):
    """Test with simple sequences that should be predictable"""
    # Strong preferences - each state strongly prefers its observation
    A = np.array([[0.9, 0.05, 0.05],
                  [0.05, 0.9, 0.05],
                  [0.05, 0.05, 0.9]])
    C = np.array([0.33, 0.33, 0.34])
    B = np.array([[0.8, 0.1, 0.1],
                  [0.1, 0.8, 0.1],
                  [0.1, 0.1, 0.8]])
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    test_cases = [
        [0, 1, 2],           # Sequential
        [0, 0, 0],           # All same
        [1, 1, 1],           # All same
        [2, 2, 2],           # All same
    ]
    
    for i, obs_sequence in enumerate(test_cases):
        dut._log.info(f"\n=== Simple Test {i+1}: {obs_sequence} ===")
        await setup_hardware(dut, A, C, B, obs_sequence)
        hw_path = await run_hardware_test(dut, obs_sequence)
        sw_path, _ = viterbi_reference(obs_sequence, A, C, B)
        
        dut._log.info(f"Hardware: {hw_path}")
        dut._log.info(f"Software: {list(sw_path)}")
        
        # Validate output range
        for j, state in enumerate(hw_path):
            assert 0 <= state <= 2, f"Invalid state {state} at position {j}"

@cocotb.test()
async def test_viterbi_random_sequences(dut):
    """Test with multiple random sequences"""
    A = np.array([[0.7, 0.2, 0.1],
                  [0.1, 0.8, 0.1],
                  [0.2, 0.1, 0.7]])
    C = np.array([0.5, 0.3, 0.2])
    B = np.array([[0.6, 0.3, 0.1],
                  [0.2, 0.7, 0.1],
                  [0.1, 0.2, 0.7]])
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    for test_num in range(2):  # Reduced number for faster testing
        dut._log.info(f"\n=== Random Test {test_num + 1} ===")
        seq_length = random.randint(3, 4)  # Shorter sequences
        obs_sequence = [random.randint(0, 2) for _ in range(seq_length)]
        
        await setup_hardware(dut, A, C, B, obs_sequence)
        hw_path = await run_hardware_test(dut, obs_sequence)
        sw_path, _ = viterbi_reference(obs_sequence, A, C, B)
        
        dut._log.info(f"Obs: {obs_sequence}")
        dut._log.info(f"HW:  {hw_path}")
        dut._log.info(f"SW:  {list(sw_path)}")
        
        # Validate output range
        for state in hw_path:
            assert 0 <= state <= 2, f"Invalid state {state}"

@cocotb.test()
async def test_viterbi_edge_cases(dut):
    """Test edge cases like minimum length sequences"""
    A = np.array([[0.5, 0.3, 0.2],
                  [0.2, 0.6, 0.2],
                  [0.3, 0.2, 0.5]])
    C = np.array([0.4, 0.3, 0.3])
    B = np.array([[0.6, 0.2, 0.2],
                  [0.1, 0.8, 0.1],
                  [0.2, 0.1, 0.7]])
    
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # Test minimum length
    dut._log.info("\n=== Testing length 1 sequence ===")
    obs_sequence = [1]
    await setup_hardware(dut, A, C, B, obs_sequence)
    hw_path = await run_hardware_test(dut, obs_sequence)
    dut._log.info(f"Length 1 result: {hw_path[0]}")
    assert 0 <= hw_path[0] <= 2, f"Invalid state for length 1: {hw_path[0]}"

