package require tcltest
namespace import ::tcltest::*
set dir [file normalize [file dirname [info script]]]

source [file join $dir .. mathutil.tcl]
source [file join $dir .. touchstoneutil.tcl]
source [file join $dir .. rfutil.tcl]
source [file join $dir .. gnuplotutil.tcl]
source [file join mathutil.test]
source [file join touchstoneutil.test]
source [file join rfutil.test]
source [file join gnuplotutil.test]
