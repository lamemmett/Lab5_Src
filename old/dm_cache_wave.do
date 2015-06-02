onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dm_cache_testbench/clk
add wave -noupdate -radix unsigned /dm_cache_testbench/addr_in
add wave -noupdate /dm_cache_testbench/enable
add wave -noupdate -radix unsigned /dm_cache_testbench/data_out
add wave -noupdate -radix unsigned /dm_cache_testbench/L1/counter
add wave -noupdate -radix unsigned /dm_cache_testbench/L2/counter
add wave -noupdate -radix unsigned /dm_cache_testbench/memory/counter
add wave -noupdate /dm_cache_testbench/memory/finishDelay
add wave -noupdate -radix unsigned -childformat {{{/dm_cache_testbench/L1/data[3]} -radix unsigned} {{/dm_cache_testbench/L1/data[2]} -radix unsigned} {{/dm_cache_testbench/L1/data[1]} -radix unsigned} {{/dm_cache_testbench/L1/data[0]} -radix unsigned}} -subitemconfig {{/dm_cache_testbench/L1/data[3]} {-height 15 -radix unsigned} {/dm_cache_testbench/L1/data[2]} {-height 15 -radix unsigned} {/dm_cache_testbench/L1/data[1]} {-height 15 -radix unsigned} {/dm_cache_testbench/L1/data[0]} {-height 15 -radix unsigned}} /dm_cache_testbench/L1/data
add wave -noupdate -radix unsigned -childformat {{{/dm_cache_testbench/L2/data[7]} -radix unsigned} {{/dm_cache_testbench/L2/data[6]} -radix unsigned} {{/dm_cache_testbench/L2/data[5]} -radix unsigned} {{/dm_cache_testbench/L2/data[4]} -radix unsigned} {{/dm_cache_testbench/L2/data[3]} -radix unsigned} {{/dm_cache_testbench/L2/data[2]} -radix unsigned} {{/dm_cache_testbench/L2/data[1]} -radix unsigned} {{/dm_cache_testbench/L2/data[0]} -radix unsigned}} -subitemconfig {{/dm_cache_testbench/L2/data[7]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[6]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[5]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[4]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[3]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[2]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[1]} {-height 15 -radix unsigned} {/dm_cache_testbench/L2/data[0]} {-height 15 -radix unsigned}} /dm_cache_testbench/L2/data
add wave -noupdate -radix unsigned /dm_cache_testbench/L1/cacheIndex
add wave -noupdate -radix unsigned /dm_cache_testbench/L2/cacheIndex
add wave -noupdate -radix unsigned /dm_cache_testbench/L2/tag
add wave -noupdate -radix unsigned /dm_cache_testbench/L2/tags
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {355 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 260
configure wave -valuecolwidth 40
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
WaveRestoreZoom {63987 ps} {66103 ps}
