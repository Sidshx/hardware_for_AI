#Makefile for Cocotb Viterbi simulation

# Default simulator (can be changed to modelsim, xcelium, etc.)
SIM ?= icarus

# Verilog source files
VERILOG_SOURCES = viterbi_top.v

# Top level module
TOPLEVEL = viterbi_top

# Python test module
MODULE = test_viterbi_cocotb

# Include cocotb's make rules to take care of the build
include $(shell cocotb-config --makefiles)/Makefile.sim

# Optional: Add waveform generation for debugging
ifeq ($(SIM),icarus)
    COMPILE_ARGS += -DICARUS
    PLUSARGS += +define+COCOTB_SIM=1
endif


