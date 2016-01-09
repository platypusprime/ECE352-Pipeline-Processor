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
add wave -noupdate -divider DataMem
add wave -noupdate -label DataMem/address -radix hexadecimal /multicycle_tb/DUT/DataMem/address
add wave -noupdate -label DataMem/data -radix hexadecimal /multicycle_tb/DUT/DataMem/data
add wave -noupdate -label DataMem/q -radix hexadecimal /multicycle_tb/DUT/DataMem/q
add wave -noupdate -label DataMem/address_pc -radix hexadecimal -childformat {{{/multicycle_tb/DUT/DataMem/address_pc[7]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[6]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[5]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[4]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[3]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[2]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[1]} -radix hexadecimal} {{/multicycle_tb/DUT/DataMem/address_pc[0]} -radix hexadecimal}} -subitemconfig {{/multicycle_tb/DUT/DataMem/address_pc[7]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[6]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[5]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[4]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[3]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[2]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[1]} {-radix hexadecimal} {/multicycle_tb/DUT/DataMem/address_pc[0]} {-radix hexadecimal}} /multicycle_tb/DUT/DataMem/address_pc
add wave -noupdate -label DataMem/q_pc -radix hexadecimal /multicycle_tb/DUT/DataMem/q_pc
add wave -noupdate -divider Control
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {2211258 ps} 0}
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
