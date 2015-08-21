onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /userIO/clock
add wave -noupdate /userIO/reset
add wave -noupdate /userIO/write
add wave -noupdate -radix unsigned /userIO/addr
add wave -noupdate /userIO/enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {53933 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 325
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
WaveRestoreZoom {35840 ps} {107520 ps}
