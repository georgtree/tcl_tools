###Abstract
# This file implements functions for work with 2-port S-parameters data.
# Version: 0.1

package require math::complexnumbers
package require math::constants
package require argparse

package provide rfutil 0.1

namespace eval ::rfutil {

    namespace import ::math::complexnumbers::*
    namespace export s2z s2y z2s y2s z2y y2z zTEq yPEq inv2x2 deemb mag angle cxxTEq
    ::math::constants::constants radtodeg degtorad pi
}


proc ::rfutil::s2z {sxx z0} {
    # Procedure convert 2-port s-parameters to z-parameters
    #
    #  sxx - Dictionary that contains 2-port matrix of s-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    #  z0 - Reference impedance in form of {real imag}
    # 
    # Returns dictionary of the same form as input dictionary with z-parameters
    #
    set len [llength [dict get $sxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $sxx 11] $i]
        set 21 [lindex [dict get $sxx 21] $i]
        set 12 [lindex [dict get $sxx 12] $i]
        set 22 [lindex [dict get $sxx 22] $i]
        lappend z11 [* $z0 [/ [+ [* [+ $1c $11] [- $1c $22]] [* $12 $21] ] [- [* [- $1c $11] [- $1c $22]] [* $12 $21] ]]]
        lappend z12 [* $z0 [/ [* $2c $12] [- [* [- $1c $11] [- $1c $22]] [* $12 $21] ]]]
        lappend z21 [* $z0 [/ [* $2c $21] [- [* [- $1c $11] [- $1c $22]] [* $12 $21] ]]]
        lappend z22 [* $z0 [/ [+ [* [- $1c $11] [+ $1c $22]] [* $12 $21] ] [- [* [- $1c $11] [- $1c $22]] [* $12 $21] ]]]
    }
    return [dict create 11 $z11 21 $z21 12 $z12 22 $z22]
}

proc ::rfutil::s2t {sxx} {
    # Procedure convert 2-port s-parameters to transfer parameters
    #
    #  sxx - Dictionary that contains 2-port matrix of s-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the same form as input dictionary with transfer parameters
    #
    set len [llength [dict get $sxx 11]]
    set 1c [complex 1 0]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $sxx 11] $i]
        set 21 [lindex [dict get $sxx 21] $i]
        set 12 [lindex [dict get $sxx 12] $i]
        set 22 [lindex [dict get $sxx 22] $i]
        lappend t11 [- $12 [/ [* $11 $22] $21]]
        lappend t12 [/ $11 $21]
        lappend t21 [* $m1c [/ $22 $21]]
        lappend t22 [/ $1c $21]
    }
    return [dict create 11 $t11 21 $t21 12 $t12 22 $t22]
}

proc ::rfutil::t2s {txx} {
    # Procedure convert 2-port transfer parameters to s-parameters
    #
    #  txx - Dictionary that contains 2-port matrix of transfer parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # Returns dictionary of the same form as input dictionary with s-parameters
    #
    set len [llength [dict get $txx 11]]
    set 1c [complex 1 0]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $txx 11] $i]
        set 21 [lindex [dict get $txx 21] $i]
        set 12 [lindex [dict get $txx 12] $i]
        set 22 [lindex [dict get $txx 22] $i]
        lappend s11 [/ $12 $22]
        lappend s12 [- $11 [/ [* $12 $21] $22]]
        lappend s21 [/ $1c $22]
        lappend s22 [* $m1c [/ $21 $22]]
    }
    return [dict create 11 $s11 21 $s21 12 $s12 22 $s22]
}

proc ::rfutil::s2y {sxx z0} {
    # Procedure convert 2-port s-parameters to y-parameters
    #
    #  sxx - Dictionary that contains 2-port matrix of s-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    #  z0 - Reference impedance in form of {real imag}
    # 
    # Returns dictionary of the same form as input dictionary with y-parameters
    #
    set len [llength [dict get $sxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    set m2c [complex -2 0]
    set y0 [pow $z0 [complex -1 0]]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $sxx 11] $i]
        set 21 [lindex [dict get $sxx 21] $i]
        set 12 [lindex [dict get $sxx 12] $i]
        set 22 [lindex [dict get $sxx 22] $i]
        lappend y11 [* $y0 [/ [+ [* [- $1c $11] [+ $1c $22]] [* $12 $21] ] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21] ]]]
        lappend y12 [* $y0 [/ [* $m2c $12] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21] ]]]
        lappend y21 [* $y0 [/ [* $m2c $21] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21] ]]]
        lappend y22 [* $y0 [/ [+ [* [+ $1c $11] [- $1c $22]] [* $12 $21] ] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21] ]]]
    }
    return  [dict create 11 $y11 21 $y21 12 $y12 22 $y22]
}

