#!/bin/bash
# Quick simulation helper script

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "Blinky PyUVM Simulation"
echo "======================="
echo ""

# Setup Python virtual environment
VENV_DIR="./venv"
if [ ! -d "$VENV_DIR" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv "$VENV_DIR"
fi

# Activate virtual environment
echo "Activating virtual environment..."
source "$VENV_DIR/bin/activate"

# Check Python dependencies
echo "Checking Python dependencies..."
if ! python3 -c "import cocotb" 2>/dev/null; then
    echo "Installing dependencies in venv..."
    pip install --upgrade pip
    pip install -r requirements.txt
fi

echo -e "${GREEN}Dependencies OK${NC}"
echo ""

# Run simulation
echo "Running simulation..."
make SIM=icarus

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}Simulation completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  - View waveforms:     make waves"
    echo "  - Clean files:        make clean_all"
else
    echo ""
    echo -e "${RED}Simulation failed!${NC}"
    echo "Check transcript and log files for details"
    deactivate
    exit 1
fi

# Deactivate virtual environment
deactivate
