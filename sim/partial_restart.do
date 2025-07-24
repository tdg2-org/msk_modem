
set tbFile msk_tb_mdl_RX
#--------------------------------------------------------------------------------------------------
# msk
#--------------------------------------------------------------------------------------------------
set mskDir ../hdl
set comDir ../../common/hdl

#  vlog $mskDir/mdl/lpf_fixed_mdl.sv             -sv -work work
#  vlog $mskDir/mdl/polyphase_interp_mdl.sv      -sv -work work
#  vlog $mskDir/mdl/polyphase_interp_mdl_0.sv    -sv -work work
#  vlog $mskDir/mdl/ddc_lpf_mdl.sv               -sv -work work
#  vlog $mskDir/mdl/gardner_ted_mdl.sv           -sv -work work
  vlog $mskDir/mdl/loop_filter_mdl.sv           -sv -work work
#  vlog $mskDir/mdl/phase_accum_mdl.sv           -sv -work work
#  vlog $mskDir/mdl/msk_slicer_dec_mdl.sv        -sv -work work
#  vlog $mskDir/mdl/msk_demod_mdl.sv             -sv -work work
#  vlog $mskDir/mdl/mf_taps_pkg.sv               -sv -work work
#  vlog $mskDir/mdl/msk_mf.sv                    -sv -work work   
#  vlog $mskDir/mdl/coarse_cfo_mdl.sv            -sv -work work
#  vlog $mskDir/mdl/derotator_mdl.sv             -sv -work work
#  vlog $mskDir/mdl/phase_detector_mdl.sv        -sv -work work
#  vlog $mskDir/mdl/loop_filter_cfo_mdl.sv       -sv -work work
#  vlog $mskDir/mdl/nco_dds_mdl.sv               -sv -work work
#  vlog $comDir/mdl/tb/file_read_simple.sv       -sv -work work
#  vlog $comDir/mdl/shifter_viewer.sv            -sv -work work
#  vlog $comDir/mdl/variable_strobe.sv           -sv -work work
#  vlog $comDir/mdl/array_shift_delay.sv         -sv -work work

# vlog $mskDir/tb/$tbFile.sv   -sv -work work


restart

log -r *

run 400us

