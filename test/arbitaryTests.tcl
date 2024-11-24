package require tcltest
namespace import ::tcltest::*
namespace import ::tcl::mathop::*
package require csv
package require argparse

set script_path [file dirname [file normalize [info script]]]
lappend auto_path "$script_path/../"
package require gnuplotutil
package require mathutil
set xi 0
for {set i 0} {$i<=100} {incr i} {
    set xi [expr {($xi+0.05*$i/50)}]
    lappend x $xi
    lappend y [expr {sin($xi)}]
}

set deriv2Data1 [::mathutil::deriv1 $x [::mathutil::deriv1 $x $y] ]
set deriv2Data [::mathutil::deriv2 $x $y]
gnuplotutil::plotXNYN -xlabel "x label" -ylabel "y label" -grid -names {sindat 1 2}\
        -columns $x $y $x $deriv2Data $x $deriv2Data1
# puts $x
#puts $sinDataFiltered

