# FPGA Blinky Template

This repository is a reusable FPGA blinky template with Vivado build/program scripts, cocotb simulation, and CI/CD integration.

## Prerequisites

- Xilinx Vivado Design Suite (version compatible with your target FPGA)
- (Optional) Icarus Verilog for simulation
- (Optional) Python 3.7+ with python3-venv for testbench

## Directory Structure

```
.
├── src/
│   ├── hdl/              # Verilog/VHDL source files
│   └── sw/               # Software source files (if any)
├── fpga/
│   └── xilinx/           # Xilinx-specific files
│       ├── build.tcl     # Build script for Vivado
│       ├── program.tcl   # Programming script
│       └── *.xdc         # Constraint files
├── build/                # Generated build files (created by build script)
├── output/               # Final bitstream output
├── test/                 # Test files
│   ├── sim/              # Simulation tests
│   ├── cosim/            # Co-simulation tests
│   └── hil/              # Hardware-in-loop tests
├── doc/                  # Documentation
├── model/                # Model files
└── run.sh                # Build/program helper script
```

## Building and Running

This project includes a helper script `run.sh` to automate building and programming.

### Build Project
To build the Vivado project and generate the bitstream:
```bash
./run.sh --build
```
The project and bitstream will be created in `output` directory.

## Hardware Setup

1. Connect your FPGA board to your host machine (typically USB/JTAG).
2. Power on the board.
3. Ensure cable drivers and board files are installed for your platform/vendor.
4. Verify your board is visible to Vivado Hardware Manager.

### Program Device
To program your board (after completing Hardware Setup above):
1. Ensure your board is connected and powered on.
2. Run:
```bash
./run.sh --program
```
3. Observe the configured LED output blinking.

### Example: Cora Z7-07S

If you use Digilent Cora Z7-07S:

1. Connect the board using the micro-USB port labeled `PROG UART`.
2. Power using the onboard switch or a 5V barrel supply.
3. Verify connection:
   ```bash
   lsusb | grep -i digilent
   ```
4. Install Digilent cable drivers (first time only):
   ```bash
   cd /opt/Xilinx/Vivado/*/data/xicom/cable_drivers/lin64/install_script/install_drivers
   sudo ./install_drivers
   ```
5. Program:
   ```bash
   ./run.sh --program
   ```
6. Observe LED0 blinking.

### Run Simulation
To run the PyUVM testbench with Icarus Verilog:
```bash
./run.sh --sim
```

This will:
- Automatically create and use a Python virtual environment
- Install required dependencies (cocotb, pyuvm) in the venv
- Run the PyUVM testbench targeting 100% functional coverage
- Run in quick mode by default for fast CI/local checks

Note: The first run will take longer as it sets up the virtual environment.

To generate waveforms explicitly:
```bash
cd test/sim
make SIM=icarus WAVES=1
```

Note: Icarus Verilog flow here does not generate HTML code coverage reports.

See [test/sim/README.md](test/sim/README.md) for detailed simulation documentation.

## CI/CD

GitHub Actions workflow is defined in [.github/workflows/ci.yml](.github/workflows/ci.yml).

- **simulation** job runs first on `ubuntu-latest` using Icarus Verilog (`./run.sh --sim`)
- **build-bitstream** job runs only after simulation passes (`needs: simulation`)
- Bitstream is built on self-hosted runner labels: `self-hosted`, `linux`, `xilinx`
- Generated `.bit` file from `output/` is uploaded as artifact `blinky_bitstream`

### Clean Build Files
To clean all build and simulation artifacts:
```bash
./run.sh --clean
```
