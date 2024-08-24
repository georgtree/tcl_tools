package require csv
package require argparse

namespace eval ::gnuplotutil {

    namespace export plotXYN plotXNYN
}


# plotXYN --
#    Procedure create input and command files to plot 2D graphs with the same x points, and send it to gnuplot
#
# Arguments:
#    x           List that contains x-point for 2D graph

#    args        Arguments for procedure:
# 				 1. -xlog : boolean switch of log scale of x axis, default off
# 				 2. -ylog : boolean switch of log scale of y axis, default off
# 				 3. -delete : boolean switch that enables deleting of temporary file after end of plotting, default off
# 				 4. -xlabel : argument to set x-axis label to display, string must be provided after it
# 				 5. -ylabel : argument to set y-axis label to display, string must be provided after it
# 				 6. -optcmd : argument with optional string that may contain additional commands to gnuplot
# 				 7. -grid : boolean switch that enables display of grid, default off
# 				 8. -names : argument that enable setting the column names of provided data, value must be provided as list
#                            in the same order as data columns provided, must have the length 1+number of y data colums
# 				 9. -columns : argument that provides the y data to plot, the number of columns is not restricted and must be provided
#                              at the end of command after all switches
# Result:
#    Gnuplot window with plotted data
#
# Example:
#    set x [list 0 1 2 3 4 5 6]
#    set y1 [list 0 1 4 9 16 25 36]
#    set y2 [list 0 1 8 27 64 125 216]
#    gnuplotutil::plotXYN $x -xlog -ylog -xlabel "x label" -ylabel "y label" -delete -grid -names [list y1 y2] -columns $y1 $y2
#
proc gnuplotutil::plotXYN {x args} {
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-delete -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-optcmd -argument}
        {-grid -boolean}
        {-names -argument}
        {-columns -catchall}
    }]
    set xscaleStr ""
    set yscaleStr ""
    set xlabelStr ""
    set ylabelStr ""
    set gridStr ""
    set autoTitleStr ""
    set optcmdStr ""
    if {[dict get $arguments xlog]==1} {
        set xscaleStr "set logscale x"
    }
    if {[dict get $arguments ylog]==1} {
        set yscaleStr "set logscale y"
    }
    if {[dict get $arguments grid]==1} {
        set gridStr "set grid"
    }
    if {[dict exist $arguments names]==1} {
        set columnNames [dict get $arguments names]
    }
    if {[dict exist $arguments xlabel]==1} {
        set xlabelStr "set xlabel '[dict get $arguments xlabel]'"
    }
    if {[dict exist $arguments ylabel]==1} {
        set ylabelStr "set ylabel '[dict get $arguments ylabel]'"
    }
    if {[dict exist $arguments optcmd]==1} {
        set optcmdStr [dict get $arguments optcmd]
    }
    set yColumnCount 0
    foreach val [dict get $arguments columns] {
        if {[llength $val] != [llength $x]} {
            puts stderr "Number of points of y-axis data (column $yColumnCount) doesn't match the number of points of x-axis data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dict get $arguments columns]]
    if {([dict exist $arguments names]==1)} {
        if {[llength $columnNames] != [expr {$numCol}]} {
            puts stderr "Column names count is not the same as count of data columns"
            set autoTitleStr ""
        } else {
            lappend outList "{ } $columnNames"
            set autoTitleStr "set key autotitle columnheader"
        }
    }
    set numRow [llength $x]
    for {set i 0} {$i<$numRow} {incr i} {
        set row [lindex $x $i]
        foreach val [dict get $arguments columns] {
            lappend row [lindex $val $i]
        }
        lappend outList $row
    }
    # save data to temporary file
    set randId [expr {int(rand()*10000)}]
    set resFile [open tmpPlotId${randId}.csv w+]
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'tmpPlotId${randId}.csv' using 1:2 with lines "
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr  "${commandStr}, '' using 1:[expr {$i+2}] with lines "
    }
    exec gnuplot << "
        set mouse
        $optcmdStr
        $autoTitleStr
        $xlabelStr
        $ylabelStr
        $xscaleStr
        $yscaleStr
        $gridStr
        $commandStr
        pause mouse close
    "
    if {[dict get $arguments delete]==1} {
        file delete tmpPlotId${randId}.csv
    }
}

