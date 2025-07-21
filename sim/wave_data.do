onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group NEW /msk_tb_mdl_RX/shifter_viewer_NEW/data_i
add wave -noupdate -expand -group NEW /msk_tb_mdl_RX/shifter_viewer_NEW/srh0
add wave -noupdate -expand -group NEW /msk_tb_mdl_RX/shifter_viewer_NEW/srh1
add wave -noupdate -expand -group NEW /msk_tb_mdl_RX/shifter_viewer_NEW/srh2
add wave -noupdate -expand -group NEW /msk_tb_mdl_RX/shifter_viewer_NEW/srh3
add wave -noupdate -expand -group NEW -radix binary /msk_tb_mdl_RX/shifter_viewer_NEW/sr32
add wave -noupdate -expand -group NEW -color Salmon /msk_tb_mdl_RX/shifter_viewer_NEW/genblk1/pattern_match
add wave -noupdate -expand -group OVERSAMP /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/data_i
add wave -noupdate -expand -group OVERSAMP /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/srh0
add wave -noupdate -expand -group OVERSAMP /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/srh1
add wave -noupdate -expand -group OVERSAMP /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/srh2
add wave -noupdate -expand -group OVERSAMP /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/srh3
add wave -noupdate -expand -group OVERSAMP -radix binary /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/sr32
add wave -noupdate -expand -group OVERSAMP -color Salmon -subitemconfig {{/msk_tb_mdl_RX/shifter_viewer_OVERSAMP/genblk1/pattern_match[3]} {-color Salmon} {/msk_tb_mdl_RX/shifter_viewer_OVERSAMP/genblk1/pattern_match[2]} {-color Salmon} {/msk_tb_mdl_RX/shifter_viewer_OVERSAMP/genblk1/pattern_match[1]} {-color Salmon} {/msk_tb_mdl_RX/shifter_viewer_OVERSAMP/genblk1/pattern_match[0]} {-color Salmon}} /msk_tb_mdl_RX/shifter_viewer_OVERSAMP/genblk1/pattern_match
add wave -noupdate -expand -group CFO /msk_tb_mdl_RX/shifter_viewer_CFO/data_i
add wave -noupdate -expand -group CFO /msk_tb_mdl_RX/shifter_viewer_CFO/srh0
add wave -noupdate -expand -group CFO /msk_tb_mdl_RX/shifter_viewer_CFO/srh1
add wave -noupdate -expand -group CFO /msk_tb_mdl_RX/shifter_viewer_CFO/srh2
add wave -noupdate -expand -group CFO /msk_tb_mdl_RX/shifter_viewer_CFO/srh3
add wave -noupdate -expand -group CFO /msk_tb_mdl_RX/shifter_viewer_CFO/sr32
add wave -noupdate -expand -group CFO -color Salmon /msk_tb_mdl_RX/shifter_viewer_CFO/genblk1/pattern_match
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {79410998 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 203
configure wave -valuecolwidth 186
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
WaveRestoreZoom {0 ps} {617969625 ps}
