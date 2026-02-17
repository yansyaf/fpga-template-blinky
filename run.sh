#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 [command]"
    echo "Commands:"
    echo "  --build    Build the FPGA bitstream using Vivado"
    echo "  --program  Program the FPGA device"
    echo "  --sim      Run PyUVM simulation with Icarus Verilog"
    echo "  --clean    Clean build and simulation files"
    exit 1
}

# Check if an argument is provided
if [ $# -eq 0 ]; then
    usage
fi

# Get the directory of the script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VIVADO_DIR="$SCRIPT_DIR/fpga/xilinx"
SIM_DIR="$SCRIPT_DIR/test/sim"

# Execute command based on argument
case "$1" in
    --build)
        echo "Starting Vivado Build..."
        cd "$VIVADO_DIR"
        vivado -mode batch -source build.tcl
        ;;
    --program)
        echo "Programming FPGA..."
        cd "$VIVADO_DIR"
        vivado -mode batch -source program.tcl
        ;;
    --sim)
        echo "Running PyUVM Simulation with Icarus Verilog..."
        cd "$SIM_DIR"
        
        # Setup Python virtual environment
        VENV_DIR="$SIM_DIR/venv"
        if [ ! -d "$VENV_DIR" ]; then
            echo "Creating Python virtual environment..."
            python3 -m venv "$VENV_DIR"
        fi
        
        # Activate virtual environment
        source "$VENV_DIR/bin/activate"
        
        # Check if Python dependencies are installed
        if ! python3 -c "import cocotb" 2>/dev/null; then
            echo "Installing Python dependencies in venv..."
            pip install --upgrade pip
            pip install -r requirements.txt
        fi
        
        # Run simulation
        make SIM=icarus
        SIM_RESULT=$?
        
        # Deactivate venv
        deactivate
        
        # Check result
        if [ $SIM_RESULT -eq 0 ]; then
            echo ""
            echo "Simulation completed successfully!"
            echo "View waveforms: make waves"
        else
            echo "Simulation failed!"
            exit 1
        fi
        ;;
    --clean)
        echo "Cleaning build and simulation files..."
        rm -rf "$SCRIPT_DIR/build"
        rm -rf "$SCRIPT_DIR/output"
        rm -rf "$SCRIPT_DIR/vivado.jou"
        rm -rf "$SCRIPT_DIR/vivado.log"
        rm -rf "$SCRIPT_DIR/fpga/xilinx/"*.jou
        rm -rf "$SCRIPT_DIR/fpga/xilinx/"*.log
        rm -rf "$SCRIPT_DIR/fpga/xilinx/.Xil"
        rm -rf "$SCRIPT_DIR/test/sim/__pycache__"
        rm -rf "$SCRIPT_DIR/test/sim/venv"
        rm -rf "$SCRIPT_DIR/test/sim/sim_build"
        rm -rf "$SCRIPT_DIR/test/sim/transcript"
        rm -rf "$SCRIPT_DIR/test/sim/"*.ini
        rm -rf "$SCRIPT_DIR/test/sim/"*.ucdb
        rm -rf "$SCRIPT_DIR/test/sim/results.xml"
        
        # Clean simulation files
        cd "$SIM_DIR"
        make clean_all 2>/dev/null || true
        ;;
    *)
        echo "Invalid argument: $1"
        usage
        ;;
esac
