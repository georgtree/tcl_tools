package require argparse 0.58
package require extexpr
package provide mathutil 0.1

namespace eval ::mathutil {

    namespace import ::tcl::mathop::*
    namespace export trapz cumtrapz findApprox movAvg deriv1 deriv2
    interp alias {} dget {} dict get
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists
}

proc ::mathutil::trapz {args} {
    # Does trapezoidal integration of x-y lists
    #  x - list of x values
    #  y - list of y values
    # Returns: value of integral
    argparse -help {Does trapezoidal integration of x-y lists. Returns: value of integral} {
        {x -help {List of x values}}
        {y -help {List of y values}}
    }
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set result 0.0
    for {set i 0} {$i<$xLen-1} {incr i} {
        set result [= {$result+(lindex($y,$i+1)+lindex($y,$i))/2.0*(lindex($x,$i+1)-lindex($x,$i))}]
    }
    return $result
}

proc ::mathutil::cumtrapz {args} {
    # Does trapezoidal integration with storing cumulative data at each point
    #  x - list of x values
    #  y - list of y values
    #  init - start value
    # Returns: list each value of which is the value of integral across all previous xy values
    argparse -help {Does trapezoidal integration with storing cumulative data at each point. Returns: list each value\
                            of which is the value of integral across all previous xy values} {
        {x -help {List of x values}}
        {y -help {List of y values}}
        {init -optional -default 0.0 -type double -help {Start value}}
    }
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set result $init
    for {set i 0} {$i<$xLen-1} {incr i} {
        set result [= {$result+(lindex($y,$i+1)+lindex($y,$i))/2.0*(lindex($x,$i+1)-lindex($x,$i))}]
        lappend resultList $result
    }
    return $resultList
}

proc ::mathutil::findApprox {args} {
    # Finds index of first matched value in list with epsilon tolerance
    #  list - list of values
    #  value - value to match
    #  epsilon - tolerance
    # Returns: value from the list
    argparse -help {Finds index of first matched value in list with epsilon tolerance. Returns: value from the list} {
        {list -help {List of values}}
        {value -type double -help {Value to match}}
        {epsilon -optional -default 1.0 -type double -validate {[= {$arg>0.0}]}\
                 -errormsg {Epsilon must be larger than zero} -help {Tolerance value}}
    }
    set idx 0
    foreach x $list {
        if {abs($value - $x) < $epsilon} {
            return $idx
        }
        incr idx
    }
    return -code error "Value '$value' was not found"
}

proc ::mathutil::movAvg {args} {
    # Finds moving average of y with given window size.
    #  y - list of values, must be larger than window size
    #  winsize - size of the window, must be an integer larger than 1
    #  -x - optional argument with x values
    # Returns: list of y, and x if -x argument is specified
    argparse -pfirst -help {Finds moving average of y with given window size. Returns: list of y, and x if -x argument\
                                    is specified} {
        {y -help {List of values, must be larger than window size}}
        {winsize -type integer -help {Size of the window, must be an integer larger than 1 and odd size}}
        {-x= -help {Optional argument with x values}}
    }
    # input verification
    if {$winsize<2} {
        return -code error {Window size must be larger than one}
    } elseif {$winsize%2==0} {
        return -code error {Size of window must be odd}
    }
    set yLen [llength $y]
    if {$yLen<$winsize+1} {
        return -code error "Length of y '$yLen' must be not less than size of window + 1\
                '$winsize + 1 = [+ $winsize 1]'"
    }
    if {[info exists x]} {
        set xLen [llength $x]
        if {$xLen != $yLen} {
            return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
        }
    }
    # actual calculations
    set halfWinSize [= {int(($winsize-1)/2)}]
    for {set i $halfWinSize} {$i<$yLen-$halfWinSize} {incr i} {
        set value 0
        for {set j [= {$i-$halfWinSize}]} {$j<=$i+$halfWinSize} {incr j} {
            set value [= {$value+lindex($y,$j)}]
        }
        lappend yAvg [= {$value/$winsize}]
    }
    if {[info exists x]} {
        return [list [lrange $x $halfWinSize end-$halfWinSize] $yAvg]
    } else {
        return $yAvg
    }  
}

