set script_path [file dirname [file normalize [info script]]]
lappend auto_path "$script_path/../"
package require gnuplotutil


set x1 [list 1 2 3 4 5 6]
set y1 [list 1 4 9 16 25 36]
set x2 [list 6 5 4 3 2 1]
set y2 [list 36 25 16 9 4 1]
set x3 [list 7 8 9 10]
set y3 [list 49 64 81 100]

        
#set plot1 [list -xlog -ylog -xlabel "x label" -ylabel "y label" -grid -names [list name1 name2 name3] -columns $x1 $y1 $x2 $y2 $x3 $y3]
#set plot2 [list -ylabel "y label" -grid -names [list name1 name2] -columns $x1 $y1 $x2 $y2 ]
#set plot3 [list -xlabel "x label" -ylabel "y label" -names [list name3] -columns $x3 $y3 ]
#set plot4 [list -grid -names [list name2] -columns $x2 $y2 ]
#gnuplotutil::multiplotXNYN {2 2} -plots $plot1 $plot2 $plot3 $plot4

gnuplotutil::plotHist $x1 -xlabel "x label" -ylabel "y label" -names [list  y1 y2] -columns $y1 $y2