onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /userIO_testbench/clock
add wave -noupdate /userIO_testbench/reset
add wave -noupdate /userIO_testbench/write
add wave -noupdate /userIO_testbench/addr
add wave -noupdate /userIO_testbench/enable
add wave -noupdate /userIO_testbench/cacheSystem/L1/data
add wave -noupdate /userIO_testbench/cacheSystem/L1/tag
add wave -noupdate /userIO_testbench/cacheSystem/L1/tags
add wave -noupdate /userIO_testbench/cacheSystem/L1/wordSelect
add wave -noupdate /userIO_testbench/cacheSystem/L1/enableOut
add wave -noupdate /userIO_testbench/cacheSystem/L2/data
add wave -noupdate -radix decimal /userIO_testbench/cacheSystem/L1/addrIn
add wave -noupdate /userIO_testbench/cacheSystem/L1/enableOut
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {15027 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 447
configure wave -valuecolwidth 153
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
configure wave -timelineunits ns
update
WaveRestoreZoom {15275 ps} {16581 ps}
