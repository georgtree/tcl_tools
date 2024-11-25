package require math::complexnumbers
package require math::constants
package require textutil::split

package provide touchstoneutil 0.1

namespace eval ::touchstoneutil {

    namespace import ::math::complexnumbers::*
    namespace export s2p_read
    ::math::constants::constants radtodeg degtorad pi
    interp alias {} dget {} dict get
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists
}

# format of s2p must be without space between # and Hz, #Hz S RI R 50

proc ::touchstoneutil::s2p_read {filePath} {
    variable degtorad
    set infile [open $filePath r]
    set i 0
    set format ""
    while { [gets $infile line] >= 0 } {
        incr i
        if {[string match !* $line]} {
            continue
        } elseif {[string match #* $line]} {
            set paramList [textutil::split::splitx $line]
            foreach param $paramList {
                if {[string tolower $param] == "ri"} {
                    set format "ri"
                } elseif {[string tolower $param] == "db"} {
                    set format "db"
                } elseif {[string tolower $param] == "ma"} {
                    set format "ma"
                } 
            }
        } else {
            set lineList [split $line " "]
            lappend freq [@ $lineList 0]
            lappend 11a [@ $lineList 1]
            lappend 11b [@ $lineList 2]
            lappend 21a [@ $lineList 3]
            lappend 21b [@ $lineList 4]
            lappend 12a [@ $lineList 5]
            lappend 12b [@ $lineList 6]
            lappend 22a [@ $lineList 7]
            lappend 22b [@ $lineList 8]
        }
    }
    set len [llength $freq]
    if {$format=="ri"} {
        for {set i 0} {$i<$len} {incr i} {
            lappend 11 [complex [@ $11a $i] [@ $11b $i]]
            lappend 21 [complex [@ $21a $i] [@ $21b $i]]
            lappend 12 [complex [@ $12a $i] [@ $12b $i]]
            lappend 22 [complex [@ $22a $i] [@ $22b $i]]
        }
    } elseif {$format=="db"} {
        for {set i 0} {$i<$len} {incr i} {
            set 1j [complex 0 1]
            set mag11 [= {10.0**([@ $11a $i]/20.0)}]
            set phRad11 [= {$degtorad*[@ $11b $i]}]
            set mag21 [= {10.0**([@ $21a $i]/20.0)}]
            set phRad21 [= {$degtorad*[@ $21b $i]}]
            set mag12 [= {10.0**([@ $12a $i]/20.0)}]
            set phRad12 [= {$degtorad*[@ $12b $i]}]
            set mag22 [= {10.0**([@ $22a $i]/20.0)}]
            set phRad22 [= {$degtorad*[@ $22b $i]}]
            lappend 11 [* [complex $mag11 0] [exp [* $1j [complex $phRad11 0]]]]
            lappend 21 [* [complex $mag21 0] [exp [* $1j [complex $phRad21 0]]]]
            lappend 12 [* [complex $mag12 0] [exp [* $1j [complex $phRad12 0]]]]
            lappend 22 [* [complex $mag22 0] [exp [* $1j [complex $phRad22 0]]]]
        }
    } elseif {$format=="ma"} {
        for {set i 0} {$i<$len} {incr i} {
            set 1j [complex 0 1]
            set mag11 [@ $11a $i]
            set phRad11 [= {$degtorad*[@ $11b $i]}]
            set mag21 [@ $21a $i]
            set phRad21 [= {$degtorad*[@ $21b $i]}]
            set mag12 [@ $12a $i]
            set phRad12 [= {$degtorad*[@ $12b $i]}]
            set mag22 [@ $22a $i]
            set phRad22 [= {$degtorad*[@ $22b $i]}]
            lappend 11 [* [complex $mag11 0] [exp [* $1j [complex $phRad11 0]]]]
            lappend 21 [* [complex $mag21 0] [exp [* $1j [complex $phRad21 0]]]]
            lappend 12 [* [complex $mag12 0] [exp [* $1j [complex $phRad12 0]]]]
            lappend 22 [* [complex $mag22 0] [exp [* $1j [complex $phRad22 0]]]]
        }
    } else {
        error {Format of the file is not ri, db or ma}
    }
    return [dict create freq $freq 11 $11 21 $21 12 $12 22 $22]
}
