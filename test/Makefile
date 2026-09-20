# Makefile for Tiny Tapeout cocotb simulation
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# Target your exact custom SystemVerilog file path
VERILOG_SOURCES += $(PWD)/../src/tt_um_neural_processor.v

# TOPLEVEL is the name of the toplevel module in your Verilog file
TOPLEVEL = tt_um_neural_processor

# MODULE is the name of the Python test file
MODULE = test

# Include cocotb's official simulation runner rules
include $(shell cocotb-config --makefiles)/Makefile.sim
