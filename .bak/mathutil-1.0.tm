

package require argparse


namespace eval ::mathutil {

    namespace import ::tcl::mathop::*
    namespace export trapz cumtrapz
}

# trapz --
#    Procedure for trapezoidal integration of x-y lists
#
# Arguments:
#    xList           x-data list
#    yList           y-data list
# Result:
#    Value of integral
#
proc mathutil::trapz {xList yList} {
    set xLen [llength $xList]
    set yLen [llength $yList]
    if {$xLen != $yLen} {error "Length of xList $xLen is not equal to length of yList $yLen"}
    set result 0.0
    for {set i 0} {$i<[- $xLen 1]} {incr i} {
        set xI [lindex $xList $i]
        set xIp1 [lindex $xList [+ $i 1]]
        set yI [lindex $yList $i]
        set yIp1 [lindex $yList [+ $i 1]]
        set result [expr {$result+($yIp1+$yI)/2.0*($xIp1-$xI)}]
    }
    return $result
}


# cumtrapz --
#    Procedure for trapezoidal integration with cumulative data result
#
# Arguments:
#    xList           x-data list
#    yList           y-data list
#    init            initial value of integral
# Result:
#    Each value of resulted list is the value of integral across all previous xy values
#
proc mathutil::cumtrapz {xList yList {init 0}} {
    set xLen [llength $xList]
    set yLen [llength $yList]
    if {$xLen != $yLen} {error "Length of xList $xLen is not equal to length of yList $yLen"}
    set result $init
    for {set i 0} {$i<[- $xLen 1]} {incr i} {
        set xI [lindex $xList $i]
        set xIp1 [lindex $xList [+ $i 1]]
        set yI [lindex $yList $i]
        set yIp1 [lindex $yList [+ $i 1]]
        set result [expr {$result+($yIp1+$yI)/2.0*($xIp1-$xI)}]
        lappend resultList $result
    }
    return $resultList
}