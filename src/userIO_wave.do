onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /userIO_testbench/clock
add wave -noupdate /userIO_testbench/reset
add wave -noupdate /userIO_testbench/write
add wave -noupdate /userIO_testbench/addr
add wave -noupdate /userIO_testbench/enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16934 ps} 0}
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
WaveRestoreZoom {0 ps} {20736 ps}
