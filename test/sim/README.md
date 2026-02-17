# Blinky PyUVM Testbench

This directory contains a PyUVM-based testbench for the blinky module with 100% functional coverage target.

## Features

- **PyUVM Framework**: Industry-standard UVM methodology in Python
- **100% Coverage Target**: Tests all functional aspects of the blinky module
  - Reset functionality
  - Counter increment
  - LED output toggle
  - Counter overflow
- **Icarus Verilog Integration**: Open-source Verilog simulator
- **Waveform Generation**: Automatic VCD waveform capture for debugging

## Prerequisites

### Software Requirements
- Python 3.7+
- python3-venv (for virtual environment support)
- Icarus Verilog (open-source simulator)
- GTKWave (for waveform viewing)
- cocotb (auto-installed in venv)
- pyuvm (auto-installed in venv)

Install system requirements:
```bash
# On Debian/Ubuntu
sudo apt install python3 python3-venv iverilog gtkwave

# On macOS (with Homebrew)
brew install icarus-verilog gtkwave

# Verify
python3 --version
iverilog -v
```

### Installation

The simulation scripts automatically create and manage a Python virtual environment to avoid conflicts with system packages.

**Automatic Setup** (recommended):
```bash
./run.sh --sim  # From project root
```
or
```bash
./run_test.sh   # From test/sim directory
```

**Manual Setup**:
If you prefer to manually setup the environment:
```bash
# Create virtual environment
python3 -m venv venv

# Activate it
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

## Running Simulations

### Quick Start

From the project root:
```bash
./run.sh --sim
```

### Manual Execution

From the `test/sim` directory:

```bash
# Run simulation
make

# Run with specific simulator
make SIM=icarus

# View waveforms after simulation
make waves

# Clean all files
make clean_all
```

## Test Structure

### Files

- `test_blinky.py`: Main PyUVM testbench
  - `BlinkyItem`: Transaction item
  - `BlinkyDriver`: Drives reset signal
  - `BlinkyMonitor`: Observes DUT outputs
  - `BlinkyScoreboard`: Checks correctness and tracks coverage
  - `BlinkyAgent`: Combines driver, monitor, sequencer
  - `BlinkyEnv`: Top-level environment
  - `BlinkyTest`: Test sequences

- `Makefile`: Cocotb makefile for simulation control
- `requirements.txt`: Python dependencies

### Coverage Items

The testbench tracks and reports the following coverage:

1. **Reset Coverage**: Verifies reset functionality
2. **LED Toggle**: Confirms LED changes state
3. **Counter Overflow**: Tests 27-bit counter wrap-around
4. **LED States**: Verifies both high and low LED states

## Simulation Output

After running, you'll find:

- `dump.vcd`: VCD waveform file (view with `make waves` or `gtkwave dump.vcd`)
- `results.xml`: Test results in JUnit format
- `sim_build/`: Icarus Verilog build directory

## Interpreting Results

### Successful Test Output

```
SCOREBOARD REPORT
==============================================================
Checks Passed: XXXXX
Checks Failed: 0

COVERAGE REPORT:
  Reset tested: ✓
  LED toggle observed: ✓
  Counter overflow: ✓
  LED states seen: {0, 1}

Functional Coverage: 100.0%
==============================================================
TEST PASSED: All checks passed!
```

## Debugging

### View Waveforms

```bash
make waves
```

This opens GTKWave with the VCD waveform file. You can also directly run:
```bash
gtkwave dump.vcd
```

### Increase Logging

Set log level to DEBUG:
```bash
make COCOTB_LOG_LEVEL=DEBUG
```

## Customization

### Adjust Simulation Time

Edit `test_blinky.py`, modify `RunSequence.body()`:
```python
num_cycles = 2**27 + 1000  # Adjust as needed
```

### Add More Tests

Add new sequence classes and execute in `BlinkyTest.run_phase()`:
```python
async def run_phase(self):
    self.raise_objection()
    
    # Your custom sequence
    custom_seq = CustomSequence("custom_seq")
    await custom_seq.start(seqr)
    
    self.drop_objection()
```

## Troubleshooting

### ModuleNotFoundError: No module named 'cocotb'

The scripts automatically handle dependencies using a virtual environment. If you see this error:

1. Delete the venv directory: `rm -rf venv`
2. Run again: `./run.sh --sim`

Or manually install in venv:
```bash
source venv/bin/activate
pip install -r requirements.txt
```

### externally-managed-environment error

This error occurs when trying to install packages system-wide on modern Linux distributions. The scripts now automatically use a virtual environment to avoid this. If you still see this error, ensure you're running the latest version of the scripts.

### iverilog: command not found

Install Icarus Verilog:
```bash
# Debian/Ubuntu
sudo apt install iverilog

# macOS
brew install icarus-verilog
```

### Simulation hangs

Check that clock is running and sequences complete properly. Add timeout in test:
```python
await Timer(1000000, units='ns')  # 1ms timeout
```

## Performance

- Full coverage test runs ~2^27 cycles for counter overflow
- Simulation time depends on Icarus Verilog performance
- Typical run time: 5-30 minutes (depending on machine)

For faster testing during development, reduce `num_cycles` in `RunSequence`.
