onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /lru_testbench/test/select
add wave -noupdate /lru_testbench/test/index
add wave -noupdate /lru_testbench/test/asso_index
add wave -noupdate /lru_testbench/test/write_trigger
add wave -noupdate /lru_testbench/test/read_trigger
add wave -noupdate /lru_testbench/test/reset
add wave -noupdate -expand /lru_testbench/test/mem
add wave -noupdate /lru_testbench/test/v
add wave -noupdate /lru_testbench/test/reading
add wave -noupdate /lru_testbench/test/writing
add wave -noupdate /lru_testbench/test/full
add wave -noupdate /lru_testbench/test/r
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {44 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {74 ps} {130 ps}
