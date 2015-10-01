onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /solution/clock
add wave -noupdate /solution/reset
add wave -noupdate -radix unsigned /solution/addr
add wave -noupdate /solution/enable
add wave -noupdate /solution/requestComplete
add wave -noupdate /solution/dataOut
add wave -noupdate /solution/TOTALdelay
add wave -noupdate /solution/L1delay
add wave -noupdate /solution/myCache/rom/BLOCK_SIZE_L1
add wave -noupdate /solution/myCache/rom/NUM_CACHE_INDEX_L1
add wave -noupdate /solution/myCache/rom/NUM_ASSO_INDEX_L1
add wave -noupdate /solution/myCache/rom/CACHE_DELAY_L1
add wave -noupdate /solution/myCache/rom/BLOCK_SIZE_L2
add wave -noupdate /solution/myCache/rom/NUM_CACHE_INDEX_L2
add wave -noupdate /solution/myCache/rom/NUM_ASSO_INDEX_L2
add wave -noupdate /solution/myCache/rom/CACHE_DELAY_L2
add wave -noupdate /solution/myCache/rom/BLOCK_SIZE_L3
add wave -noupdate /solution/myCache/rom/NUM_CACHE_INDEX_L3
add wave -noupdate /solution/myCache/rom/NUM_ASSO_INDEX_L3
add wave -noupdate /solution/myCache/rom/CACHE_DELAY_L3
add wave -noupdate /solution/myCache/rom/CACHE_DELAY_MEM
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
