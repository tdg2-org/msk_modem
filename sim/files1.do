set tbFile msk_tb_mdl_RX

#--------------------------------------------------------------------------------------------------
# msk
#--------------------------------------------------------------------------------------------------
set mskDir ../hdl
set mskFiles { \
  mdl/lpf_fixed_mdl.sv \
  mdl/polyphase_interp_mdl.sv \
  mdl/polyphase_interp_mdl_0.sv \
  mdl/ddc_lpf_mdl.sv \
  mdl/gardner_ted_mdl.sv \
  mdl/loop_filter_mdl.sv \
  mdl/phase_accum_mdl.sv \
  mdl/msk_slicer_dec_mdl.sv \
  mdl/msk_demod_mdl.sv \
  mdl/mf_taps_pkg.sv \
  mdl/msk_mf.sv \
  mdl/coarse_cfo_mdl.sv \
  mdl/derotator_mdl.sv \
  mdl/phase_detector_mdl.sv \
  mdl/loop_filter_cfo_mdl.sv \
  mdl/nco_dds_mdl.sv \
}  

foreach x $mskFiles {
  vlog $mskDir/$x -sv -work work
}


#--------------------------------------------------------------------------------------------------
# common
#--------------------------------------------------------------------------------------------------
set comDir ../../common/hdl
set comFiles {\
  tb/file_read_simple.sv \
  shifter_viewer.sv \
  variable_strobe.sv \
  array_shift_delay.sv \
}

foreach x $comFiles {
  vlog $comDir/$x -sv -work work
}


#--------------------------------------------------------------------------------------------------
# tb
#--------------------------------------------------------------------------------------------------
vlog $mskDir/tb/$tbFile.sv   -sv -work work

