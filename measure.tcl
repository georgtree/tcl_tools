package require argparse
package provide measure 0.1

namespace eval ::measure {

    namespace import ::tcl::mathop::*
    namespace export measure
    interp alias {} dget {} dict get
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists
    interp alias {} dcreate {} dict create
}

proc ::measure::AliasesKeysCheck {arguments keys} {
    foreach key $keys {
        if {[dexist $arguments $key]} {
            return $key
        }
    }
    set formKeys [lmap key $keys {subst -$key}]
    return -code error "[join [lrange $formKeys 0 end-1] ", "] or [@ $formKeys end] must be presented"
}

proc ::measure::Allow {names keysList} {
    foreach name $names {
        lappend indexes [lsearch -exact $keysList $name]
    }
    return [lremove $keysList {*}$indexes]
}

proc ::measure::measure {args} {
    # Does different measurements of inpu data lists.
    #  -xname - name of x list in data dictionary. This list must be strictly increaing without duplicate elements.
    #  -data - dictionary that contains lists with names as the keys and lists as the values.
    #  -trig - contains conditions for trigger (see below), selects Trigger-Target measurement, requires -targ
    #  -targ - contains conditions for target (see below), requires -trig
    #  -find - contains conditions for find (see below)
    #  -when - contains conditions for when (see below)
    #  -at - time for find
    # This procedure imitates the .meas command from SPICE3 and Ngspice in particular. It has mutiple modes, and each mod
    #  could have different forms:
    #  ###### **Trigger-Target**
    #  In this mode it measures the difference in x list between two points selected from one or two input lists 
    #  (vectors). First it searches for the trigger point along x list (vector) with certain value of input list,
    #  or certain x axis value, second it searches for the target point with with certain value of input list, or 
    #  certain x axis value, and finally calculates difference between trigger and target point along x axis.
    #  The conditions for trigger and target could be in two forms: hit of certain value by specified vector, or 
    #  certain exact point on x axis. These conditions are provided as a list of arguments to -trig and -targ switches:
    #   -vec - name of vector in data dictionary
    #   -val - value to match
    #   -td - x axis delay after which the search is start, default is 0.0.
    #   -cross - condition's count, cross conditions counts every time vector crosses value, and saves
    #     only n-th crossing the value. The possible values are positive integers, or `last` string.
    #   -rise - condition's count, rise conditions counts every time vector crosses value from lower to higher
    #     (rising slope), and saves only n-th crossing the value. The possible values are positive integers, or `last` 
    #     string.
    #   -fall - condition's count, fall conditions counts every time vector crosses value from higher to lower
    #     (falling slope), and saves only n-th crossing the value. The possible values are positive integers, or `last` 
    #     string.
    #
    #  or
    #
    #   -at - exact x value
    #
    # Examples of usages:
    # ```
    # ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -trig {-vec y1 -val 0.1 -rise 3} -targ {-vec y2 -val 0.5 -fall 5}
    # ```
    # Here we use x key value as x axis, trigger vector point is when y1 crosses value 0.1, third rise, and target 
    # vector point is when y2 crosses value 0.5, fifth fall.
    # ```
    # ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -trig {-vec y1 -val 0.7 -rise 2} -targ {-at 20.0}
    # ```
    # Here we use x key value as x axis, trigger vector point is when y1 crosses value 0.7, second rise, and target point 
    # is value 20.0 at x axis.
    # 
    # In this mode procedure returns dictionary with keys `xtrig`, `xtarg`, `xdelta` and corresponding values.
    # Synopsis: -xname value -data value -trig \{-vec value -val value ?-td value? -cross|rise|fall value\}
    #   -targ \{-vec value -val value ?-td value? -cross|rise|fall value\}
    # Synopsis: -xname value -data value -trig \{-at value\} -targ \{-vec value -val value ?-td value? -cross|rise|fall value\}
    # Synopsis: -xname value -data value -trig \{-vec value -val value ?-td value? -cross|rise|fall value\} -targ \{-at value\}
    #
    #  ###### **Find-When**
    #  In this mode it measures any vector, when two signals cross each other or a signal crosses a given value. 
    #  Measurements start after a delay `-td` and may be restricted to a range between `-from` and `-to`. Possible
    #  combinations of switches are `-when {...}` or `-find {...} -when {...}`. For `-when` the possible switches are:
    #   -vec - name of vector in data dictionary
    #   -val - value to match
    #   -td - x axis delay after which the search is start, default is 0.0.
    #   -from - start of the range in which search happens, default is 0.0.
    #   -to - end of the range in which search happens, optional
    #   -cross - condition's count, cross conditions counts every time vector crosses value, and saves
    #     only n-th crossing the value. The possible values are positive integers, or `last` string.
    #   -rise - condition's count, rise conditions counts every time vector crosses value from lower to higher
    #     (rising slope), and saves only n-th crossing the value. The possible values are positive integers, or `last` 
    #     string.
    #   -fall - condition's count, fall conditions counts every time vector crosses value from higher to lower
    #     (falling slope), and saves only n-th crossing the value. The possible values are positive integers, or `last` 
    #     string.
    #
    #  or
    #
    #   -vec1 - name of first vector in data dictionary
    #   -vec2 - name of second vector in data dictionary
    #   -td - x axis delay after which the search is start, default is 0.0.
    #   -from - start of the range in which search happens, default is 0.0.
    #   -to - end of the range in which search happens, optional
    #   -cross - condition's count, cross conditions counts every time `-vec1` vector crosses value, and saves
    #     only n-th crossing the value. The possible values are positive integers, or `last` string.
    #   -rise - condition's count, rise conditions counts every time `-vec1` vector crosses value from lower to higher
    #     (rising slope), and saves only n-th crossing the value. The possible values are positive integers, or `last` 
    #     string.
    #   -fall - condition's count, fall conditions counts every time `-vec1` vector crosses value from higher to lower
    #     (falling slope), and saves only n-th crossing the value. The possible values are positive integers, or `last` 
    #     string.
    #
    #  For `-find` we specify the vector name in data dictionary for which values should be found at `when` point.
    # Examples of usages:
    # ```
    # ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -find y1 -when {-vec y2 -val 0.5 -fall 5}
    # ```
    # Here we use x key value as x axis, find vector is y1, and point is when vector y2 crosses value 0.5, fifth fall.
    # ```
    # ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -find y1 -when {-vec1 y1 -vec2 y2 -fall 5}
    # ```
    # Here we use x key value as x axis, find vector is y1, and point is when vector y1 crosses y2, fifth fall of y1 
    # vector.
    # ```
    # ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -when {-vec1 y1 -vec2 y2 -fall last -from 1 -to 30}
    # ```
    # Here we use x key value as x axis, point is when vector y1 crosses y2, last fall of y1 vector, searching range is 
    # [1,30].
    # In this mode procedure returns dictionary with keys `xwhen`, and `yfind` if `-find` switch is specified, and 
    # corresponding values.
    # Synopsis: -xname value -data value ?-find value? -when \{-vec value -val value ?-td value? ?-from value? 
    #   ?-to value? -cross|rise|fall value\}
    # Synopsis: -xname value -data value ?-find value? -when \{-vec1 value -vec2 value ?-td value? ?-from value? 
    #   ?-to value? -cross|rise|fall value\}
    #  ###### **Find-At**
    #  In this mode it finds value of the vector at specified time.
    # Examples of usages:
    # ```
    # ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -find y1 -at 5
    # ```
    # Synopsis: -xname value -data value -find value -at value
    set keysList {trig targ find when at integ deriv avg min max pp rms minat maxat}
    argparse "
        {-xname= -required}
        {-data= -required}
        \{-trig= -require targ -forbid \{[Allow {trig targ} $keysList]\}\}
        \{-targ= -require trig -forbid \{[Allow {trig targ} $keysList]\}\}
        \{-find= -forbid \{[Allow {find when at} $keysList]\}\}
        \{-when= -forbid \{[Allow {find when} $keysList]\}\}
        \{-at= -require find -validate {\[string is double \$arg\]} -forbid \{[Allow {find at} $keysList]\}\}
        \{-integ= -forbid \{[Allow integ $keysList]\}\}
        \{-deriv= -forbid \{[Allow deriv $keysList]\}\}
        \{-avg= -forbid \{[Allow avg $keysList]\}\}
        \{-min= -forbid \{[Allow min $keysList]\}\}
        \{-max= -forbid \{[Allow max $keysList]\}\}
        \{-pp= -forbid \{[Allow pp $keysList]\}\}
        \{-rms= -forbid \{[Allow rms $keysList]\}\}
        \{-minat= -forbid \{[Allow minat $keysList]\}\}
        \{-maxat= -forbid \{[Allow maxat $keysList]\}\}"
    if {[info exists trig]} {
        set definition {
            {-at= -forbid {vec val delay cross rise fall} -validate {[string is double $arg]}}
            {-vec= -forbid at -require val}
            {-val= -forbid at -validate {[string is double $arg]}}
            {-td|delay= -default 0.0 -forbid at -require {vec val} -validate {[string is double $arg]}}
            {-cross= -forbid {rise fall} -forbid at -require {vec val}}
            {-rise= -forbid {cross fall} -forbid at -require {vec val}}
            {-fall= -forbid {cross rise} -forbid at -require {vec val}}
        }
        set trigArgs [argparse -inline $definition $trig]
        set targArgs [argparse -inline $definition $targ]
        AliasesKeysCheck $trigArgs {at vec}
        AliasesKeysCheck $targArgs {at vec}
        if {![dexist $trigArgs at]} {
            set trigVecCond [AliasesKeysCheck $trigArgs {cross rise fall}]
            set trigVecCondCount [dget $trigArgs $trigVecCond]
            if {[string is integer $trigVecCondCount]} {
                if {$trigVecCondCount<=0} {
                    return -code error "Trig count '$trigVecCondCount' must be more than 0"
                }
            } elseif {$trigVecCondCount ne {last}} {
                return -code error "Trig count '$trigVecCondCount' must be an integer or 'last' string"
            }
            set trigData [dget $data [dget $trigArgs vec]]
            set trigVal [dget $trigArgs val]
        } else {
            set trigVecCond rise
            set trigVecCondCount 1
            set trigData [dget $data $xname]
            set trigVal [dget $trigArgs at]
        }
        if {![dexist $targArgs at]} {
            set targVecCond [AliasesKeysCheck $targArgs {cross rise fall}]
            set targVecCondCount [dget $targArgs $targVecCond]
            if {[string is integer $targVecCondCount]} {
                if {$targVecCondCount<=0} {
                    return -code error "Targ count '$targVecCondCount' must be more than 0"
                }
            } elseif {$targVecCondCount ne {last}} {
                return -code error "Targ count '$targVecCondCount' must be an integer or 'last' string"
            }
            set targData [dget $data [dget $targArgs vec]]
            set targVal [dget $targArgs val]
        } else {
            set targVecCond rise
            set targVecCondCount 1
            set targData [dget $data $xname]
            set targVal [dget $targArgs at]
        }
        return [TrigTarg [dget $data $xname] $trigData $trigVal $targData $targVal $trigVecCond\
                        $trigVecCondCount $targVecCond $targVecCondCount [dget $trigArgs delay] [dget $targArgs delay]]
    } elseif {[info exists find] && [info exists when]} {
        set whenArgs [argparse -inline {
            {-vec= -require val -forbid {vec1 vec2}}
            {-val= -require vec -forbid {vec1 vec2}}
            {-vec1= -require vec2 -forbid {vec val}}
            {-vec2= -require vec1 -forbid {vec val}}
            {-td|delay= -default 0.0 -validate {[string is double $arg]}}
            {-from= -default 0.0 -validate {[string is double $arg]}}
            {-to= -validate {[string is double $arg]}}
            {-cross= -forbid {rise fall}}
            {-rise= -forbid {cross fall}}
            {-fall= -forbid {cross rise}}
        } $when]
        AliasesKeysCheck $whenArgs {vec vec1}
        set whenVecCond [AliasesKeysCheck $whenArgs {cross rise fall}]
        if {[string is integer [dget $whenArgs $whenVecCond]]} {
            if {[dget $whenArgs $whenVecCond]<=0} {
                return -code error "Trig count '[dget $whenArgs $whenVecCond]' must be more than 0"
            }
        } elseif {[dget $whenArgs $whenVecCond] ne {last}} {
            return -code error "Trig count '[dget $whenArgs $whenVecCond]' must be an integer or 'last' string"
        }
        if {![dexist $whenArgs to]} {
            set to [@ [dget $data $xname] end]
        } else {
            set to [dget $whenArgs to]
        }
        if {[dexist $whenArgs vec1]} {
            if {[dget $whenArgs vec1] eq [dget $whenArgs vec2]} {
                return -code error "vec1 must be different to vec2"
            }
            return [FindWhen [dget $data $xname] findwheneq [dget $data $find]\
                            [dget $data [dget $whenArgs vec1]] {} [dget $data [dget $whenArgs vec2]] $whenVecCond\
                            [dget $whenArgs $whenVecCond] [dget $whenArgs delay] [dget $whenArgs from] $to]
        } else {
            return [FindWhen [dget $data $xname] findwhen [dget $data $find]\
                            [dget $data [dget $whenArgs vec]] [dget $whenArgs val] {} $whenVecCond\
                            [dget $whenArgs $whenVecCond] [dget $whenArgs delay] [dget $whenArgs from] $to]
        }
    } elseif {[info exists when]} {
        set whenArgs [argparse -inline {
            {-vec= -require val -forbid {vec1 vec2}}
            {-val= -require vec -forbid {vec1 vec2}}
            {-vec1= -require vec2 -forbid {vec val}}
            {-vec2= -require vec1 -forbid {vec val}}
            {-td|delay= -default 0.0 -validate {[string is double $arg]}}
            {-from= -default 0.0 -validate {[string is double $arg]}}
            {-to= -validate {[string is double $arg]}}
            {-cross= -forbid {rise fall}}
            {-rise= -forbid {cross fall}}
            {-fall= -forbid {cross rise}}
        } $when]
        AliasesKeysCheck $whenArgs {vec vec1}
        set whenVecCond [AliasesKeysCheck $whenArgs {cross rise fall}]
        if {[string is integer [dget $whenArgs $whenVecCond]]} {
            if {[dget $whenArgs $whenVecCond]<=0} {
                return -code error "Trig count '[dget $whenArgs $whenVecCond]' must be more than 0"
            }
        } elseif {[dget $whenArgs $whenVecCond] ne {last}} {
            return -code error "Trig count '[dget $whenArgs $whenVecCond]' must be an integer or 'last' string"
        }
        if {![dexist $whenArgs to]} {
            set to [@ [dget $data $xname] end]
        } else {
            set to [dget $whenArgs to]
        }
        if {[dexist $whenArgs vec1]} {
            return [FindWhen [dget $data $xname] wheneq {} [dget $data [dget $whenArgs vec1]] {}\
                            [dget $data [dget $whenArgs vec2]] $whenVecCond [dget $whenArgs $whenVecCond]\
                            [dget $whenArgs delay] [dget $whenArgs from] $to]
        } else {
            return [FindWhen [dget $data $xname] when {} [dget $data [dget $whenArgs vec]]\
                            [dget $whenArgs val] {} $whenVecCond [dget $whenArgs $whenVecCond] [dget $whenArgs delay]\
                            [dget $whenArgs from] $to]
        }
    } elseif {[info exists at]} {
        return [FindAt [dget $data $xname] $at [dget $data $find]]
    } elseif {[info exists integ]} {
        set integArgs [argparse -inline {
            {-vec= -required}
            {-from= -default 0.0 -validate {[string is double $arg]}}
            {-to= -validate {[string is double $arg]}}
         } $integ]
        if {![dexist $integArgs to]} {
            set to [@ [dget $data $xname] end]
        } else {
            set to [dget $integArgs to]
        }
        return [Integ [dget $data $xname] [dget $data [dget $integArgs vec]] [dget $integArgs from] $to]
    }
}

