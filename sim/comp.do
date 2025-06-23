rm -rf work
vlog  ../hdl/common/led_cnt.sv  -sv -work work
vlog  ../hdl/tb/led_cnt_tb.sv   -sv -work work

restart

log -r *

run 100us