proc ::mathutil::deriv1 {args} {
    # Calculates first derivative of x-y lists
    #  x - list of x values
    #  y - list of y values
    # Returns: value of first derivative
    #
    # For calculating derivative we use 3-point method with unequal steps, equations
    # were taken from "Finite Difference Formulae for Unequal Sub-Intervals Using Lagrange's Interpolation Formula",
    # January 2009, International Journal of Mathematical Analysis 3(17):815-827, Ashok Kumar Singh
    argparse -help {Calculates first derivative of x-y lists. Returns: value of first derivative} {
        {x -help {List of x values}}
        {y -help {List of y values}}
    }
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set numPoints $xLen
    # calculate first point
    set h1 [= {lindex($x,1)-lindex($x,0)}]
    set h2 [= {lindex($x,2)-lindex($x,1)}]
    lappend yDeriv [= {-(2*$h1+$h2)/($h1*($h1+$h2))*lindex($y,0)+($h1+$h2)/($h1*$h2)*lindex($y,1)-$h1/($h2*($h1+$h2))*\
                               lindex($y,2)}]
    # calculate inner points
    for {set i 1} {$i<$numPoints-1} {incr i} {
        set h1 [= {lindex($x,$i)-lindex($x,$i-1)}]
        set h2 [= {lindex($x,$i+1)-lindex($x,$i)}]
        lappend yDeriv [= {-$h2/($h1*($h1+$h2))*lindex($y,$i-1)-($h1-$h2)/($h1*$h2)*lindex($y,$i)+$h1/($h2*($h1+$h2))*\
                                   lindex($y,$i+1)}]
    }
    # calculate last point
    set h1 [= {lindex($x,{end-1})-lindex($x,{end-2})}]
    set h2 [= {lindex($x,{end})-lindex($x,{end-1})}]
    lappend yDeriv [= {$h2/($h1*($h1+$h2))*lindex($y,{end-2})-($h1+$h2)/($h1*$h2)*lindex($y,{end-1})+\
                               ($h1+2*$h2)/($h2*($h1+$h2))*lindex($y,{end})}]
    return $yDeriv
}

proc ::mathutil::deriv2 {args} {
    # Calculates second derivative of x-y lists
    #  x - list of x values
    #  y - list of y values
    # Returns: value of second derivative
    #
    # For calculating derivative we use 3-point method with unequal steps, equations
    # were taken from "Finite Difference Formulae for Unequal Sub-Intervals Using Lagrange's Interpolation Formula",
    # January 2009, International Journal of Mathematical Analysis 3(17):815-827, Ashok Kumar Singh
    argparse -help {Calculates second derivative of x-y lists. Returns: value of second derivative} {
        {x -help {List of x values}}
        {y -help {List of y values}}
    }
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    set numPoints $xLen
    # calculate first point
    set h1 [= {lindex($x,1)-lindex($x,0)}]
    set h2 [= {lindex($x,2)-lindex($x,1)}]
    lappend yDeriv [= {2*($h2*lindex($y,0)-($h1+$h2)*lindex($y,1)+$h1*lindex($y,2))/($h1*$h2*($h1+$h2))}]
    # calculate inner points
    for {set i 1} {$i<$numPoints-1} {incr i} {
        set h1 [= {lindex($x,$i)-lindex($x,$i-1)}]
        set h2 [= {lindex($x,$i+1)-lindex($x,$i)}]
        lappend yDeriv [= {2*($h2*lindex($y,$i-1)-($h1+$h2)*lindex($y,$i)+$h1*lindex($y,$i+1))/($h1*$h2*($h1+$h2))}]
    }
    # calculate last point
    set h1 [= {lindex($x,{end-1})-lindex($x,{end-2})}]
    set h2 [= {lindex($x,{end})-lindex($x,{end-1})}]
    lappend yDeriv [= {2*($h2*lindex($y,{end-2})-($h1+$h2)*lindex($y,{end-1})+$h1*lindex($y,{end}))/($h1*$h2*($h1+$h2))}]
    return $yDeriv
}
