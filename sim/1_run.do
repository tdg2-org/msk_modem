if {![file exists modelsim.ini]} {vmap -c }

rm -rf work

#vcom  ../hdl/common/2008/led_cnt_vhd08.vhd  -2008 -work work
#vlog  ../hdl/common/led_cnt.sv  -sv -work work
#vlog  ../hdl/tb/led_cnt_tb.sv   -sv -work work

vlog  ../hdl/real_to_iq.sv    -sv -work work
vlog  ../hdl/iq_to_real.sv    -sv -work work
vlog  ../hdl/mdl/downconverter_mdl.sv -sv -work work
vlog  ../hdl/mdl/upconverter_mdl.sv   -sv -work work
vlog  ../hdl/mdl/msk_modulator_mdl.sv -sv -work work
vlog  ../hdl/mdl/msk_demodulator_mdl.sv -sv -work work
vlog  ../hdl/tb/msk_tb.sv         -sv -work work

vsim  -vopt work.msk_tb -voptargs=+acc -t ns

# ps resolution
#vsim  -vopt work.msk_tb -voptargs=+acc -t ps
#vsim  -vopt work.msk_tb -voptargs=+acc -t fs

log -r /*

if {[file exists wave.do]} {do wave.do}

run 5us