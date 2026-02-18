# Build script for Cora Z7-07S Blinky Project

# Disable WebTalk to avoid USB enumeration crashes in containers
config_webtalk -user off

# Source configuration file
set script_dir [file dirname [file normalize [info script]]]
source [file join $script_dir "config.tcl"]

# Check the supported part
set parts_007 [get_parts $PART]
if {[llength $parts_007] == 0} {
    puts "Error: No supported part found for Cora Z7-07S. Please check your Vivado installation."
    exit 1
}

# Use variables from config.tcl
set project_name $PROJECT_NAME
set top_module $TOP_MODULE
set project_dir $PROJECT_DIR
set part $PART

# Create project
create_project -force $project_name $project_dir -part $part

# Add source files
add_files ../../src/hdl/blinky.v

# Add constraint files
add_files -fileset constrs_1 $XDC_FILE

# Set top module
set_property top $top_module [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Launch Synthesis
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Launch Implementation
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Generate Bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Copy the generated bitstream to the output directory
set bitstream_path [file join $project_dir ${project_name}.runs impl_1 ${top_module}.bit]
file mkdir $OUTPUT_DIR
file copy -force $bitstream_path [file join $OUTPUT_DIR ${project_name}.bit]

puts "Bitstream generated successfully!"
