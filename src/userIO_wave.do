onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /userIO_testbench/cacheSystem/#ublk#0#11/numCacheIndices
add wave -noupdate /userIO_testbench/cacheSystem/#ublk#0#11/numAssoIndices
add wave -noupdate /userIO_testbench/cacheSystem/#ublk#0#11/cacheSizes
add wave -noupdate /userIO_testbench/cacheSystem/#ublk#0#11/blockSizes
add wave -noupdate /userIO_testbench/cacheSystem/#ublk#0#11/numCacheLevels
add wave -noupdate /userIO_testbench/cacheSystem/#ublk#0#11/HASH
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13 ps} 0}
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
WaveRestoreZoom {0 ps} {687 ps}
