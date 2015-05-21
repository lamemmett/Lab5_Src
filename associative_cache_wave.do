onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /associative_cache_testbench/reset
add wave -noupdate /associative_cache_testbench/write
add wave -noupdate /associative_cache_testbench/enable
add wave -noupdate /associative_cache_testbench/clk
add wave -noupdate -radix unsigned /associative_cache_testbench/addr_in
add wave -noupdate -radix unsigned /associative_cache_testbench/data_out
add wave -noupdate /associative_cache_testbench/L1/data_out
add wave -noupdate /associative_cache_testbench/L1/data_in
add wave -noupdate /associative_cache_testbench/L2/data_out
add wave -noupdate /associative_cache_testbench/L2/data_in
add wave -noupdate /associative_cache_testbench/memory/data_out
add wave -noupdate /associative_cache_testbench/memory/data_in
add wave -noupdate -radix unsigned /associative_cache_testbench/L1/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/L2/counter
add wave -noupdate -radix unsigned /associative_cache_testbench/memory/counter
add wave -noupdate /associative_cache_testbench/enable
add wave -noupdate /associative_cache_testbench/L1/miss
add wave -noupdate /associative_cache_testbench/L1/enable
add wave -noupdate /associative_cache_testbench/L2/enable
add wave -noupdate /associative_cache_testbench/L2/write
add wave -noupdate /associative_cache_testbench/L2/data_in
add wave -noupdate /associative_cache_testbench/memory/enable
add wave -noupdate -expand /associative_cache_testbench/L1/valid_bits
add wave -noupdate /associative_cache_testbench/L1/dirty_bits
add wave -noupdate -radix unsigned -childformat {{{/associative_cache_testbench/L1/data[3]} -radix unsigned} {{/associative_cache_testbench/L1/data[2]} -radix unsigned} {{/associative_cache_testbench/L1/data[1]} -radix unsigned} {{/associative_cache_testbench/L1/data[0]} -radix unsigned}} -expand -subitemconfig {{/associative_cache_testbench/L1/data[3]} {-height 15 -radix unsigned} {/associative_cache_testbench/L1/data[2]} {-height 15 -radix unsigned} {/associative_cache_testbench/L1/data[1]} {-height 15 -radix unsigned} {/associative_cache_testbench/L1/data[0]} {-height 15 -radix unsigned}} /associative_cache_testbench/L1/data
add wave -noupdate -radix unsigned -childformat {{{/associative_cache_testbench/L2/data[7]} -radix unsigned} {{/associative_cache_testbench/L2/data[6]} -radix unsigned} {{/associative_cache_testbench/L2/data[5]} -radix unsigned} {{/associative_cache_testbench/L2/data[4]} -radix unsigned} {{/associative_cache_testbench/L2/data[3]} -radix unsigned} {{/associative_cache_testbench/L2/data[2]} -radix unsigned} {{/associative_cache_testbench/L2/data[1]} -radix unsigned} {{/associative_cache_testbench/L2/data[0]} -radix unsigned -childformat {{{[3]} -radix unsigned} {{[2]} -radix unsigned} {{[1]} -radix unsigned} {{[0]} -radix unsigned}}}} -expand -subitemconfig {{/associative_cache_testbench/L2/data[7]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[6]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[5]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[4]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[3]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[2]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[1]} {-height 15 -radix unsigned} {/associative_cache_testbench/L2/data[0]} {-height 15 -radix unsigned -childformat {{{[3]} -radix unsigned} {{[2]} -radix unsigned} {{[1]} -radix unsigned} {{[0]} -radix unsigned}}} {/associative_cache_testbench/L2/data[0][3]} {-radix unsigned} {/associative_cache_testbench/L2/data[0][2]} {-radix unsigned} {/associative_cache_testbench/L2/data[0][1]} {-radix unsigned} {/associative_cache_testbench/L2/data[0][0]} {-radix unsigned}} /associative_cache_testbench/L2/data
add wave -noupdate /associative_cache_testbench/L2/dirty_bits
add wave -noupdate /associative_cache_testbench/memory/mem
add wave -noupdate -radix unsigned /associative_cache_testbench/L1/LRUoutput
add wave -noupdate /associative_cache_testbench/L2/LRUoutput
add wave -noupdate /associative_cache_testbench/L1/waitingForLower
add wave -noupdate /associative_cache_testbench/L1/start_counter
add wave -noupdate -expand /associative_cache_testbench/L1/LRU/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {235 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 295
configure wave -valuecolwidth 146
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
WaveRestoreZoom {0 ps} {3760 ps}
