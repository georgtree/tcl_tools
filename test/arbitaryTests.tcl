package require tcltest
namespace import ::tcltest::*
namespace import ::tcl::mathop::*
package require csv
package require argparse

set script_path [file dirname [file normalize [info script]]]
lappend auto_path "$script_path/../"
package require gnuplotutil
package require mathutil

test testMultiplotXNYN-5 {general test} -setup {
    set x1 [list 1 2 3 4 5 6]
    set y1 [list 1 4 9 16 25 36]
    set x2 [list 6 5 4 3 2 1]
    set y2 [list 36 25 16 9 4 1]
    set x3 [list 7 8 9 10]
    set y3 [list 49 64 81 100]
} -body {
    set result [gnuplotutil::multiplotXNYN {2 2} -inline -plots\
                        [list -xlog -ylog -xlabel "x label" -ylabel "y label" -grid -names [list name1 name2 name3]\
                                 -columns $x1 $y1 $x2 $y2 $x3 $y3]\
                        [list -ylabel "y label" -grid -names [list name1 name2] -columns $x1 $y1 $x2 $y2]\
                        [list -xlabel "x label" -ylabel "y label" -names [list name3] -columns $x3 $y3]\
                        [list -grid -names [list name2] -columns $x2 $y2]]
    return $result
} -result {set term x11 size 800,600 noenhanced
set multiplot layout 2,2
set key autotitle columnheader
set xlabel 'x label'
set ylabel 'y label'
set logscale x
set logscale y
set grid
plot './gnuplotTemp0.csv' using 1:2 with lines , '' using 3:4 with lines , '' using 5:6 with lines 
unset xlabel
unset ylabel
unset logscale x
unset logscale y
unset grid
set key autotitle columnheader
set ylabel 'y label'
set grid
plot './gnuplotTemp1.csv' using 1:2 with lines , '' using 3:4 with lines 
unset ylabel
unset grid
set key autotitle columnheader
set xlabel 'x label'
set ylabel 'y label'
plot './gnuplotTemp2.csv' using 1:2 with lines 
unset xlabel
unset ylabel
set key autotitle columnheader
set grid
plot './gnuplotTemp3.csv' using 1:2 with lines 
unset grid
unset multiplot
pause mouse close}

