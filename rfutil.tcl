###Abstract
# This file implements functions for work with 2-port S-parameters data.
# Version: 0.1

package require math::complexnumbers
package require math::constants
package require argparse 0.58

package provide rfutil 0.1

namespace eval ::rfutil {

    namespace import ::math::complexnumbers::*
    namespace export s2z s2t t2s s2y z2s y2s z2y y2z zTEq cxxTEq lxxTEq yPEq cxxPEq lxxPEq inv2x2 matMul2x2 deemb mag\
            angle 
    ::math::constants::constants radtodeg degtorad pi
    interp alias {} dget {} dict get
    interp alias {} dkeys {} dict keys
    interp alias {} dvalues {} dict values
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists
    interp alias {} dsize {} dict size
}

proc ::rfutil::compLen {dict} {
    # Check the lengths of lists of each dictionary's list
    #  dict - input dictionary
    set keys [dkeys $dict]
    set values [dvalues $dict]
    set size [dsize $dict]
    for {set i 0} {$i<[= {$size-1}]} {incr i} {
        set keyA [@ $keys $i]
        set keyB [@ $keys [= {$i+1}]]
        set lenA [llength [@ $values $i]]
        set lenB [llength [@ $values [= {$i+1}]]]
        if {$lenA!=$lenB} {
            error "Length of $keyA '$lenA' is not equal to length of $keyB '$lenB'"
        }
    }
    return
}

proc ::rfutil::s2z {args} {
    # Converts 2-port s-parameters to z-parameters.
    #
    #  sxx - Dictionary that contains 2-port matrix of s-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    #  z0 - Reference impedance in form of {real imag}, default is {50 0}, optional
    # 
    # Returns dictionary of the same form as input dictionary with z-parameters
    #
    argparse -help {Converts 2-port s-parameters to z-parameters. Returns dictionary of the same form as input\
                            dictionary with z-parameters} {
        {sxx -help {Dictionary that contains 2-port matrix of s-parameters, each matrix element is the list of values\
                            at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
        {z0 -optional -default {50.0 0.0} -help {Reference impedance in form of {real imag}}}
    }
    ::rfutil::compLen $sxx
    set len [llength [dget $sxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $sxx 11] $i]
        set 21 [@ [dget $sxx 21] $i]
        set 12 [@ [dget $sxx 12] $i]
        set 22 [@ [dget $sxx 22] $i]
        lappend z11 [* $z0 [/ [+ [* [+ $1c $11] [- $1c $22]] [* $12 $21]] [- [* [- $1c $11] [- $1c $22]] [* $12 $21]]]]
        lappend z12 [* $z0 [/ [* $2c $12] [- [* [- $1c $11] [- $1c $22]] [* $12 $21] ]]]
        lappend z21 [* $z0 [/ [* $2c $21] [- [* [- $1c $11] [- $1c $22]] [* $12 $21] ]]]
        lappend z22 [* $z0 [/ [+ [* [- $1c $11] [+ $1c $22]] [* $12 $21]] [- [* [- $1c $11] [- $1c $22]] [* $12 $21]]]]
    }
    return [dict create 11 $z11 21 $z21 12 $z12 22 $z22]
}

proc ::rfutil::s2t {args} {
    # Converts 2-port s-parameters to transfer parameters.
    #
    #  sxx - Dictionary that contains 2-port matrix of s-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the same form as input dictionary with transfer parameters
    #
    argparse -help {Converts 2-port s-parameters to transfer parameters. Returns dictionary of the same form as input\
                            dictionary with transfer parameters} {
        {sxx -help {Dictionary that contains 2-port matrix of s-parameters, each matrix element is the list of values\
                            at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $sxx
    set len [llength [dget $sxx 11]]
    set 1c [complex 1 0]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $sxx 11] $i]
        set 21 [@ [dget $sxx 21] $i]
        set 12 [@ [dget $sxx 12] $i]
        set 22 [@ [dget $sxx 22] $i]
        lappend t11 [- $12 [/ [* $11 $22] $21]]
        lappend t12 [/ $11 $21]
        lappend t21 [* $m1c [/ $22 $21]]
        lappend t22 [/ $1c $21]
    }
    return [dict create 11 $t11 21 $t21 12 $t12 22 $t22]
}

proc ::rfutil::t2s {args} {
    # Converts 2-port transfer parameters to s-parameters.
    #
    #  txx - Dictionary that contains 2-port matrix of transfer parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # Returns dictionary of the same form as input dictionary with s-parameters
    #
    argparse -help {Converts 2-port transfer parameters to s-parameters. Returns dictionary of the same form as input\
                            dictionary with s-parameters} {
        {txx -help {Dictionary that contains 2-port matrix of transfer parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $txx
    set len [llength [dget $txx 11]]
    set 1c [complex 1 0]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $txx 11] $i]
        set 21 [@ [dget $txx 21] $i]
        set 12 [@ [dget $txx 12] $i]
        set 22 [@ [dget $txx 22] $i]
        lappend s11 [/ $12 $22]
        lappend s12 [- $11 [/ [* $12 $21] $22]]
        lappend s21 [/ $1c $22]
        lappend s22 [* $m1c [/ $21 $22]]
    }
    return [dict create 11 $s11 21 $s21 12 $s12 22 $s22]
}

proc ::rfutil::s2y {args} {
    # Converts 2-port s-parameters to y-parameters.
    #
    #  sxx - Dictionary that contains 2-port matrix of s-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    #  z0 - Reference impedance in form of {real imag}, default is {50 0}, optional
    # 
    # Returns dictionary of the same form as input dictionary with y-parameters
    #
    argparse -help {Converts 2-port s-parameters to y-parameters. Returns dictionary of the same form as input\
                            dictionary with y-parameters} {
        {sxx -help {Dictionary that contains 2-port matrix of s-parameters, each matrix element is the list of values\
                            at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
        {z0 -optional -default {50.0 0.0} -help {Reference impedance in form of {real imag}}}
    }
    ::rfutil::compLen $sxx
    set len [llength [dget $sxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    set m2c [complex -2 0]
    set y0 [pow $z0 [complex -1 0]]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $sxx 11] $i]
        set 21 [@ [dget $sxx 21] $i]
        set 12 [@ [dget $sxx 12] $i]
        set 22 [@ [dget $sxx 22] $i]
        lappend y11 [* $y0 [/ [+ [* [- $1c $11] [+ $1c $22]] [* $12 $21]] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21]]]]
        lappend y12 [* $y0 [/ [* $m2c $12] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21] ]]]
        lappend y21 [* $y0 [/ [* $m2c $21] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21] ]]]
        lappend y22 [* $y0 [/ [+ [* [+ $1c $11] [- $1c $22]] [* $12 $21]] [- [* [+ $1c $11] [+ $1c $22]] [* $12 $21]]]]
    }
    return [dict create 11 $y11 21 $y21 12 $y12 22 $y22]
}

