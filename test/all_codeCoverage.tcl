package require tcltest
namespace import ::tcltest::*
set dir [file normalize [file dirname [info script]]]

source [file join mathutil.tcl]
source [file join touchstoneutil.tcl]
source [file join rfutil.tcl]
source [file join test mathutil.test]
source [file join test touchstoneutil.test]
source [file join test rfutil.test]

