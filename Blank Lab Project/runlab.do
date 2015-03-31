# Create work library
vlib work

# Compile Verilog
#     All Verilog files that are part of this design should have
#     their own "vlog" line below.
vlog "./mux2_1.sv"
vlog "./mux4_1.sv"
vlog "./mux16_1.sv"
vlog "./mux32_1.sv"
vlog "./mux32_32_32.sv"
vlog "./D_FF.sv"
vlog "./register.sv"
vlog "./decoder1.sv"
vlog "./decoder2.sv"
vlog "./decoder3.sv"
vlog "./decoder5.sv"
vlog "./regfile.sv"
vlog "./regstim.sv"
vlog "./fullAdder.sv"
vlog "./adder32.sv"
vlog "./xor32.sv"
vlog "./setZeroFlag.sv"
vlog "./alu.sv"

# Call vsim to invoke simulator
#     Make sure the last item on the line is the name of the
#     testbench module you want to execute.
vsim -voptargs="+acc" -t 1ps -lib work setZeroFlag_testbench

# Source the wave do file
#     This should be the file that sets up the signal window for
#     the module you are testing.
do setZeroFlag_wave.do

# Set the window types
view wave
view structure
view signals

# Run the simulation
run -all

# End
