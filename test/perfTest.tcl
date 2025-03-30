package require mathutil
namespace import ::mathutil::*
namespace import ::tcl::mathop::*
package require measure

for {set i 0} {$i<=1000000} {incr i} {
    set xi [= {$i*0.00005}]
    lappend x $xi
    lappend y1 [= {sin($xi)}]
    lappend y2 [= {cos($xi)}]
}
puts [time {
        ::measure::measure -xname x -data [dcreate x $x y1 $y1 y2 $y2] -trig {-vec y1 -val 0.1 -rise 3}\
                  -targ {-vec y2 -val 0.5 -fall 5}
    } 1]