proc ::rfutil::z2s {args} {
    # Converts 2-port z-parameters to s-parameters.
    #
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    #  z0 - Reference impedance in form of {real imag}, default is {50 0}, optional
    # 
    # Returns dictionary of the same form as input dictionary with s-parameters
    #
    argparse -help {Converts 2-port z-parameters to s-parameters. Returns dictionary of the same form as input\
                            dictionary with s-parameters} {
        {zxx -help {Dictionary that contains 2-port matrix of z-parameters, each matrix element is the list of values\
                            at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
        {z0 -optional -default {50.0 0.0} -help {Reference impedance in form of {real imag}}}
    }
    ::rfutil::compLen $zxx
    set len [llength [dget $zxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $zxx 11] $i]
        set 21 [@ [dget $zxx 21] $i]
        set 12 [@ [dget $zxx 12] $i]
        set 22 [@ [dget $zxx 22] $i]
        lappend s11 [/ [- [* [- $11 $z0] [+ $22 $z0]] [* $12 $21]] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
        lappend s12 [/ [* [* $2c $12] $z0] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
        lappend s21 [/ [* [* $2c $21] $z0] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
        lappend s22 [/ [- [* [+ $11 $z0] [- $22 $z0]] [* $12 $21]] [- [* [+ $11 $z0] [+ $22 $z0]] [* $12 $21]]]
    }
    return [dict create 11 $s11 21 $s21 12 $s12 22 $s22]
}

proc ::rfutil::y2s {args} {
    # Converts 2-port y-parameters to s-parameters.
    #
    #   yxx - Dictionary that contains 2-port matrix of y-parameters,
    #    each matrix element is the list of values at different
    #    frequencies (or other parameter) in form of {real imag}.
    #    The form of dictionary is: {11 list 12 list 21 list 22 list}
    #   z0 - Reference impedance in form of {real imag}
    # 
    # Returns dictionary of the same form as input dictionary with s-parameters
    #
    argparse -help {Converts 2-port y-parameters to s-parameters. Returns dictionary of the same form as input\
                            dictionary with s-parameters} {
        {yxx -help {Dictionary that contains 2-port matrix of y-parameters, each matrix element is the list of values\
                            at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
        {z0 -optional -default {50.0 0.0} -help {Reference impedance in form of {real imag}}}
    }
    ::rfutil::compLen $yxx
    set len [llength [dget $yxx 11]]
    set 1c [complex 1 0]
    set 2c [complex 2 0]
    set m2c [complex -2 0]
    set y0 [pow $z0 [complex -1 0]]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $yxx 11] $i]
        set 21 [@ [dget $yxx 21] $i]
        set 12 [@ [dget $yxx 12] $i]
        set 22 [@ [dget $yxx 22] $i]
        lappend s11 [/ [+ [* [- $y0 $11 ] [+ $y0 $22]] [* $12 $21]] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
        lappend s12 [/ [* [* $m2c $12] $y0] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
        lappend s21 [/ [* [* $m2c $21] $y0] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
        lappend s22 [/ [+ [* [+ $y0 $11 ] [- $y0 $22]] [* $12 $21]] [- [* [+ $y0 $11] [+ $y0 $22]] [* $12 $21]]]
    }
    return [dict create 11 $s11 21 $s21 12 $s12 22 $s22]
}

proc ::rfutil::z2y {args} {
    # Converts 2-port z-parameters to y-parameters.
    #
    #   zxx - Dictionary that contains 2-port matrix of z-parameters,
    #    each matrix element is the list of values at different
    #    frequencies (or other parameter) in form of {real imag}.
    #    The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the same form as input dictionary with y-parameters
    #
    argparse -help {Converts 2-port z-parameters to y-parameters. Returns dictionary of the same form as input\
                            dictionary with y-parameters} {
        {zxx -help {Dictionary that contains 2-port matrix of z-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $zxx
    set len [llength [dget $zxx 11]]
    set m1c [complex -1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $zxx 11] $i]
        set 21 [@ [dget $zxx 21] $i]
        set 12 [@ [dget $zxx 12] $i]
        set 22 [@ [dget $zxx 22] $i]
        lappend y11 [/ $22 [- [* $11 $22] [* $12 $21]]]
        lappend y12 [/ [* $12 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend y21 [/ [* $21 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend y22 [/ $11 [- [* $11 $22] [* $12 $21]]]
    }
    return [dict create 11 $y11 21 $y21 12 $y12 22 $y22]
}

proc ::rfutil::y2z {args} {
    # Converts 2-port y-parameters to z-parameters.
    #
    #   yxx - Dictionary that contains 2-port matrix of y-parameters,
    #    each matrix element is the list of values at different
    #    frequencies (or other parameter) in form of {real imag}.
    #    The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the same form as input dictionary with z-parameters
    #
    argparse -help {Converts 2-port y-parameters to z-parameters. Returns dictionary of the same form as input\
                            dictionary with z-parameters} {
        {yxx -help {Dictionary that contains 2-port matrix of y-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $yxx
    set len [llength [dget $yxx 11]]
    set m1c [complex -1 0]
    set 2c [complex 2 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $yxx 11] $i]
        set 21 [@ [dget $yxx 21] $i]
        set 12 [@ [dget $yxx 12] $i]
        set 22 [@ [dget $yxx 22] $i]
        lappend z11 [/ $22 [- [* $11 $22] [* $12 $21]]]
        lappend z12 [/ [* $12 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend z21 [/ [* $21 $m1c] [- [* $11 $22] [* $12 $21]]]
        lappend z22 [/ $11 [- [* $11 $22] [* $12 $21]]]
    }
    return [dict create 11 $z11 21 $z21 12 $z12 22 $z22]
}

proc ::rfutil::zTEq {args} {
    # Calculates equivalent T circuit elements values.
    # 
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the form {z1 list z2 list z3 list} with impedances of equivalent elements
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
    argparse -help {Calculates equivalent T circuit elements values. Returns dictionary of the form\
                            {z1 list z2 list z3 list} with impedances of equivalent elements} {
        {zxx -help {Dictionary that contains 2-port matrix of z-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $zxx
    set len [llength [dget $zxx 11]]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $zxx 11] $i]
        set 21 [@ [dget $zxx 21] $i]
        set 22 [@ [dget $zxx 22] $i]
        lappend z1 [- $11 $21]
        lappend z2 [- $22 $21]
        lappend z3 $21
    }
    return [dict create z1 $z1 z2 $z2 z3 $z3]
}

proc ::rfutil::cxxTEq {args} {
    # Calculates capacitive part equivalent T circuit elements values.
    #
    #  freq - Frequency values list
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the form {c1 list c2 list c3 list} with capacitive part of equivalent elements
    # impedance
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
    argparse -help {Calculates capacitive part equivalent T circuit elements values. Returns dictionary of the form\
                            {c1 list c2 list c3 list} with capacitive part of equivalent elements impedance} {
        {freq -help {List of frequency values}}
        {zxx -help {Dictionary that contains 2-port matrix of z-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen [dict merge [dict create freq $freq] $zxx]
    variable pi
    set zEq [::rfutil::zTEq $zxx]
    set 1c [complex 1 0]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [@ $freq $i]
        set z1 [@ [dget $zEq z1] $i]
        set z2 [@ [dget $zEq z2] $i]
        set z3 [@ [dget $zEq z3] $i]
        lappend c1 [= {-1/(2*$pi*$freqVal*[imag $z1])}]
        lappend c2 [= {-1/(2*$pi*$freqVal*[imag $z2])}]
        lappend c3 [= {-1/(2*$pi*$freqVal*[imag $z3])}]
    }
    return [dict create c1 $c1 c2 $c2 c3 $c3]
}

proc ::rfutil::lxxTEq {args} {
    # Calculates inductive part equivalent T circuit elements values.
    #
    #  freq - Frequency values list
    #  zxx - Dictionary that contains 2-port matrix of z-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the form {l1 list l2 list l3 list} with inductive part of equivalent elements
    # impedance
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
    argparse -help {Calculates inductive part equivalent T circuit elements values. Returns dictionary of the form\
                            {l1 list l2 list l3 list} with capacitive part of equivalent elements impedance} {
        {freq -help {List of frequency values}}
        {zxx -help {Dictionary that contains 2-port matrix of z-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen [dict merge [dict create freq $freq] $zxx]
    variable pi
    set zEq [::rfutil::zTEq $zxx]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [@ $freq $i]
        set z1 [@ [dget $zEq z1] $i]
        set z2 [@ [dget $zEq z2] $i]
        set z3 [@ [dget $zEq z3] $i]
        lappend l1 [= {[imag $z1]/(2*$pi*$freqVal)}]
        lappend l2 [= {[imag $z2]/(2*$pi*$freqVal)}]
        lappend l3 [= {[imag $z3]/(2*$pi*$freqVal)}]
    }
    return [dict create l1 $l1 l2 $l2 l3 $l3]
}

proc ::rfutil::yPEq {args} {
    # Calculates equivalent P circuit elements values.
    #
    #  yxx - Dictionary that contains 2-port matrix of y-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the form {y1 list y2 list y3 list} with impedances of equivalent elements
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
    argparse -help {Calculates equivalent P circuit elements values. Returns dictionary of the form\
                            {y1 list y2 list y3 list} with impedances of equivalent elements} {
        {yxx -help {Dictionary that contains 2-port matrix of y-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $yxx
    set len [llength [dget $yxx 11]]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set 11 [@ [dget $yxx 11] $i]
        set 21 [@ [dget $yxx 21] $i]
        set 22 [@ [dget $yxx 22] $i]
        lappend y1 [+ $11 $21]
        lappend y2 [+ $22 $21]
        lappend y3 [* $m1c $21]
    }
    return [dict create y1 $y1 y2 $y2 y3 $y3]
}

proc ::rfutil::cxxPEq {args} {
    # Calculates capacitive part equivalent P circuit elements values.
    #
    #  freq - Frequency values list
    #  yxx - Dictionary that contains 2-port matrix of y-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the form {c1 list c2 list c3 list} with capacitive part of equivalent elements
    # admittance
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
    argparse -help {Calculates capacitive part equivalent P circuit elements values. Returns dictionary of the form\
                            {c1 list c2 list c3 list} with capacitive part of equivalent elements admittance} {
        {freq -help {List of frequency values}}
        {yxx -help {Dictionary that contains 2-port matrix of y-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen [dict merge [dict create freq $freq] $yxx]
    variable pi
    set yEq [::rfutil::yPEq $yxx]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [@ $freq $i]
        set y1 [@ [dget $yEq y1] $i]
        set y2 [@ [dget $yEq y2] $i]
        set y3 [@ [dget $yEq y3] $i]
        lappend c1 [= {[imag $y1]/(2*$pi*$freqVal)}]
        lappend c2 [= {[imag $y2]/(2*$pi*$freqVal)}]
        lappend c3 [= {[imag $y3]/(2*$pi*$freqVal)}]
    }
    return [dict create c1 $c1 c2 $c2 c3 $c3]
}

proc ::rfutil::lxxPEq {args} {
    # Calculates inductive part equivalent P circuit elements values.
    #
    #  freq - Frequency values list
    #  yxx - Dictionary that contains 2-port matrix of y-parameters,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the form {l1 list l2 list l3 list} with inductive part of equivalent elements
    # impedance
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
    argparse -help {Calculates inductive part equivalent P circuit elements values. Returns dictionary of the form\
                            {l1 list l2 list l3 list} with inductive part of equivalent elements impedance} {
        {freq -help {List of frequency values}}
        {yxx -help {Dictionary that contains 2-port matrix of y-parameters, each matrix element is the list of\
                            values at different frequencies (or other parameter) in form of {real imag}. The form of\
                            dictionary is: {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen [dict merge [dict create freq $freq] $yxx]
    variable pi
    set yEq [::rfutil::yPEq $yxx]
    set len [llength $freq]
    for {set i 0} {$i<$len} {incr i} {
        set freqVal [@ $freq $i]
        set y1 [@ [dget $yEq y1] $i]
        set y2 [@ [dget $yEq y2] $i]
        set y3 [@ [dget $yEq y3] $i]
        lappend l1 [= {-1/(2*$pi*$freqVal*[imag $y1])}]
        lappend l2 [= {-1/(2*$pi*$freqVal*[imag $y2])}]
        lappend l3 [= {-1/(2*$pi*$freqVal*[imag $y3])}]
    }
    return [dict create l1 $l1 l2 $l2 l3 $l3]
}

proc ::rfutil::inv2x2 {args} {
    # Calculates inverse matrix of input matrix with size 2x2.
    #
    #  mat - Dictionary that contains 2-port matrix,
    #   each matrix element is the list of values at different
    #   frequencies (or other parameter) in form of {real imag}.
    #   The form of dictionary is: {11 list 12 list 21 list 22 list}
    # 
    # Returns dictionary of the same form as input dictionary with resulted matrix
    #
    argparse -help {Calculates inverse matrix of input matrix with size 2x2. Returns dictionary of the same form as\
                            input dictionary with resulted matrix} {
        {mat -help {Dictionary that contains 2-port matrix, each matrix element is the list of values at different\
                            frequencies (or other parameter) in form of {real imag}. The form of dictionary is:\
                            {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen $mat
    set len [llength [dget $mat 11]]
    set 1c [complex 1 0]
    set m1c [complex -1 0]
    for {set i 0} {$i<$len} {incr i} {
        set a [@ [dget $mat 11] $i]
        set b [@ [dget $mat 12] $i]
        set c [@ [dget $mat 21] $i]
        set d [@ [dget $mat 22] $i]
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

proc ::rfutil::matMul2x2 {args} {
    # Calculates multiply matrices with 2x2 size.
    #
    #  mat1 - First matrix in dictionary form {11 list 12 list 21 list 22 list}
    #  mat2 - Second matrix in dictionary form {11 list 12 list 21 list 22 list}
    #                
    # Returns dictionary of the same form as input dictionaries with resulted matrix
    #
    argparse -help {Calculates multiply matrices with 2x2 size. Returns dictionary of the same form as input\
                            dictionaries with resulted matrix} {
        {mat1 -help {First matrix in dictionary form {11 list 12 list 21 list 22 list}}}
        {mat2 -help {Second matrix in dictionary form {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen [dict merge $mat1 $mat2]
    set len1 [llength [dget $mat1 11]]
    ::rfutil::compLen $mat1
    ::rfutil::compLen $mat2
    for {set i 0} {$i<$len1} {incr i} {
        set a1 [@ [dget $mat1 11] $i]
        set b1 [@ [dget $mat1 12] $i]
        set c1 [@ [dget $mat1 21] $i]
        set d1 [@ [dget $mat1 22] $i]
        set a2 [@ [dget $mat2 11] $i]
        set b2 [@ [dget $mat2 12] $i]
        set c2 [@ [dget $mat2 21] $i]
        set d2 [@ [dget $mat2 22] $i]
        lappend 11 [+ [* $a1 $a2] [* $b1 $c2]]
        lappend 12 [+ [* $a1 $b2] [* $b1 $d2]]
        lappend 21 [+ [* $c1 $a2] [* $d1 $c2]]
        lappend 22 [+ [* $c1 $b2] [* $d1 $d2]]
    }
    return [dict create 11 $11 21 $21 12 $12 22 $22]
}

proc ::rfutil::deemb {args} {
    # Procedure for deembedding of DUT from test fixture.
    #
    #  sMeas - Measured s-parameters matrix in dictionary form {11 list 12 list 21 list 22 list}
    #  sFixtL - s-parameters matrix of left fixture in dictionary form {11 list 12 list 21 list 22 list}
    #  sFixtR - s-parameters matrix of right fixture in dictionary form {11 list 12 list 21 list 22 list}
    #                
    # Returns dictionary of the same form as input dictionaries with deembedded DUT s-matrix
    #```
    #    ┌      ┐   ┌        ┐-1   ┌       ┐     ┌        ┐-1
    #    │ Tdut │ = │ Tfixtl │  x  │ Tmeas │  x  │ Tfixtr │
    #    └      ┘   └        ┘     └       ┘     └        ┘
    #```
    argparse -help {Procedure for deembedding of DUT from test fixture. Returns dictionary of the same form as input\
                            dictionaries with deembedded DUT s-matrix} {
        {sMeas -help {Measured s-parameters matrix in dictionary form {11 list 12 list 21 list 22 list}}}
        {sFixtL -help {s-parameters matrix of left fixture in dictionary form {11 list 12 list 21 list 22 list}}}
        {sFixtR -help {s-parameters matrix of right fixture in dictionary form {11 list 12 list 21 list 22 list}}}
    }
    ::rfutil::compLen [dict merge $sMeas $sFixtL $sFixtR]
    set tMeas [s2t $sMeas]
    set tFixtL [inv2x2 [s2t $sFixtL]]
    set tFixtR [inv2x2 [s2t $sFixtR]]
    set tDut [matMul2x2 [matMul2x2 $tFixtL $tMeas] $tFixtR]
    set sDut [t2s $tDut]
    return $sDut
}

proc ::rfutil::mag {args} {
    # Calculates magnitude of complex number.
    #
    #  data - List with complex data in form {real imag}
    #  -db - Option to select output magnitude in db scale
    #                
    # Returns list of magnitudes
    #
    argparse -pfirst -help {Calculates magnitude of complex number. Returns list of magnitudes} {
        {data -help {List with complex data in form {real imag}}}
        {-db -boolean -help {Option to select output magnitude in db scale}}
    }
    set len [llength $data]
    if {$db} {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [= {20*log10([mod [@ $data $i]])}]
        }
    } else {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [mod [@ $data $i]]
        }
    }
    return $result
}

proc ::rfutil::angle {args} {
    # Calculates angle (phase) of complex number.
    #
    #  data - List with complex data in form {real imag}
    #  -deg - Option to select angle in degrees units
    #                
    # Returns list of angles
    #
    argparse -pfirst -help {Calculates angle (phase) of complex number. Returns list of angles} {
        {data -help {List with complex data in form {real imag}}}
        {-deg -boolean -help {Option to select output angle in degrees}}
    }
    variable radtodeg
    set len [llength $data]
    if {$deg} {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [= {$radtodeg*[arg [@ $data $i]]}]
        }
    } else {
        for {set i 0} {$i<$len} {incr i} {
            lappend result [arg [@ $data $i]]
        }
    }
    return $result
}
