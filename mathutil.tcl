package require argparse
package require math::interpolate
package provide mathutil 0.1

namespace eval ::mathutil {

    namespace import ::tcl::mathop::*
    namespace export trapz cumtrapz findApprox movAvg deriv1 deriv2
    interp alias {} dget {} dict get
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists
}

proc ::mathutil::trapz {x y} {
    # Does trapezoidal integration of x-y lists
    #  x - list of x values
    #  y - list of y values
    # Returns: value of integral
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set result 0.0
    for {set i 0} {$i<[- $xLen 1]} {incr i} {
        set result [= {$result+([@ $y [+ $i 1]]+[@ $y $i])/2.0*([@ $x [+ $i 1]]-[@ $x $i])}]
    }
    return $result
}

proc ::mathutil::cumtrapz {x y {init 0}} {
    # Does trapezoidal integration with storing cumulative data at each point
    #  x - list of x values
    #  y - list of y values
    #  init - start value
    # Returns: list each value of which is the value of integral across all previous xy values
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set result $init
    for {set i 0} {$i<[- $xLen 1]} {incr i} {
        set result [= {$result+([@ $y [+ $i 1]]+[@ $y $i])/2.0*([@ $x [+ $i 1]]-[@ $x $i])}]
        lappend resultList $result
    }
    return $resultList
}

proc ::mathutil::findApprox {list value {epsilon 1}} {
    # Finds index of first matched value in list with epsilon tolerance
    #  list - list of values
    #  value - value to match
    #  epsilon - tolerance
    # Returns: value from the list
    if {![string is double $epsilon]} {
        return -code error "Epsilon must be a number"
    } elseif {$epsilon<=0} {
        return -code error "Epsilon must be larger than zero"
    }
    if {![string is double $value]} {
        return -code error "Value must be a number"
    }
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
    if {![string is integer $winSize]} {
        return -code error "Window size must be an integer"
    } elseif {$winSize<2} {
        return -code error "Window size must be larger than one"
    } elseif {$winSize%2==0} {
        return -code error "Size of window must be odd"
    }
    set yLen [llength $y]
    if {$yLen < [+ $winSize 1]} {
        return -code error "Length of y '$yLen' must be not less than size of window + 1  '$winSize + 1 = [+ $winSize 1]'"
    }
    if {[info exists x]} {
        set xLen [llength $x]
        if {$xLen != $yLen} {
            return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
        }
    }
    # actual calculations
    set winSizeM1 [- $winSize 1]
    set halfWinSize [= {int($winSizeM1/2)}]
    for {set i $halfWinSize} {$i<[- $yLen $halfWinSize]} {incr i} {
        set value 0
        for {set j [- $i $halfWinSize]} {$j<=[+ $i $halfWinSize]} {incr j} {
            set value [= {$value+[@ $y $j]}]
        }
        lappend yAvg [= {$value/$winSize}]
    }
    if {[info exists x]} {
        return [list [lrange $x $halfWinSize end-$halfWinSize] $yAvg]
    } else {
        return $yAvg
    }  
}

proc ::mathutil::deriv1 {x y} {
    # Calculates first derivative of x-y lists
    #  x - list of x values
    #  y - list of y values
    # Returns: value of first derivative
    #
    # For calculating derivative we use 3-point method with unequal steps, equations
    # were taken from "Finite Difference Formulae for Unequal Sub-Intervals Using Lagrange's Interpolation Formula",
    # January 2009, International Journal of Mathematical Analysis 3(17):815-827, Ashok Kumar Singh
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set numPoints $xLen
    # calculate first point
    set h1 [- [@ $x 1] [@ $x 0]]
    set h2 [- [@ $x 2] [@ $x 1]]
    lappend yDeriv [= {-(2*$h1+$h2)/($h1*($h1+$h2))*[@ $y 0]+($h1+$h2)/($h1*$h2)*[@ $y 1]-\
                                  $h1/($h2*($h1+$h2))*[@ $y 2]}]
    # calculate inner points
    for {set i 1} {$i<[- $numPoints 1]} {incr i} {
        set h1 [- [@ $x $i] [@ $x [- $i 1]]]
        set h2 [- [@ $x [+ $i 1]] [@ $x $i]]
        lappend yDeriv [= {-$h2/($h1*($h1+$h2))*[@ $y [- $i 1]]-($h1-$h2)/($h1*$h2)*[@ $y $i]+\
                                      $h1/($h2*($h1+$h2))*[@ $y [+ $i 1]]}]
    }
    # calculate last point
    set h1 [- [@ $x end-1] [@ $x end-2]]
    set h2 [- [@ $x end] [@ $x end-1]]
    lappend yDeriv [= {$h2/($h1*($h1+$h2))*[@ $y end-2]-($h1+$h2)/($h1*$h2)*[@ $y end-1]+\
                                  ($h1+2*$h2)/($h2*($h1+$h2))*[@ $y end]}]
    return $yDeriv
}

proc ::mathutil::deriv2 {x y} {
    # Calculates second derivative of x-y lists
    #  x - list of x values
    #  y - list of y values
    # Returns: value of second derivative
    #
    # For calculating derivative we use 3-point method with unequal steps, equations
    # were taken from "Finite Difference Formulae for Unequal Sub-Intervals Using Lagrange's Interpolation Formula",
    # January 2009, International Journal of Mathematical Analysis 3(17):815-827, Ashok Kumar Singh
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set numPoints $xLen
    # calculate first point
    set h1 [- [@ $x 1] [@ $x 0]]
    set h2 [- [@ $x 2] [@ $x 1]]
    lappend yDeriv [= {2*($h2*[@ $y 0]-($h1+$h2)*[@ $y 1]+$h1*[@ $y 2])/($h1*$h2*($h1+$h2))}]
    # calculate inner points
    for {set i 1} {$i<[- $numPoints 1]} {incr i} {
        set h1 [- [@ $x $i] [@ $x [- $i 1]]]
        set h2 [- [@ $x [+ $i 1]] [@ $x $i]]
        lappend yDeriv [= {2*($h2*[@ $y [- $i 1]]-($h1+$h2)*[@ $y $i]+$h1*[@ $y [+ $i 1]])/($h1*$h2*($h1+$h2))}]
    }
    # calculate last point
    set h1 [- [@ $x end-1] [@ $x end-2]]
    set h2 [- [@ $x end] [@ $x end-1]]
    lappend yDeriv [= {2*($h2*[@ $y end-2]-($h1+$h2)*[@ $y end-1]+$h1*[@ $y end])/($h1*$h2*($h1+$h2))}]
    return $yDeriv
}
