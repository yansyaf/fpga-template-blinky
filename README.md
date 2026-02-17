# FPGA Blinky Project for Cora Z7-07S

This project implements a simple LED blinky on the Digilent Cora Z7-07S FPGA board.

## Prerequisites

- Xilinx Vivado Design Suite with Zynq-7000
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

### Connecting the Cora Z7-07S Board

1. **USB Connection:**
   - Connect the board using the **micro-USB port labeled "PROG UART"** (the port closest to the edge)
   - This single USB connection provides both JTAG programming and UART communication

2. **Power the Board:**
   - Use the onboard power switch to turn on the board, OR
   - Connect a 5V power supply to the barrel jack labeled "POWER"
   - The power LED should illuminate when powered

3. **Verify USB Connection:**
   ```bash
   lsusb | grep -i digilent
   ```
   You should see a Digilent device (e.g., "Digilent Adept USB Device")

4. **Install Digilent Cable Drivers** (first time only):
   ```bash
   cd /opt/Xilinx/Vivado/*/data/xicom/cable_drivers/lin64/install_script/install_drivers
   sudo ./install_drivers
   ```
   Note: Replace `*` with your Vivado version (e.g., `2023.2`)

### Program Device
To program the Cora Z7-07S board (after completing Hardware Setup above):
1. Ensure your board is connected and powered on.
2. Run:
```bash
./run.sh --program
```
3. Observe **LED 0** (Red) blinking.

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
