onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -max 32767.0 -radix decimal /mf_tb/mf0/i_in
add wave -noupdate -format Analog-Step -height 84 -max 1042.0 -min -137.0 -radix decimal /mf_tb/mf0/i_out
add wave -noupdate -max 32767.0 -radix decimal /mf_tb/mf0/q_in
add wave -noupdate -format Analog-Step -height 84 -max 1042.0 -min -137.0 -radix decimal /mf_tb/mf0/q_out
add wave -noupdate -divider <NULL>
add wave -noupdate -max 32767.0 -radix decimal /mf_tb/mf/i_in
add wave -noupdate -format Analog-Step -height 84 -max 16672.999999999996 -min -2182.0 -radix decimal /mf_tb/mf/i_out
add wave -noupdate -max 32767.0 -radix decimal /mf_tb/mf/q_in
add wave -noupdate -format Analog-Step -height 84 -max 16672.999999999996 -min -2182.0 -radix decimal /mf_tb/mf/q_out
add wave -noupdate -divider <NULL>
add wave -noupdate -max 32767.0 -radix decimal /mf_tb/msk_mf0_inst/din
add wave -noupdate -format Analog-Step -height 84 -max 32767.0 -radix decimal /mf_tb/msk_mf0_inst/dout
add wave -noupdate -divider <NULL>
add wave -noupdate -max 32767.0 -radix decimal /mf_tb/msk_mf_inst/din
add wave -noupdate -format Analog-Step -height 84 -max 29486.0 -radix decimal /mf_tb/msk_mf_inst/dout
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {507959 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 213
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 3
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
WaveRestoreZoom {0 ps} {5043539 ps}
