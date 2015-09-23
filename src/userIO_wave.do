onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /userIO/clock
add wave -noupdate /userIO/reset
add wave -noupdate -radix unsigned /userIO/addr
add wave -noupdate /userIO/enable
add wave -noupdate /userIO/requestComplete
add wave -noupdate /userIO/dataOut
add wave -noupdate /userIO/TOTALdelay
add wave -noupdate /userIO/L1delay
add wave -noupdate /userIO/myCache/rom/BLOCK_SIZE_L1
add wave -noupdate /userIO/myCache/rom/NUM_CACHE_INDEX_L1
add wave -noupdate /userIO/myCache/rom/NUM_ASSO_INDEX_L1
add wave -noupdate /userIO/myCache/rom/CACHE_DELAY_L1
add wave -noupdate /userIO/myCache/rom/BLOCK_SIZE_L2
add wave -noupdate /userIO/myCache/rom/NUM_CACHE_INDEX_L2
add wave -noupdate /userIO/myCache/rom/NUM_ASSO_INDEX_L2
add wave -noupdate /userIO/myCache/rom/CACHE_DELAY_L2
add wave -noupdate /userIO/myCache/rom/BLOCK_SIZE_L3
add wave -noupdate /userIO/myCache/rom/NUM_CACHE_INDEX_L3
add wave -noupdate /userIO/myCache/rom/NUM_ASSO_INDEX_L3
add wave -noupdate /userIO/myCache/rom/CACHE_DELAY_L3
add wave -noupdate /userIO/myCache/rom/CACHE_DELAY_MEM
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13439 ps} 0}
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
WaveRestoreZoom {698822 ps} {698962 ps}