proc ::rfutil::z2s {zxx z0} {
    # Procedure convert 2-port z-parameters to s-parameters
    #
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    #  z0 - Reference impedance in form of {real imag}
    # 
    # Returns dictionary of the same form as input dictionary with s-parameters
    #
    set len [llength [dict get $zxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $zxx 11] $i]
        set 21 [lindex [dict get $zxx 21] $i]
        set 12 [lindex [dict get $zxx 12] $i]
        set 22 [lindex [dict get $zxx 22] $i]
        lappend s11 [/ [- [* [- $11 $z0] [+ $22 $z0]] [* $12 $21]] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
        lappend s12 [/ [* [* $2c $12] $z0] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
        lappend s21 [/ [* [* $2c $21] $z0] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
        lappend s22 [/ [- [* [+ $11 $z0] [- $22 $z0]] [* $12 $21]] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
    }
    return [dict create 11 $s11 21 $s21 12 $s12 22 $s22]
}

proc ::rfutil::y2s {yxx z0} {
    # Procedure convert 2-port y-parameters to s-parameters
    #
    #   yxx - Dictionary that contains 2-port matrix of y-parameters,
    #    each matrix element is the list of values at different
    #    frequencies (or other parameter) in form of {real imag}.
    #    The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    #   z0 - Reference impedance in form of {real imag}
    # 
    # Returns dictionary of the same form as input dictionary with s-parameters
    #
    set len [llength [dict get $yxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    set m2c [complex -2 0]
    set y0 [pow $z0 [complex -1 0]]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $yxx 11] $i]
        set 21 [lindex [dict get $yxx 21] $i]
        set 12 [lindex [dict get $yxx 12] $i]
        set 22 [lindex [dict get $yxx 22] $i]
        lappend s11 [/ [+ [* [- $y0 $11 ] [+ $y0 $22]] [* $12 $21]] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
        lappend s12 [/ [* [* $m2c $12] $y0] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
        lappend s21 [/ [* [* $m2c $21] $y0] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
        lappend s22 [/ [+ [* [+ $y0 $11 ] [- $y0 $22]] [* $12 $21]] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
    }
    return [dict create 11 $s11 21 $s21 12 $s12 22 $s22]
}

proc ::rfutil::z2y {zxx} {
    # Procedure convert 2-port z-parameters to y-parameters
    #
    #   zxx - Dictionary that contains 2-port matrix of z-parameters,
    #    each matrix element is the list of values at different
    #    frequencies (or other parameter) in form of {real imag}.
    #    The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the same form as input dictionary with y-parameters
    #
    set len [llength [dict get $zxx 11]]
    set m1c [complex -1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $zxx 11] $i]
        set 21 [lindex [dict get $zxx 21] $i]
        set 12 [lindex [dict get $zxx 12] $i]
        set 22 [lindex [dict get $zxx 22] $i]
        lappend y11 [/ $22 [- [* $11 $22] [* $12 $21]]]
        lappend y12 [/ [* $12 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend y21 [/ [* $21 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend y22 [/ $11 [- [* $11 $22] [* $12 $21]]]
    }
    return [dict create 11 $y11 21 $y21 12 $y12 22 $y22]
}

proc ::rfutil::y2z {yxx} {
    # Procedure convert 2-port y-parameters to z-parameters
    #
    #   yxx - Dictionary that contains 2-port matrix of y-parameters,
    #    each matrix element is the list of values at different
    #    frequencies (or other parameter) in form of {real imag}.
    #    The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the same form as input dictionary with z-parameters
    #
    set len [llength [dict get $yxx 11]]
    set m1c [complex -1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $yxx 11] $i]
        set 21 [lindex [dict get $yxx 21] $i]
        set 12 [lindex [dict get $yxx 12] $i]
        set 22 [lindex [dict get $yxx 22] $i]
        lappend z11 [/ $22 [- [* $11 $22] [* $12 $21]]]
        lappend z12 [/ [* $12 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend z21 [/ [* $21 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend z22 [/ $11 [- [* $11 $22] [* $12 $21]]]
    }
    return [dict create 11 $z11 21 $z21 12 $z12 22 $z22]
}

proc ::rfutil::zTEq {zxx} {
    # Procedure calculates equivalent T circuit elements values
    # 
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the form {z1 {list} z2 {list} z3 {list}} with impedances of equivalent elements
    #
    #               Z1            Z2                                         
    #              ___           ___                                        
    #         o---|___|----o----|___|---o                                   
    #         .            |            .                                   
    #         .           .-.           .                                   
    #      P1 .           | |           . P2                                
    #         .         Z3| |           .                                   
    #         .           '-'           .                                  
    #        \./           |           \./                                  
    #         o----------- o -----------o   
    #
    set len [llength [dict get $zxx 11]]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $zxx 11] $i]
        set 21 [lindex [dict get $zxx 21] $i]
        set 22 [lindex [dict get $zxx 22] $i]
        lappend z1 [- $11 $21]
        lappend z2 [- $22 $21]
        lappend z3 $21
    }
    return [dict create z1 $z1 z2 $z2 z3 $z3]
}

proc ::rfutil::cxxTEq {freq zxx} {
    # Procedure calculates capacitive part equivalent T circuit elements values
    #
    #  freq - Frequency values list
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the form {c1 {list} c2 {list} c3 {list}} with capacitive part of equivalent elements impedance
    #
    #             C1           C2            
    #              | |           | |         
    #         o----| |-----o-----| |----o    
    #         .    | |     |     | |    .    
    #         .            |            .    
    #      P1 .         C3---           . P2 
    #         .           ---           .    
    #        \./           |           \./   
    #         .            |            .    
    #         o----------- o -----------o 
    #
    variable pi
    set zEq [::rfutil::zTEq $zxx]
    set 1c [complex 1 0]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [lindex $freq $i]
        set z1 [lindex [dict get $zEq z1] $i]
        set z2 [lindex [dict get $zEq z2] $i]
        set z3 [lindex [dict get $zEq z3] $i]
        lappend c1 [expr {-1/(2*$pi*$freqVal*[imag $z1])}]
        lappend c2 [expr {-1/(2*$pi*$freqVal*[imag $z2])}]
        lappend c3 [expr {-1/(2*$pi*$freqVal*[imag $z3])}]
    }
    return [dict create c1 $c1 c2 $c2 c3 $c3]
}

proc ::rfutil::lxxTEq {freq zxx} {
    # Procedure calculates inductive part equivalent T circuit elements values
    #
    #  freq - Frequency values list
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the form {l1 {list} l2 {list} l3 {list}} with inductive part of equivalent elements impedance
    #
    #             L1            L2          
    #              ___           ___        
    #         o----UUU-----o-----UUU----o   
    #         .            |            .   
    #         .         L3 C|           .   
    #      P1 .            C|           . P2
    #         .            C|           .   
    #        \./           |           \./  
    #         .            |            .   
    #         o----------- o -----------o   
    #
    variable pi
    set zEq [::rfutil::zTEq $zxx]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [lindex $freq $i]
        set z1 [lindex [dict get $zEq z1] $i]
        set z2 [lindex [dict get $zEq z2] $i]
        set z3 [lindex [dict get $zEq z3] $i]
        lappend l1 [expr {[imag $z1]/(2*$pi*$freqVal)}]
        lappend l2 [expr {[imag $z2]/(2*$pi*$freqVal)}]
        lappend l3 [expr {[imag $z3]/(2*$pi*$freqVal)}]
    }
    return [dict create l1 $l1 l2 $l2 l3 $l3]
}

proc ::rfutil::yPEq {yxx} {
    # Procedure calculates equivalent P circuit elements values
    #
    #  yxx - Dictionary that contains 2-port matrix of y-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the form {y1 {list} y2 {list} y3 {list}} with impedances of equivalent elements
    #
    #                      Y3
    #                      ___                                               
    #          o-----o----|___|----o-----o                                   
    #          .     |             |     .                                   
    #          .    .-.           .-.    .                                   
    #       P1 .    | |           | |    . P2                                
    #          .  Y1| |         Y2| |    .                                   
    #          .    '-'           '-'    .                                  
    #         \./    |             |    \./                                   
    #          o-----o-------------o-----o       
    #
    set len [llength [dict get $yxx 11]]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [lindex [dict get $yxx 11] $i]
        set 21 [lindex [dict get $yxx 21] $i]
        set 22 [lindex [dict get $yxx 22] $i]
        lappend y1 [+ $11 $21]
        lappend y2 [+ $22 $21]
        lappend y3 [* $m1c $21]
    }
    return [dict create y1 $y1 y2 $y2 y3 $y3]
}

proc ::rfutil::cxxPEq {freq yxx} {
    # Procedure calculates capacitive part equivalent P circuit elements values
    #
    #  freq - Frequency values list
    #  yxx - Dictionary that contains 2-port matrix of y-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the form {c1 {list} c2 {list} c3 {list}} with capacitive part of equivalent elements admittance
    #
    #                     C3                  
    #                      | |                
    #          o-----o-----| |-----o-----o    
    #          .     |     | |     |     .    
    #          .     |             |     .    
    #       P1 .  C1---         C2---    . P2 
    #          .    ---           ---    .    
    #         \./    |             |    \./   
    #          .     |             |     .    
    #          o-----o-------------o-----o    
    #
    variable pi
    set yEq [::rfutil::yPEq $yxx]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [lindex $freq $i]
        set y1 [lindex [dict get $yEq y1] $i]
        set y2 [lindex [dict get $yEq y2] $i]
        set y3 [lindex [dict get $yEq y3] $i]
        lappend c1 [expr {[imag $y1]/(2*$pi*$freqVal)}]
        lappend c2 [expr {[imag $y2]/(2*$pi*$freqVal)}]
        lappend c3 [expr {[imag $y3]/(2*$pi*$freqVal)}]
    }
    return [dict create c1 $c1 c2 $c2 c3 $c3]
}

proc ::rfutil::lxxPEq {freq yxx} {
    # Procedure calculates inductive part equivalent P circuit elements values
    #
    #  freq - Frequency values list
    #  yxx - Dictionary that contains 2-port matrix of y-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the form {l1 {list} l2 {list} l3 {list}} with inductive part of equivalent elements impedance
    #
    #                       L3                 
    #                       ___                
    #           o-----o-----UUU-----o-----o    
    #           .     |             |     .    
    #           .  L1 C|         L2 C|    .    
    #        P1 .     C|            C|    . P2 
    #           .     C|            C|    .    
    #          \./    |             |    \./   
    #           .     |             |     .    
    #           o-----o-------------o-----o      
    #
    variable pi
    set yEq [::rfutil::yPEq $yxx]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [lindex $freq $i]
        set y1 [lindex [dict get $yEq y1] $i]
        set y2 [lindex [dict get $yEq y2] $i]
        set y3 [lindex [dict get $yEq y3] $i]
        lappend l1 [expr {-1/(2*$pi*$freqVal*[imag $y1])}]
        lappend l2 [expr {-1/(2*$pi*$freqVal*[imag $y2])}]
        lappend l3 [expr {-1/(2*$pi*$freqVal*[imag $y3])}]
    }
    return [dict create l1 $l1 l2 $l2 l3 $l3]
}

proc ::rfutil::inv2x2 {mat} {
    # Procedure calculates inverse matrix of input matrix with size 2x2
    #
    #  mat - Dictionary that contains 2-port matrix,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 {list} 12 {list} 21 {list} 22 {list}}
    # 
    # Returns dictionary of the same form as input dictionary with resulted matrix
    #
    set len [llength [dict get $mat 11]]
    set 1c [complex 1 0]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set a [lindex [dict get $mat 11] $i]
        set b [lindex [dict get $mat 12] $i]
        set c [lindex [dict get $mat 21] $i]
        set d [lindex [dict get $mat 22] $i]
        set det [- [* $a $d] [* $b $c]]
        if {([real $det]==0.0) && ([imag $det]==0.0)} {
            error "Matrix can't be inverted"
        }
        set rec [/ $1c $det]
        lappend 11 [* $rec $d]
        lappend 12 [* $rec [* $m1c $b]]
        lappend 21 [* $rec [* $m1c $c]]
        lappend 22 [* $rec $a]
    }
    return [dict create 11 $11 21 $21 12 $12 22 $22]
}

proc ::rfutil::matMul2x2 {mat1 mat2} {
    # Procedure calculates multiply matrices with 2x2 size
    #
    #  mat1 - First matrix in dictionary form {11 {list} 12 {list} 21 {list} 22 {list}}
    #  mat2 - Second matrix in dictionary form {11 {list} 12 {list} 21 {list} 22 {list}}
    #                
    # Returns dictionary of the same form as input dictionaries with resulted matrix
    #
    set len1 [llength [dict get $mat1 11]]
    set len2 [llength [dict get $mat2 11]]
    if {$len1!=$len2} {
        error "Lengths of matrix elements lists are different"
    }
    for {set i 0} {$i<$len1} {incr i} {
        set a1 [lindex [dict get $mat1 11] $i]
        set b1 [lindex [dict get $mat1 12] $i]
        set c1 [lindex [dict get $mat1 21] $i]
        set d1 [lindex [dict get $mat1 22] $i]
        set a2 [lindex [dict get $mat2 11] $i]
        set b2 [lindex [dict get $mat2 12] $i]
        set c2 [lindex [dict get $mat2 21] $i]
        set d2 [lindex [dict get $mat2 22] $i]
        lappend 11 [+ [* $a1 $a2] [* $b1 $c2]]
        lappend 12 [+ [* $a1 $b2] [* $b1 $d2]]
        lappend 21 [+ [* $c1 $a2] [* $d1 $c2]]
        lappend 22 [+ [* $c1 $b2] [* $d1 $d2]]
    }
    return [dict create 11 $11 21 $21 12 $12 22 $22]
}

proc ::rfutil::deemb {sMeas sFixtL sFixtR} {
    # Procedure for deembedding of DUT from test fixture 
    #
    #  sMeas - Measured s-parameters matrix in dictionary form {11 {list} 12 {list} 21 {list} 22 {list}}
    #  sFixtL - s-parameters matrix of left fixture in dictionary form {11 {list} 12 {list} 21 {list} 22 {list}}
    #  sFixtR - s-parameters matrix of right fixture in dictionary form {11 {list} 12 {list} 21 {list} 22 {list}}
    #                
    # Returns dictionary of the same form as input dictionaries with deembedded DUT s-matrix
    #```
    #    ┌      ┐   ┌        ┐-1   ┌       ┐     ┌        ┐-1
    #    │ Tdut │ = │ Tfixtl │  x  │ Tmeas │  x  │ Tfixtr │
    #    └      ┘   └        ┘     └       ┘     └        ┘
    #```
    set tMeas [s2t $sMeas]
    set tFixtL [inv2x2 [s2t $sFixtL]]
    set tFixtR [inv2x2 [s2t $sFixtR]]
    set tDut [matMul2x2 [matMul2x2 $tFixtL $tMeas] $tFixtR]
    set sDut [t2s $tDut]
    return $sDut
}

proc ::rfutil::mag {data args} {
    # Procedure calculates magnitude of complex number
    #
    #  data - List with complex data in form a+i*b
    #  -db - Option to select magnitude in db scale
    #                
    # Returns list of magnitudes
    #
    set arguments [argparse -inline {
        {-db -boolean} }]
    set len [llength $data]
    if {[dict get $arguments db]==1} {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [expr {20*log10([mod [lindex $data $i]])} ]
        }
    } else {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [mod [lindex $data $i]]
        }
    }
    return $result
}

proc ::rfutil::angle {data args} {
    # Procedure calculates angle (phase) of complex number
    #
    #  data - List with complex data in form a+i*b
    #  -deg - Option to select angle in degrees units
    #                
    # Returns list of angles
    #
    set arguments [argparse -inline {
        {-deg -boolean} }]
    variable radtodeg
    set len [llength $data]
    if {[dict get $arguments deg]==1} {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [expr {$radtodeg*[arg [lindex $data $i]]}]
        }
    } else {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [arg [lindex $data $i]]
        }
    }
    return $result
}
