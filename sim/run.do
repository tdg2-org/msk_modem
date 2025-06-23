rm -rf work

vlog  ../hdl/common/led_cnt.sv  -sv -work work
vlog  ../hdl/tb/led_cnt_tb.sv   -sv -work work

vsim  -vopt work.led_cnt_tb -voptargs=+acc

log -r /*

if {[file exists wave.do]} {do wave.do}

run 100us