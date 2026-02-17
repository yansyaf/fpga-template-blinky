# Program script for Cora Z7-07S

# Source configuration file
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir "config.tcl"]

# Connect to local hardware server
open_hw_manager
connect_hw_server
open_hw_target

# Find the FPGA device (not ARM DAP)
set devices [get_hw_devices]
puts "Available devices: $devices"

# Look for the xc7z device (FPGA), not arm_dap
set fpga_device ""
foreach dev $devices {
    if {[string match $PART $dev]} {
        set fpga_device $dev
        break
    }
}

if {$fpga_device == ""} {
    puts "Error: No ${PART} FPGA device found in JTAG chain"
    puts "Available devices: $devices"
    close_hw_manager
    exit 1
}

puts "Using FPGA device: $fpga_device"
current_hw_device $fpga_device
refresh_hw_device -update_hw_probes false $fpga_device

# Find the bitstream - use absolute path
set project_root [file normalize [file join $script_dir "../.."]]
set bitstream_path [file join $project_root $OUTPUT_DIR "${PROJECT_NAME}.bit"]

puts "Looking for bitstream at: $bitstream_path"

if {![file exists $bitstream_path]} {
    puts "Error: Bitstream not found at $bitstream_path"
    puts "Please build the project first using: ./run.sh --build"
    close_hw_manager
    exit 1
}

# Program the device
puts "Programming device with: $bitstream_path"
set_property PROGRAM.FILE $bitstream_path $fpga_device
program_hw_devices $fpga_device
refresh_hw_device $fpga_device

puts "Device programmed successfully!"
close_hw_manager