# plotXNYN --
#    Procedure create input and command files to plot 2D graphs with the individual x points, and send it to gnuplot
#
# Arguments:
#    args        Arguments for procedure:
# 				 1. -xlog : boolean switch of log scale of x axis, default off
# 				 2. -ylog : boolean switch of log scale of y axis, default off
# 				 3. -delete : boolean switch that enables deleting of temporary file after end of plotting, default off
# 				 4. -xlabel : argument to set x-axis label to display, string must be provided after it
# 				 5. -ylabel : argument to set y-axis label to display, string must be provided after it
# 				 6. -optcmd : argument with optional string that may contain additional commands to gnuplot
# 				 7. -grid : boolean switch that enables display of grid, default off
# 				 8. -names : argument that enable setting the column names of provided data, value must be provided as list
#                            in the same order as data columns provided, must have the length 1+number of y data colums
# 				 9. -columns : argument that provides the x and y data to plot, the number of columns is not restricted and must be provided
#    Gnuplot window with plotted data
#
# Example:
# set x1 [list 0 1 2 3 4 5 6]
# set y1 [list 0 1 4 9 16 25 36]
# set x2 [list 0 1 2 3 4 5 6 7]
# set y2 [list 0 1 8 27 64 125 216 350]
# set x3 [list 0 1 2 3 4 5 6 7]
# set y3 [list 0 -1 -8 -27 -64 -125 -216 -350]
# set x4 [list 0 1 2 3 4 5 6 7]
# set y4 [list 0 -1 -8 -27 -64 -125 -216 -350]
#
# gnuplotutil::plotXNYN -xlabel "x label" -ylabel "y label" -grid -names [list y1 y2 y3 y4] -columns $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4
#
proc gnuplotutil::plotXNYN {args} {
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-delete -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-optcmd -argument}
        {-grid -boolean}
        {-names -argument}
        {-columns -catchall}
    }]
    set xscaleStr ""
    set yscaleStr ""
    set xlabelStr ""
    set ylabelStr ""
    set gridStr ""
    set autoTitleStr ""
    set optcmdStr ""
    if {[dict get $arguments xlog]==1} {
        set xscaleStr "set logscale x"
    }
    if {[dict get $arguments ylog]==1} {
        set yscaleStr "set logscale y"
    }
    if {[dict get $arguments grid]==1} {
        set gridStr "set grid"
    }
    if {[dict exist $arguments names]==1} {
        set columnNames [dict get $arguments names]
    }
    if {[dict exist $arguments xlabel]==1} {
        set xlabelStr "set xlabel '[dict get $arguments xlabel]'"
    }
    if {[dict exist $arguments ylabel]==1} {
        set ylabelStr "set ylabel '[dict get $arguments ylabel]'"
    }
    if {[dict exist $arguments optcmd]==1} {
        set optcmdStr [dict get $arguments optcmd]
    }
    set columnsNum [llength [dict get $arguments columns]]
    if {$columnsNum % 2 != 0} {
        error "Number of data columns $columnsNum is odd"
    }
    set dataNum [expr {int($columnsNum/2)}]
    set yColumnCount 0
    for {set i 0} {$i<$dataNum} {incr i} {
        set xLen [llength [lindex [dict get $arguments columns] [expr {int($i*2)}]]]
        set yLen [llength [lindex [dict get $arguments columns] [expr {int($i*2+1)}]]]
        lappend xLengths $xLen
        if {$xLen != $yLen} {
            puts stderr "Number of points of y-axis data (column [expr {1+$yColumnCount}]) doesn't match the number of points of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dict exist $arguments names]==1)} {
            set headerString {}
        if {[llength $columnNames] != [expr {$dataNum}]} {
            puts stderr "Column names count is not the same as count of data columns"
            set autoTitleStr ""
        } else {
            for {set i 0} {$i<=$dataNum} {incr i} {
                set headerString "${headerString} { } [lindex $columnNames $i]"
            }
            lappend outList $headerString
            set autoTitleStr "set key autotitle columnheader"
        }
    }
    set numRow [tcl::mathfunc::max {*}$xLengths]
    for {set i 0} {$i<$numRow} {incr i} {
        set row {}
        for {set j 0} {$j<$dataNum} {incr j} {
            set columns [dict get $arguments columns]
            set xVal [lindex [lindex $columns [expr {int($j*2)}]] $i]
            set yVal [lindex [lindex $columns [expr {int($j*2+1)}]] $i]
            if {$xVal=={}} {
                lappend row { } { }
            } else {
                lappend row $xVal $yVal
            }
        }
        lappend outList $row
    }
    # save data to temporary file
    set randId [expr {int(rand()*10000)}]
    set resFile [open tmpPlotId${randId}.csv w+]
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'tmpPlotId${randId}.csv' using 1:2 with lines "
    for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [expr {$i*2+1}]:[expr {$i*2+2}] with lines "
    }
    exec gnuplot << "
        set mouse
        $optcmdStr
        $autoTitleStr
        $xlabelStr
        $ylabelStr
        $xscaleStr
        $yscaleStr
        $gridStr
        $commandStr
        pause mouse close
    "
    if {[dict get $arguments delete]==1} {
        file delete tmpPlotId${randId}.csv
    }
}