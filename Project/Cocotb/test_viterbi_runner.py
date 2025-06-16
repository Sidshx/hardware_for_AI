#!/usr/bin/env python3

import pytest
from cocotb_test.simulator import run
import os

def test_viterbi_simple():
    """Run simple Viterbi tests"""
    run(
        verilog_sources=["viterbi_top.v"],  # FIXED: Correct filename
        toplevel="viterbi_top",
        module="test_viterbi_cocotb",
        simulator="icarus",
        waves=True,
    )

def test_viterbi_comprehensive():
    """Run comprehensive Viterbi tests"""
    run(
        verilog_sources=["viterbi_top.v"],  # FIXED: Correct filename
        toplevel="viterbi_top", 
        module="test_viterbi_cocotb",
        simulator="icarus",
        waves=True,
        sim_build="sim_build_comprehensive",
    )

if __name__ == "__main__":
    test_viterbi_simple()

