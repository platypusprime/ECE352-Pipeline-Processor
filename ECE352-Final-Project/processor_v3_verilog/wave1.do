onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /multicycle_tb/reset
add wave -noupdate /multicycle_tb/clock
add wave -noupdate -radix hexadecimal /multicycle_tb/DUT/PC/q
add wave -noupdate -radix decimal /multicycle_tb/DUT/Control/cycles
add wave -noupdate -divider Registers
add wave -noupdate -radix hexadecimal /multicycle_tb/DUT/RF_block/k0
add wave -noupdate -radix hexadecimal /multicycle_tb/DUT/RF_block/k1
add wave -noupdate -radix hexadecimal /multicycle_tb/DUT/RF_block/k2
add wave -noupdate -radix hexadecimal /multicycle_tb/DUT/RF_block/k3
add wave -noupdate -divider Control
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2228642 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 227
configure wave -valuecolwidth 57
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1000
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3150 ns}
