onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /associative_cache_testbench/clk
add wave -noupdate -radix unsigned /associative_cache_testbench/addr_in
add wave -noupdate -radix unsigned /associative_cache_testbench/data_out
add wave -noupdate -radix unsigned /associative_cache_testbench/L1/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/L2/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/memory/counter
add wave -noupdate -radix unsigned -childformat {{{/associative_cache_testbench/L1/data[3]} -radix unsigned} {{/associative_cache_testbench/L1/data[2]} -radix unsigned} {{/associative_cache_testbench/L1/data[1]} -radix unsigned} {{/associative_cache_testbench/L1/data[0]} -radix unsigned}} -expand -subitemconfig {{/associative_cache_testbench/L1/data[3]} {-height 15 -radix unsigned} {/associative_cache_testbench/L1/data[2]} {-height 15 -radix unsigned} {/associative_cache_testbench/L1/data[1]} {-height 15 -radix unsigned} {/associative_cache_testbench/L1/data[0]} {-height 15 -radix unsigned}} /associative_cache_testbench/L1/data
add wave -noupdate -radix unsigned /associative_cache_testbench/L2/data
add wave -noupdate /associative_cache_testbench/L1/LRUoutput
add wave -noupdate /associative_cache_testbench/L1/LRU/select
add wave -noupdate /associative_cache_testbench/L1/LRU/index
add wave -noupdate /associative_cache_testbench/L1/LRU/asso_index
add wave -noupdate /associative_cache_testbench/L1/LRU/write_trigger
add wave -noupdate /associative_cache_testbench/L1/LRU/read_trigger
add wave -noupdate /associative_cache_testbench/L1/LRU/mem
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
WaveRestoreZoom {0 ps} {3543 ps}
