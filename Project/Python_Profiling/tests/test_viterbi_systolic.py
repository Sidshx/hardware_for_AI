# tests/test_viterbi_systolic.py
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import numpy as np

# Python reference for one Viterbi step
def viterbi_step_ref(delta_prev, logA_col, logB_j):
    sums = delta_prev + logA_col
    best_i = int(np.argmax(sums))
    best_val = sums[best_i] + logB_j
    return best_val, best_i

@cocotb.test()
async def test_random_pe_chain(dut):
    """Test the systolic Viterbi chain with random inputs."""
    FW = len(dut.delta_prev[0])  # bit-width
    I  = len(dut.delta_prev)

    # Start a 10 ns clock on dut.clk
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())

    # reset
    dut.rst_n.value = 0
    dut.start.value = 0
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # number of random trials
    for trial in range(20):
        # random fixed-point inputs (interpret as signed ints)
        delta_prev = np.random.randint(-2**(FW-1), 2**(FW-1)-1, size=I)
        logA_col   = np.random.randint(-2**(FW-1), 2**(FW-1)-1, size=I)
        logB_j     = np.random.randint(-2**(FW-1), 2**(FW-1)-1)

        # drive the vectors
        for i in range(I):
            dut.delta_prev[i].value = int(delta_prev[i])
            dut.logA_col[i].value   = int(logA_col[i])
        dut.logB_j.value = int(logB_j)

        # pulse start
        dut.start.value = 1
        await RisingEdge(dut.clk)
        dut.start.value = 0

        # wait until done
        while dut.done.value == 0:
            await RisingEdge(dut.clk)

        # read outputs
        dut_val = int(dut.delta_next.value.signed_integer)
        dut_idx = int(dut.psi_index.value)

        # compute expected
        ref_val, ref_i = viterbi_step_ref(delta_prev, logA_col, logB_j)

        # allow a small tolerance if you’re using fixed-point scaling
        assert dut_idx == ref_i, f"Argmax mismatch: got {dut_idx}, expected {ref_i}"
        assert abs(dut_val - ref_val) <= 1, f"Value mismatch: got {dut_val}, expected {ref_val}"

        # small delay before next trial
        await Timer(1, units="ns")


