package require argparse

package provide mathutil 0.1

namespace eval ::mathutil {

    namespace import ::tcl::mathop::*
    namespace export trapz cumtrapz
}

proc mathutil::trapz {xList yList} {
    # Does trapezoidal integration of x-y lists
    #  xList - list of x values
    #  yList - list of y values
    # Returns: value of integral
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

proc mathutil::cumtrapz {xList yList {init 0}} {
    # Does trapezoidal integration with storing cumulative data at each point
    #  xList - list of x values
    #  yList - list of y values
    #  init - start value, default is 0
    # Returns: list each value of which is the value of integral across all previous xy values
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