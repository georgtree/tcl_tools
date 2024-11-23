package require tcltest
namespace import ::tcltest::*
package require csv
package require argparse

set script_path [file dirname [file normalize [info script]]]
lappend auto_path "$script_path/../"
package require gnuplotutil
package require mathutil

for {set i 0} {$i<=1000} {incr i} {
    set xi [expr {$i*0.05}]
    lappend x $xi
    lappend sinData [expr {sin($xi)+sin($xi*10)+sin($xi*100)+sin($xi*1000)}]
}

set sinDataFiltered_central [::mathutil::movAvg $sinData 15 -x $x -type central]
set sinDataFiltered_forward [::mathutil::movAvg $sinData 15 -x $x -type forward]
set sinDataFiltered_backward [::mathutil::movAvg $sinData 15 -x $x -type backward]
gnuplotutil::plotXNYN -xlabel "x label" -ylabel "y label" -grid -names {sindat 1 2 3}\
        -columns $x $sinData [lindex $sinDataFiltered_central 0] [lindex $sinDataFiltered_central 1]\
        [lindex $sinDataFiltered_forward 0] [lindex $sinDataFiltered_forward 1]\
        [lindex $sinDataFiltered_backward 0] [lindex $sinDataFiltered_backward 1]
#puts $sinDataFiltered
