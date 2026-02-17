# ModelSim TCL Script for Blinky Simulation
# This script sets up waveforms, coverage, and simulation parameters

# Set simulation time format
configure wave -timelineunits ns

# Add signals to waveform
if {[batch_mode] == 0} {
    # GUI mode - add waves
    add wave -divider "Inputs"
    add wave -format Logic /blinky/clk
    add wave -format Logic /blinky/rst
    
    add wave -divider "Outputs"  
    add wave -format Logic /blinky/led
    
    add wave -divider "Internal"
    add wave -format Literal -radix unsigned /blinky/counter
    add wave -format Literal -radix hexadecimal /blinky/counter
    
    # Configure wave window
    wave zoom full
}

# Coverage settings - save on exit
# Note: Coverage is enabled via +cover compile flag in Makefile
coverage save -onexit blinky.ucdb
coverage attr -name TESTNAME -value blinky_uvm_test

# Set up assertions if any
# assertion fail -action continue

# Simulation control
onbreak {resume}
onerror {quit -code 1}

# Log all signals for debugging
# log -r /*

# Run simulation
# Note: Cocotb takes control, so we don't specify run time here
# The test will finish when complete

puts "ModelSim TCL script loaded successfully"
puts "Simulation configuration:"
puts "  - Waveform capture: Enabled"
puts "  - Coverage collection: Enabled"
puts "  - DUT: blinky"
puts ""
puts "Starting simulation..."
