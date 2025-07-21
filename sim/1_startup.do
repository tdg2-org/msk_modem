if {![file exists modelsim.ini]} {vmap -c }

rm -rf work

do files1.do

vsim  -vopt work.$tbFile -voptargs=+acc -t ps

# ns, ps, fs resolution
#vsim  -vopt work.msk_tb -voptargs=+acc -t ns
#vsim  -vopt work.msk_tb -voptargs=+acc -t ps
#vsim  -vopt work.msk_tb -voptargs=+acc -t fs

log -r /*

# default wave file, leave this here
if {[file exists wave.do]} {do wave.do}

#--------------------------------------------------------------------------------------------------
# Note: this is tedious. Remember to close extra wave windows manually *sometimes* 
#   GUI config is stored in ~/.modelsim. wave windows may be duplicated. 
#   delete them and re-run. if startup.do is run without closing questa, generally OK...
#   not sure how to make this cleaner yet...
#
# parse for wave*.do files, load into unique wave windows
# use 'view wave -new -title <wave_name>' to add new window
#
# > view wave -new -title wave_NAME
#
# Note: questa underlying wave window titles are formatted wave,wave1,wave2...etc.
#   avoid these names in do files, use '_1' or anything else instead, prevents issues
#   with the catch command below checking for existing wave windows
#--------------------------------------------------------------------------------------------------
set waveName "wave"

set waveFiles [glob -nocomplain $waveName*.do]

# Remove default wave.do, already loaded above
set filteredWaveFiles [lsearch -exact -all $waveFiles wave.do]
if {$filteredWaveFiles != ""} {
  foreach idx [lsort -integer -decreasing $filteredWaveFiles] {
    set waveFiles [lreplace $waveFiles $idx $idx]
  }
}

foreach wFile $waveFiles {
  set wFroot [file rootname $wFile]
  [catch {view $wFroot} result]
  if {$result != ""} {
    do $wFile 
  } else {
    view wave -new -title $wFroot
    do $wFile
  }
}


run 5us




