onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /msk_tb_mdl_RX/gardner_ted_inst/clk
add wave -noupdate -group ted -format Analog-Step -height 50 -max 18000.0 -min -18000.0 -radix decimal /msk_tb_mdl_RX/gardner_ted_inst/i_in
add wave -noupdate -group ted -format Analog-Step -height 50 -max 18000.0 -min -18000.0 -radix decimal /msk_tb_mdl_RX/gardner_ted_inst/q_in
add wave -noupdate -group ted /msk_tb_mdl_RX/gardner_ted_inst/iq_val
add wave -noupdate -group ted /msk_tb_mdl_RX/gardner_ted_inst/sym_valid_i
add wave -noupdate -group ted -color Salmon -format Analog-Step -height 40 -max 200.0 -min -200.0 -radix decimal /msk_tb_mdl_RX/gardner_ted_inst/e_out_o
add wave -noupdate -group ted /msk_tb_mdl_RX/gardner_ted_inst/e_valid_o
add wave -noupdate -group loop /msk_tb_mdl_RX/pi_loop_filter_inst/e_in_i
add wave -noupdate -group loop /msk_tb_mdl_RX/pi_loop_filter_inst/e_valid_i
add wave -noupdate -group loop -color Salmon -format Analog-Step -height 40 -max 5.0 -min -5.0 -radix decimal /msk_tb_mdl_RX/pi_loop_filter_inst/ctrl_o
add wave -noupdate -group loop /msk_tb_mdl_RX/pi_loop_filter_inst/ctrl_val_o
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/ctrl_i
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/ctrl_val_i
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/mu_o
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/phase_int_o
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/sym_valid_o
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/dec
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/inc
add wave -noupdate -group phase /msk_tb_mdl_RX/phase_accum_inst/nom
add wave -noupdate -group poly -radix decimal /msk_tb_mdl_RX/polyphase_interp_NEW/i_raw_i
add wave -noupdate -group poly -radix decimal /msk_tb_mdl_RX/polyphase_interp_NEW/q_raw_i
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/iq_raw_val_i
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/mu_i
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/phase_int_i
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/sym_valid_i
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/i_sym_o
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/q_sym_o
add wave -noupdate -group poly /msk_tb_mdl_RX/polyphase_interp_NEW/sym_valid_o
add wave -noupdate -group coarse_cfo -radix decimal /msk_tb_mdl_RX/coarse_cfo_mdl_inst/freq_word
add wave -noupdate -group coarse_cfo /msk_tb_mdl_RX/coarse_cfo_mdl_inst/done
add wave -noupdate -expand -group phase_det /msk_tb_mdl_RX/phase_detector_mdl_inst/err_valid
add wave -noupdate -expand -group phase_det -format Analog-Step -height 84 -max 1185504.0000000002 -min -1183874.0 -radix decimal /msk_tb_mdl_RX/phase_detector_mdl_inst/phase_err
add wave -noupdate -expand -group loop_cfo /msk_tb_mdl_RX/loop_filter_cfo_mdl_inst/freq_valid_o
add wave -noupdate -expand -group loop_cfo -radix decimal /msk_tb_mdl_RX/loop_filter_cfo_mdl_inst/freq_word_o
add wave -noupdate -expand -group dds -height 19 -max 32767.0 -min -32767.0 -radix decimal /msk_tb_mdl_RX/nco_dds_mdl_inst/cos_out
add wave -noupdate -expand -group dds -radix decimal /msk_tb_mdl_RX/nco_dds_mdl_inst/phase_word_o
add wave -noupdate -expand -group dds -height 19 -max 32767.0 -min -32767.0 -radix decimal /msk_tb_mdl_RX/nco_dds_mdl_inst/sin_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {180347500 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 209
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
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {953008875 ps}