proc ::measure::TrigTarg {x trigVec val1 targVec val2 trigVecCond trigVecCondCount targVecCond targVecCondCount\
                                  trigVecDelay targVecDelay} {
    set xLen [llength $x]
    set trigVecLen [llength $trigVec]
    set targVecLen [llength $targVec]
    if {$xLen != $trigVecLen} {
        return -code error "Length of x '$xLen' is not equal to length of trigVec '$trigVecLen'"
    } elseif {$trigVecLen != $targVecLen} {
        return -code error "Length of trigVec '$trigVecLen' is not equal to length of targVec '$targVecLen'"
    }
    set trigVecCount 0
    set targVecCount 0
    set trigVecFoundFlag false
    set targVecFoundFlag false
    for {set i 0} {$i<[= {$trigVecLen-1}]} {incr i} {
        set xi [@ $x $i]
        if {($xi<$trigVecDelay) && ($xi<$targVecDelay)} {
            continue
        }
        set xip1 [@ $x [= {$i+1}]]
        set trigVecI [@ $trigVec $i]
        set trigVecIp1 [@ $trigVec [= {$i+1}]]
        set targVecI [@ $targVec $i]
        set targVecIp1 [@ $targVec [= {$i+1}]]
        if {!$trigVecFoundFlag && ($xi>=$trigVecDelay)} {
            switch $trigVecCond {
                rise {
                    if {($trigVecI<=$val1) && ($trigVecIp1>=$val1)} {
                        set result true
                    } else {
                        set result false
                    }
                }
                fall {
                    if {($trigVecI>=$val1) && ($trigVecIp1<=$val1)} {
                        set result true
                    } else {
                        set result false
                    }
                }
                cross {
                    if {(($trigVecI<=$val1) && ($trigVecIp1>=$val1)) || (($trigVecI>=$val1) && ($trigVecIp1<=$val1))} {
                        set result true
                    } else {
                        set result false
                    }
                }
            }
            if {$result} {
                incr trigVecCount
                if {$trigVecCondCount eq {last}} {
                    set lastTrigHit [list $xi $trigVecI $xip1 $trigVecIp1]
                }
            }
        }
        if {!$targVecFoundFlag  && ($xi>=$targVecDelay)} {
            switch $targVecCond {
                rise {
                    if {($targVecI<=$val2) && ($targVecIp1>=$val2)} {
                        set result true
                    } else {
                        set result false
                    }
                }
                fall {
                    if {($targVecI>=$val2) && ($targVecIp1<=$val2)} {
                        set result true
                    } else {
                        set result false
                    }
                }
                cross {
                    if {(($targVecI<=$val2) && ($targVecIp1>=$val2)) || (($targVecI>=$val2) && ($targVecIp1<=$val2))} {
                        set result true
                    } else {
                        set result false
                    }
                }
            }
            if {$result} {
                incr targVecCount
                if {$targVecCondCount eq {last}} {
                    set lastTargHit [list $xi $targVecI $xip1 $targVecIp1]
                }
            }
        }
        if {$trigVecCondCount ne {last}} {
            if {($trigVecCount==$trigVecCondCount) && !$trigVecFoundFlag} {
                set trigVecFoundFlag true
                set xTrig [CalcXBetween $xi $trigVecI $xip1 $trigVecIp1 $val1]
            }
        }
        if {$targVecCondCount ne {last}} {
            if {($targVecCount==$targVecCondCount) && !$targVecFoundFlag} {
                set targVecFoundFlag true
                set xTarg [CalcXBetween $xi $targVecI $xip1 $targVecIp1 $val2]
            }
        }
        if {$trigVecFoundFlag && $targVecFoundFlag} {
            break
        }
    }
    if {($trigVecCondCount eq {last}) && [info exists lastTrigHit]} {
        set trigVecFoundFlag true
        set xTrig [CalcXBetween {*}$lastTrigHit $val1]
    }
    if {($targVecCondCount eq {last}) && [info exists lastTargHit]} {
        set targVecFoundFlag true
        set xTarg [CalcXBetween {*}$lastTargHit $val1]
    }
    if {!$trigVecFoundFlag} {
        return -code error "Trig value '$val1' with conditions '$trigVecCond $trigVecCondCount delay=$trigVecDelay' was\
                not found"
    } elseif {!$targVecFoundFlag} {
        return -code error "Targ value '$val2' with conditions '$targVecCond $targVecCondCount delay=$trigVecDelay' was\
                not found"
    }
    return [dcreate xtrig $xTrig xtarg $xTarg xdelta [= {$xTarg-$xTrig}]]
}

