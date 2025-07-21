onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate {/coarse_cfo_tb/genblk1[0]/coarse_cfo_mdl_inst/freq_word}
add wave -noupdate {/coarse_cfo_tb/genblk1[0]/coarse_cfo_mdl_inst/done}
add wave -noupdate {/coarse_cfo_tb/genblk1[1]/coarse_cfo_mdl_inst/freq_word}
add wave -noupdate {/coarse_cfo_tb/genblk1[1]/coarse_cfo_mdl_inst/done}
add wave -noupdate {/coarse_cfo_tb/genblk1[2]/coarse_cfo_mdl_inst/freq_word}
add wave -noupdate {/coarse_cfo_tb/genblk1[2]/coarse_cfo_mdl_inst/done}
add wave -noupdate {/coarse_cfo_tb/genblk1[3]/coarse_cfo_mdl_inst/freq_word}
add wave -noupdate {/coarse_cfo_tb/genblk1[3]/coarse_cfo_mdl_inst/done}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {12318820 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 362
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
WaveRestoreZoom {0 ps} {95660112 ps}
