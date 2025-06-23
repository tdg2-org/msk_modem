onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /msk_tb/clk
add wave -noupdate /msk_tb/data_in
add wave -noupdate /msk_tb/demod_data
add wave -noupdate -expand -group mod /msk_tb/msk_modulator_inst/PHASE_STEP_HIGH
add wave -noupdate -expand -group mod /msk_tb/msk_modulator_inst/PHASE_STEP_LOW
add wave -noupdate -expand -group mod -format Analog-Step -height 84 -max 2147480000.0000002 -min -2134060000.0 -radix decimal /msk_tb/msk_modulator_inst/phase_acc
add wave -noupdate -expand -group mod -format Analog-Step -height 100 -max 30000.0 -min -30000.0 -radix decimal /msk_tb/i_out
add wave -noupdate -expand -group mod -format Analog-Step -height 100 -max 30000.0 -min -30000.0 -radix decimal /msk_tb/q_out
add wave -noupdate -radix unsigned /msk_tb/msk_demodulator_inst/SAMPLES_PER_SYM
add wave -noupdate -radix unsigned /msk_tb/msk_demodulator_inst/SAMPLE_MIDPOINT
add wave -noupdate -radix unsigned /msk_tb/msk_demodulator_inst/midpoint
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {8259 ns} 0} {{Cursor 3} {14290 ns} 0}
quietly wave cursor active 2
configure wave -namecolwidth 274
configure wave -valuecolwidth 190
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ns} {42 us}