proc ::measure::FindWhen {x mode findVec whenVecLS val whenVecRS whenVecCond whenVecCondCount delay from to} {
    if {$mode ni {find when wheneq findwhen findwheneq}} {
        return -code error "Mode with name '$mode' in not in the list of supported modes"
    }
    set xLen [llength $x]
    set findVecLen [llength $findVec]
    set whenVecLSLen [llength $whenVecLS]
    set whenVecRSLen [llength $whenVecRS]
    if {$mode in {when wheneq findwhen findwheneq}} {
        if {$xLen != $whenVecLSLen} {
            return -code error "Length of x '$xLen' is not equal to length of whenVecLS '$whenVecLSLen'"
        }
    }
    if {$mode in {wheneq findwheneq}} {
        if {$xLen != $whenVecRSLen} {
            return -code error "Length of x '$xLen' is not equal to length of whenVecRS '$whenVecRSLen'"
        }
    }
    if {$mode in {find findwhen}} {
        if {$xLen != $whenVecLSLen} {
            return -code error "Length of x '$xLen' is not equal to length of findVec '$findVecLen'"
        }
    }
    set procsDict [dcreate rise CheckRise fall CheckFall cross CheckCross]
    set procsDictEq [dcreate rise {::tcl::mathop::<=} fall {::tcl::mathop::>=} cross no-op]
    set whenVecProc [dget $procsDict $whenVecCond]
    set whenVecCount 0
    set whenVecFoundFlag false
    if {$mode in {when findwhen}} {
        for {set i 0} {$i<[= {$whenVecLSLen-1}]} {incr i} {
            set xi [@ $x $i]
            if {($xi<$delay) || ($xi<$from) || ($xi>$to)} {
                continue
            }
            set xip1 [@ $x [= {$i+1}]]
            set whenVecLSI [@ $whenVecLS $i]
            set whenVecLSIp1 [@ $whenVecLS [= {$i+1}]]
            if {!$whenVecFoundFlag} {
                switch $whenVecCond {
                    rise {
                        if {($whenVecLSI<=$val) && ($whenVecLSIp1>=$val)} {
                            set result true
                        } else {
                            set result false
                        }
                    }
                    fall {
                        if {($whenVecLSI>=$val) && ($whenVecLSIp1<=$val)} {
                            set result true
                        } else {
                            set result false
                        }
                    }
                    cross {
                        if {(($whenVecLSI<=$val) && ($whenVecLSIp1>=$val)) ||\
                                    (($whenVecLSI>=$val) && ($whenVecLSIp1<=$val))} {
                            set result true
                        } else {
                            set result false
                        }
                    }
                }
                if {$result} {
                    incr whenVecCount
                    if {$whenVecCondCount eq {last}} {
                        set lastWhenHit [list $xi $whenVecLSI $xip1 $whenVecLSIp1]
                        if {$mode eq {findwhen}} {
                            set lastFindWhenHit [list $xi [@ $findVec $i] $xip1 [@ $findVec [= {$i+1}]]]
                        }
                    }
                }
            }
            if {$whenVecCondCount ne {last}} {
                if {($whenVecCount==$whenVecCondCount) && !$whenVecFoundFlag} {
                    set whenVecFoundFlag true
                    set xWhen [CalcXBetween $xi $whenVecLSI $xip1 $whenVecLSIp1 $val]
                    if {$mode eq {findwhen}} {
                        set yFind [CalcYBetween $xi [@ $findVec $i] $xip1 [@ $findVec [= {$i+1}]] $xWhen]
                    }
                    break
                }
            }
        }
    } elseif {$mode in {wheneq findwheneq}} {
        set whenVecProc [dget $procsDictEq $whenVecCond]
        for {set i 0} {$i<[= {$whenVecLSLen-1}]} {incr i} {
            set xi [@ $x $i]
            if {($xi<$delay) || ($xi<$from) || ($xi>$to)} {
                continue
            }
            set xip1 [@ $x [= {$i+1}]]
            set whenVecLSI [@ $whenVecLS $i]
            set whenVecLSIp1 [@ $whenVecLS [= {$i+1}]]
            set whenVecRSI [@ $whenVecRS $i]
            set whenVecRSIp1 [@ $whenVecRS [= {$i+1}]]
            if {!$whenVecFoundFlag} {
                # check two lines crossing
                if {(($whenVecLSI>=$whenVecRSI) && ($whenVecLSIp1<=$whenVecRSIp1)) ||\
                            (($whenVecLSI<=$whenVecRSI) && ($whenVecLSIp1>=$whenVecRSIp1))} {
                    switch $whenVecCond {
                        rise {
                            if {$whenVecLSI<$whenVecLSIp1} {
                                set result true
                            } else {
                                set result false
                            }
                        }
                        fall {
                            if {$whenVecLSI>$whenVecLSIp1} {
                                set result true
                            } else {
                                set result false
                            }
                        }
                        cross {
                            set result true
                        }
                    }
                    if {$result} {
                        incr whenVecCount
                        if {$whenVecCondCount eq {last}} {
                            set lastWhenHit [list $xi $whenVecLSI $xip1 $whenVecLSIp1 $xi $whenVecRSI $xip1\
                                                     $whenVecRSIp1]
                            if {$mode eq {findwheneq}} {
                                set lastFindWhenHit [list $xi [@ $findVec $i] $xip1 [@ $findVec [= {$i+1}]]]
                            }
                        }
                    }
                }
            }
            if {$whenVecCondCount ne {last}} {
                if {($whenVecCount==$whenVecCondCount) && !$whenVecFoundFlag} {
                    set whenVecFoundFlag true
                    set xWhen [@ [CalcCrossPoint $xi $whenVecLSI $xip1 $whenVecLSIp1 $xi $whenVecRSI\
                                          $xip1 $whenVecRSIp1] 0]
                    if {$mode eq {findwheneq}} {
                        set yFind [CalcYBetween $xi [@ $findVec $i] $xip1 [@ $findVec [= {$i+1}]] $xWhen]
                    }
                    break
                }
            }
        }
    }
    if {($whenVecCondCount eq {last}) && [info exists lastWhenHit]} {
        set whenVecFoundFlag true
        if {$mode in {when findwhen}} {
            set xWhen [CalcXBetween {*}$lastWhenHit $val]
            if {$mode in {findwhen}} {
                set yFind [CalcYBetween {*}$lastFindWhenHit $xWhen]
            }
        }
        if {$mode in {wheneq findwheneq}} {
            set xWhen [@ [CalcCrossPoint {*}$lastWhenHit] 0]
            if {$mode in {findwhen}} {
                set yFind [CalcYBetween {*}$lastFindWhenHit $xWhen]
            }
        }
    }
    if {($mode in {when findwhen}) && ![info exists xWhen]} {
        return -code error "When value '$val' with conditions '$whenVecCond $whenVecCondCount delay=$delay from=$from\
                to=$to' was not found"
    } elseif {($mode in {wheneq findwheneq}) && ![info exists xWhen]} {
        return -code error "Cross between vectors with conditions '$whenVecCond $whenVecCondCount delay=$delay\
                from=$from to=$to' was not found"
    }
    if {$mode in {when wheneq}} {
        return [dcreate xwhen $xWhen]
    } elseif {$mode in {findwhen findwheneq}} {
        return [dcreate xwhen $xWhen yfind $yFind]
    }
}

