onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /associative_cache_testbench/reset
add wave -noupdate /associative_cache_testbench/enable
add wave -noupdate /associative_cache_testbench/clk
add wave -noupdate -radix unsigned /associative_cache_testbench/addr_in
add wave -noupdate -radix unsigned /associative_cache_testbench/data_out
add wave -noupdate -radix unsigned /associative_cache_testbench/L1/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/L2/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/memory/counter
add wave -noupdate /associative_cache_testbench/L1/miss
add wave -noupdate /associative_cache_testbench/L1/found_data
add wave -noupdate /associative_cache_testbench/L1/state
add wave -noupdate /associative_cache_testbench/L1/next_state
add wave -noupdate /associative_cache_testbench/L1/writeEnable
add wave -noupdate /associative_cache_testbench/L2/writeEnable
add wave -noupdate /associative_cache_testbench/L1/data
add wave -noupdate /associative_cache_testbench/L1/cacheIndex
add wave -noupdate /associative_cache_testbench/L1/miss
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1146 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 300
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {8576 ps}
