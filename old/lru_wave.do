onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lru_testbench/reset
add wave -noupdate /lru_testbench/write_trigger
add wave -noupdate /lru_testbench/read_trigger
add wave -noupdate /lru_testbench/index
add wave -noupdate /lru_testbench/asso_index
add wave -noupdate /lru_testbench/select
add wave -noupdate -expand /lru_testbench/test/mem
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 108
configure wave -valuecolwidth 144
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {0 ps} {74 ps}
