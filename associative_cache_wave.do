onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /associative_cache_testbench/clk
add wave -noupdate -radix unsigned /associative_cache_testbench/addr_in
add wave -noupdate -radix unsigned /associative_cache_testbench/data_out
add wave -noupdate -radix unsigned /associative_cache_testbench/L1/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/L2/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/memory/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/L1/data
add wave -noupdate -radix unsigned /associative_cache_testbench/L2/data
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8554 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 276
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
WaveRestoreZoom {6934 ps} {10477 ps}
