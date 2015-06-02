onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cache_testbench/clock
add wave -noupdate /cache_testbench/reset
add wave -noupdate /cache_testbench/dataIn
add wave -noupdate -radix unsigned /cache_testbench/addrIn
add wave -noupdate /cache_testbench/writeIn
add wave -noupdate /cache_testbench/enableIn
add wave -noupdate /cache_testbench/requestComplete
add wave -noupdate -radix hexadecimal /cache_testbench/dataOut
add wave -noupdate -radix unsigned /cache_testbench/L1/counter
add wave -noupdate -radix unsigned /cache_testbench/L2/counter
add wave -noupdate -radix unsigned /cache_testbench/memory/counter
add wave -noupdate -radix hexadecimal -childformat {{{/cache_testbench/L1/data[1]} -radix hexadecimal} {{/cache_testbench/L1/data[0]} -radix hexadecimal -childformat {{{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}}} -expand -subitemconfig {{/cache_testbench/L1/data[1]} {-height 15 -radix hexadecimal} {/cache_testbench/L1/data[0]} {-height 15 -radix hexadecimal -childformat {{{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/cache_testbench/L1/data[0][3]} {-radix hexadecimal} {/cache_testbench/L1/data[0][2]} {-radix hexadecimal} {/cache_testbench/L1/data[0][1]} {-radix hexadecimal} {/cache_testbench/L1/data[0][0]} {-radix hexadecimal}} /cache_testbench/L1/data
add wave -noupdate -radix hexadecimal -childformat {{{/cache_testbench/L2/data[3]} -radix hexadecimal} {{/cache_testbench/L2/data[2]} -radix hexadecimal} {{/cache_testbench/L2/data[1]} -radix hexadecimal -childformat {{{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {{/cache_testbench/L2/data[0]} -radix hexadecimal -childformat {{{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}}} -expand -subitemconfig {{/cache_testbench/L2/data[3]} {-radix hexadecimal} {/cache_testbench/L2/data[2]} {-radix hexadecimal} {/cache_testbench/L2/data[1]} {-height 15 -radix hexadecimal -childformat {{{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/cache_testbench/L2/data[1][3]} {-radix hexadecimal} {/cache_testbench/L2/data[1][2]} {-radix hexadecimal} {/cache_testbench/L2/data[1][1]} {-radix hexadecimal} {/cache_testbench/L2/data[1][0]} {-radix hexadecimal} {/cache_testbench/L2/data[0]} {-height 15 -radix hexadecimal -childformat {{{[3]} -radix hexadecimal} {{[2]} -radix hexadecimal} {{[1]} -radix hexadecimal} {{[0]} -radix hexadecimal}}} {/cache_testbench/L2/data[0][3]} {-radix hexadecimal} {/cache_testbench/L2/data[0][2]} {-radix hexadecimal} {/cache_testbench/L2/data[0][1]} {-radix hexadecimal} {/cache_testbench/L2/data[0][0]} {-radix hexadecimal}} /cache_testbench/L2/data
add wave -noupdate /cache_testbench/memory/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {869 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 241
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
WaveRestoreZoom {3850 ps} {7466 ps}
