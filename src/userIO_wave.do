onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /userIO_testbench/cacheSystem/ID
add wave -noupdate /userIO_testbench/cacheSystem/ADDR_LENGTH
add wave -noupdate /userIO_testbench/cacheSystem/NUM_CACHE_INDEX_L1
add wave -noupdate /userIO_testbench/cacheSystem/NUM_ASSO_INDEX_L1
add wave -noupdate /userIO_testbench/cacheSystem/NUM_CACHE_INDEX_L2
add wave -noupdate /userIO_testbench/cacheSystem/NUM_ASSO_INDEX_L2
add wave -noupdate /userIO_testbench/cacheSystem/NUM_CACHE_INDEX_L3
add wave -noupdate /userIO_testbench/cacheSystem/NUM_ASSO_INDEX_L3
add wave -noupdate /userIO_testbench/cacheSystem/CACHE_DELAY_L1
add wave -noupdate /userIO_testbench/cacheSystem/CACHE_DELAY_L2
add wave -noupdate /userIO_testbench/cacheSystem/CACHE_DELAY_L3
add wave -noupdate /userIO_testbench/cacheSystem/CACHE_DELAY_MEM
add wave -noupdate /userIO_testbench/cacheSystem/BLOCK_SIZE_L1
add wave -noupdate /userIO_testbench/cacheSystem/BLOCK_SIZE_L2
add wave -noupdate /userIO_testbench/cacheSystem/BLOCK_SIZE_L3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13 ps} 0}
quietly wave cursor active 0
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
WaveRestoreZoom {0 ps} {687 ps}
