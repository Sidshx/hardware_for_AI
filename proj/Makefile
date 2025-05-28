
# Tell cocotb we’re using Verilog
TOPLEVEL_LANG = verilog

# List all your Verilog source files
VERILOG_SOURCES = \
    $(PWD)/viterbi_chain.v \
    $(PWD)/viterbi_pe.v

# The name of the top-level module in viterbi_chain.v
TOPLEVEL = viterbi_chain

# Your cocotb testbench module
MODULE = tests.test_viterbi_systolic

# Choose simulator (icarus or verilator)
SIM = icarus

# Make sure Python finds your DUT and tests/
export PYTHONPATH := $(PWD):$(PYTHONPATH)

# Include the cocotb-provided build rules
include $(shell cocotb-config --makefiles)/Makefile.sim
