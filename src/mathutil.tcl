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
    if {$xLen != $yLen} {
        error "Length of xList $xLen is not equal to length of yList $yLen"
    }
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
    if {$xLen != $yLen} {
        error "Length of xList $xLen is not equal to length of yList $yLen"
    }
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

proc ::mathutil::findApprox {list value {epsilon 1}} {
    # Finds index of firts matched value in list with epsilon tolerance
    #  list - list of values
    #  value - value to match
    #  epsilon - tolerance, default is 1
    # Returns: value from the list
    set idx 0
    foreach x $list {
        if {abs($value - $x) < $epsilon} {
            return $idx
        }
        incr idx
    }
    error "Value '$value' was not found"
}

proc ::mathutil::movAvg {y winSize args} {
    # Finds moving average of y with given window size.
    #  y - list of values, must be larger than window size
    #  winSize - size of the window, must be an integer larger than 1
    #  -x - optional argument with x values
    # Returns: list of y, and x if -x argument is specified
    set arguments [argparse {
        -x=
    }]
    # input verification
    if {[string is integer $winSize]!=1} {
        error "Window size must be an integer"
    } elseif {$winSize<2} {
        error "Window size must be larger than one"
    } elseif {$winSize%2==0} {
        error "Size of window must be odd"
    }
    set yLen [llength $y]
    if {$yLen < [+ $winSize 1]} {
        error "Length of y '$yLen' must be not less than size of window + 1  '$winSize + 1 = [+ $winSize 1]'"
    }
    if {[info exists x]} {
        set xLen [llength $x]
        if {$xLen != $yLen} {
            error "Length of x '$xLen' is not equal to length of y '$yLen'"
        }
    }
    # actual calculations
    set winSizeM1 [- $winSize 1]
    set halfWinSize [expr {int($winSizeM1/2)}]
    for {set i $halfWinSize} {$i<[- $yLen $halfWinSize]} {incr i} {
        set value 0
        for {set j [- $i $halfWinSize]} {$j<=[+ $i $halfWinSize]} {incr j} {
            set value [expr {$value+[lindex $y $j]}]
        }
        lappend yAvg [expr {$value/$winSize}]
    }
    if {[info exists x]} {
        return [list [lrange $x $halfWinSize end-$halfWinSize] $yAvg]
    } else {
        return $yAvg
    }  
}
