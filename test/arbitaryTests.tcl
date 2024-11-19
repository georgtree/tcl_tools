package require tcltest
namespace import ::tcltest::*
package require csv
package require argparse

set script_path [file dirname [file normalize [info script]]]
lappend auto_path "$script_path/../"
package require gnuplotutil


test testPlotXYN-2 {test with no switches} -setup {
    set x [list 0 1 2 3 4 5 6]
    set y1 [list 0 1 4 9 16 25 36]
    set y2 [list 0 1 8 27 64 125 216]
} -body {
    set result [gnuplotutil::plotXYN $x -names [list y1 y2] -columns $y1 $y2]
    return $result
} -result ""
