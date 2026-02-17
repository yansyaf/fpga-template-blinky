# Cocotb Makefile for Blinky Testbench
# Supports Icarus Verilog simulation

# Paths
SIM_DIR = $(shell pwd)
HDL_DIR = ../../src/hdl
ROOT_DIR = ../..

# DUT settings
TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(HDL_DIR)/blinky.v

# Cocotb test settings (using new variable names)
COCOTB_TOPLEVEL = blinky
COCOTB_TEST_MODULES = test_blinky

# Legacy variable support (for older cocotb)
TOPLEVEL = $(COCOTB_TOPLEVEL)
MODULE = $(COCOTB_TEST_MODULES)

# Simulator settings
SIM ?= icarus

# Icarus Verilog specific settings
ifeq ($(SIM),icarus)
    # Waveform generation (VCD format)
	WAVES ?= 0
    COCOTB_ENABLE_PROFILING ?= 0
endif

# Coverage settings
COVERAGE ?= 1

# Python test settings
export PYTHONPATH := $(SIM_DIR):$(PYTHONPATH)

# Cocotb settings
COCOTB_HDL_TIMEUNIT = 1ns
COCOTB_HDL_TIMEPRECISION = 1ps

# Logging
COCOTB_LOG_LEVEL ?= INFO
COCOTB_RESOLVE_X ?= ZEROS

# Include cocotb makefiles
include $(shell cocotb-config --makefiles)/Makefile.sim

# Custom targets
.PHONY: clean_all coverage_report waves

clean_all: clean
	@echo "Cleaning all generated files..."
	rm -rf __pycache__ .pytest_cache
	rm -f *.vcd *.fst *.wlf *.vstf *.ucdb
	rm -rf work transcript vsim.wlf sim_build
	rm -f *.log

coverage_report:
	@echo "Coverage report not available for Icarus Verilog"
	@echo "Use ModelSim or other commercial simulator for coverage analysis"

waves:
	@echo "Opening waveform viewer..."
	@if [ -f dump.vcd ]; then \
		gtkwave dump.vcd; \
	elif [ -f *.vcd ]; then \
		gtkwave *.vcd; \
	else \
		echo "No VCD waveform file found. Run simulation first."; \
	fi

help:
	@echo "Blinky Testbench Makefile"
	@echo "========================="
	@echo "Targets:"
	@echo "  make              - Run simulation with default settings"
	@echo "  make SIM=icarus   - Run with Icarus Verilog (default)"
	@echo "  make clean        - Clean build artifacts" 
	@echo "  make clean_all    - Clean all generated files"
	@echo "  make coverage_report - Generate coverage report (ModelSim only)"
	@echo "  make waves        - Open waveform viewer (gtkwave)"
	@echo ""
	@echo "Environment Variables:"
	@echo "  SIM=<simulator>   - Simulator to use (default: icarus)"
	@echo "  WAVES=1           - Enable waveform generation (default: 0)"
	@echo "  COCOTB_LOG_LEVEL  - Log level (default: INFO)"
