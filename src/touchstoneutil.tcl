package require math::complexnumbers
package require math::constants
package require textutil::split

package provide touchstoneutil 0.1

namespace eval ::touchstoneutil {

    namespace import ::math::complexnumbers::*
    namespace export s2p_read
    ::math::constants::constants radtodeg degtorad pi
}

# format of s2p must be without space between # and Hz, #Hz S RI R 50

proc touchstoneutil::s2p_read {filePath} {
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
            lappend freq [lindex $lineList 0]
            lappend 11a [lindex $lineList 1]
            lappend 11b [lindex $lineList 2]
            lappend 21a [lindex $lineList 3]
            lappend 21b [lindex $lineList 4]
            lappend 12a [lindex $lineList 5]
            lappend 12b [lindex $lineList 6]
            lappend 22a [lindex $lineList 7]
            lappend 22b [lindex $lineList 8]
        }
    }
    set len [llength $freq]
    if {$format=="ri"} {
        for {set i 0} {$i<$len} {incr i} {
            lappend 11 [complex [lindex $11a $i] [lindex $11b $i]]
            lappend 21 [complex [lindex $21a $i] [lindex $21b $i]]
            lappend 12 [complex [lindex $12a $i] [lindex $12b $i]]
            lappend 22 [complex [lindex $22a $i] [lindex $22b $i]]
        }
    } elseif {$format=="db"} {
        for {set i 0} {$i<$len} {incr i} {
            set 1j [complex 0 1]
            set mag11 [expr {10.0**([lindex $11a $i]/20.0)}]
            set phRad11 [expr {$degtorad*[lindex $11b $i]}]
            set mag21 [expr {10.0**([lindex $21a $i]/20.0)}]
            set phRad21 [expr {$degtorad*[lindex $21b $i]}]
            set mag12 [expr {10.0**([lindex $12a $i]/20.0)}]
            set phRad12 [expr {$degtorad*[lindex $12b $i]}]
            set mag22 [expr {10.0**([lindex $22a $i]/20.0)}]
            set phRad22 [expr {$degtorad*[lindex $22b $i]}]
            lappend 11 [* [complex $mag11 0] [exp [* $1j [complex $phRad11 0]]]]
            lappend 21 [* [complex $mag21 0] [exp [* $1j [complex $phRad21 0]]]]
            lappend 12 [* [complex $mag12 0] [exp [* $1j [complex $phRad12 0]]]]
            lappend 22 [* [complex $mag22 0] [exp [* $1j [complex $phRad22 0]]]]
        }
    } elseif {$format=="ma"} {
        for {set i 0} {$i<$len} {incr i} {
            set 1j [complex 0 1]
            set mag11 [lindex $11a $i]
            set phRad11 [expr {$degtorad*[lindex $11b $i]}]
            set mag21 [lindex $21a $i]
            set phRad21 [expr {$degtorad*[lindex $21b $i]}]
            set mag12 [lindex $12a $i]
            set phRad12 [expr {$degtorad*[lindex $12b $i]}]
            set mag22 [lindex $22a $i]
            set phRad22 [expr {$degtorad*[lindex $22b $i]}]
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