proc ::measure::FindAt {x val findVec} {
    set xLen [llength $x]
    set findVecLen [llength $findVec]
    if {$xLen != $findVecLen} {
        return -code error "Length of x '$xLen' is not equal to length of findVec '$findVec'"
    }
    for {set i 0} {$i<[= {$xLen-1}]} {incr i} {
        set xi [@ $x $i]
        set xip1 [@ $x [= {$i+1}]]
        set findVecLSI [@ $findVec $i]
        set findVecLSIp1 [@ $findVec [= {$i+1}]]
        if {($xi<=$val) && ($xip1>=$val)} {
            set yFind [CalcYBetween $xi $findVecLSI $xip1 $findVecLSIp1 $val]
            break
        }
    }
    return $yFind
}

proc ::measure::Integ {x y xstart xend} {
    set xLen [llength $x]
    set yLen [llength $y]
    if {$xLen != $yLen} {
        return -code error "Length of x '$xLen' is not equal to length of y '$yLen'"
    }
    if {$xstart<[@ $x 0]} {
        return -code error "Start of integration interval '$xstart' is outside the x values range"
    } elseif {$xend>[@ $x end]} {
        return -code error "End of integration interval '$xend' is outside the x values range"
    } elseif {$xstart>=$xend} {
        return -code error "Start of the integration should be lower than the end of the integration"
    }
    set result 0.0
    set startFlagFound false
    set endFlagFound false
    for {set i 0} {$i<[= {$xLen-1}]} {incr i} {
        set xi [@ $x $i]
        set xip1 [@ $x [= {$i+1}]]
        set yi [@ $y $i]
        set yip1 [@ $y [= {$i+1}]]
        if {($xi<=$xstart) && ($xip1>=$xstart) && !$startFlagFound} {
            set ystart [CalcYBetween $xi $yi $xip1 $yip1 $xstart]
            set istart $i
            set startFlagFound true
        } elseif {($xi<=$xend) && ($xip1>=$xend) && !$endFlagFound} {
            set yend [CalcYBetween $xi $yi $xip1 $yip1 $xend]
            set iend $i
            set endFlagFound true
        }
        if {$startFlagFound} {
            if {$i==$istart} {
                set xi $xstart
                set yi $ystart
            } elseif {$endFlagFound} {
                if {$i==$iend} {
                    set xip1 $xend
                    set yip1 $yend
                }
            }
            set result [= {$result+($yip1+$yi)/2.0*($xip1-$xi)}]
        }
    }
    return $result
}

proc ::measure::CalcXBetween {x1 y1 x2 y2 yBetween} {
    return [= {($yBetween-$y1)*($x2-$x1)/($y2-$y1)+$x1}]
}
proc ::measure::CalcYBetween {x1 y1 x2 y2 xBetween} {
    return [= {($y2-$y1)/($x2-$x1)*($xBetween-$x1)+$y1}]
}
proc ::measure::CalcCrossPoint {x11 y11 x21 y21 x12 y12 x22 y22} {
    set a1 [= {($y21-$y11)/($x21-$x11)}]
    set b1 [= {$y11-$a1*$x11}]
    set a2 [= {($y22-$y12)/($x22-$x12)}]
    set b2 [= {$y12-$a2*$x12}]
    set x0 [= {($b2-$b1)/($a1-$a2)}]
    set y0 [= {$a1*($b2-$b1)/($a1-$a2)+$b1}]
    return [list $x0 $y0]
}
