package require csv
package require argparse

package provide gnuplotutil 0.1

namespace eval ::gnuplotutil {

    namespace export plotXYN plotXNYN multiplotXNYN plotHist
}


proc gnuplotutil::plotXYN {x args} {
    # Plots 2D graphs in Gnuplot with the common x-values.
    #  x - List that contains x-point for 2D graph
    #  -xlog - arg xlog boolean switch of log scale of x axis, default off
    #  -ylog - boolean switch of log scale of y axis, default off
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -grid - boolean switch that enables display of grid, default off
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns - argument that provides the y data to plot, the number of columns is not restricted and must be provided
    #    at the end of command after all switches
    # Returns: gnuplot window with plotted data
    # ```
    # Example:
    # set x [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set y2 [list 0 1 8 27 64 125 216]
    # gnuplotutil::plotXYN $x -xlog -ylog -xlabel "x label" -ylabel "y label" -delete -grid -names [list y1 y2] -columns $y1 $y2
    # ```
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-nodelete -boolean}
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
            error "Number of points of y-axis data (column $yColumnCount) doesn't match the number of points of x-axis data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dict get $arguments columns]]
    if {([dict exist $arguments names]==1)} {
        if {[llength $columnNames] != [expr {$numCol}]} {
            error "Column names count is not the same as count of data columns"
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
    set counter 0
    while {true} {
        if {[file exists gnuplotTemp${counter}.csv]} {
           incr counter
        } else {
            set resFile [open gnuplotTemp${counter}.csv w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'gnuplotTemp${counter}.csv' using 1:2 with lines "
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr  "${commandStr}, '' using 1:[expr {$i+2}] with lines "
    }
    catch {exec gnuplot << "
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
    "} errorStr
    puts $errorStr
    if {[dict get $arguments nodelete]==0} {
        file delete gnuplotTemp${counter}.csv
    }
}

proc gnuplotutil::plotXNYN {args} {
    # Plots 2D graphs in Gnuplot with individual x-values.
    # Creates input and command files to plot 2D graphs with the individual x points, and sends it to gnuplot.
    #  -xlog - arg xlog boolean switch of log scale of x axis, default off
    #  -ylog - boolean switch of log scale of y axis, default off
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -grid - boolean switch that enables display of grid, default off
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns -  argument that provides the x and y data to plot, the number of columns is not restricted and must be provided
    #    at the end of command after all switches
    # Returns: gnuplot window with plotted data
    # ```
    # Example:
    # set x1 [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set x2 [list 0 1 2 3 4 5 6 7]
    # set y2 [list 0 1 8 27 64 125 216 350]
    # set x3 [list 0 1 2 3 4 5 6 7]
    # set y3 [list 0 -1 -8 -27 -64 -125 -216 -350]
    # set x4 [list 0 1 2 3 4 5 6 7]
    # set y4 [list 0 -1 -8 -27 -64 -125 -216 -350]
    # gnuplotutil::plotXNYN -xlabel "x label" -ylabel "y label" -grid -names [list y1 y2 y3 y4] -columns $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4  
    # ```
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-nodelete -boolean}
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
            error "Number of points of y-axis data (column [expr {1+$yColumnCount}]) doesn't match the number of points of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dict exist $arguments names]==1)} {
            set headerString {}
        if {[llength $columnNames] != [expr {$dataNum}]} {
            error "Column names count is not the same as count of data columns"
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
    set counter 0
    while {true} {
        if {[file exists gnuplotTemp${counter}.csv]} {
           incr counter
        } else {
            set resFile [open gnuplotTemp${counter}.csv w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'gnuplotTemp${counter}.csv' using 1:2 with lines "
    for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [expr {$i*2+1}]:[expr {$i*2+2}] with lines "
    }
    catch {exec gnuplot << "
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
    "} errorStr
    puts $errorStr
    if {[dict get $arguments nodelete]==0} {
        file delete gnuplotTemp${counter}.csv
    }
}


proc gnuplotutil::plotXNYNMp {args} {
    # Auxilary function for gnuplotutil::multiplotXNYN, creates command strings and data files
    #  for individual plots
    #  -xlog - arg xlog boolean switch of log scale of x axis, default off
    #  -ylog - boolean switch of log scale of y axis, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -grid - boolean switch that enables display of grid, default off
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns -  argument that provides the x and y data to plot, the number of columns is not restricted and must be provided
    #    at the end of command after all switches
    # Returns: list that contains command script and name of data file 
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-grid -boolean}
        {-names -argument}
        {-columns -catchall}
    }]
    set xscaleStr ""
    set yscaleStr ""
    set xlabelStr ""
    set ylabelStr ""
    set gridStr ""
    set xscaleStrUnset ""
    set yscaleStrUnset ""
    set xlabelStrUnset ""
    set ylabelStrUnset ""
    set gridStrUnset ""
    set autoTitleStr ""
    set optcmdStr ""
    if {[dict get $arguments xlog]==1} {
        set xscaleStr "set logscale x"
        set xscaleStrUnset "unset logscale x"
    }
    if {[dict get $arguments ylog]==1} {
        set yscaleStr "set logscale y"
        set yscaleStrUnset "unset logscale y"
    }
    if {[dict get $arguments grid]==1} {
        set gridStr "set grid"
        set gridStrUnset "unset grid"
    }
    if {[dict exist $arguments names]==1} {
        set columnNames [dict get $arguments names]
    }
    if {[dict exist $arguments xlabel]==1} {
        set xlabelStr "set xlabel '[dict get $arguments xlabel]'"
        set xlabelStrUnset "unset xlabel"
    }
    if {[dict exist $arguments ylabel]==1} {
        set ylabelStr "set ylabel '[dict get $arguments ylabel]'"
        set ylabelStrUnset "unset ylabel"
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
            error "Number of points of y-axis data (column [expr {1+$yColumnCount}]) doesn't match the number of points of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dict exist $arguments names]==1)} {
            set headerString {}
        if {[llength $columnNames] != [expr {$dataNum}]} {
            error "Column names count is not the same as count of data columns"
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
    set counter 0
    while {true} {
        if {[file exists gnuplotTemp${counter}.csv]} {
           incr counter
        } else {
            set resFile [open gnuplotTemp${counter}.csv w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'gnuplotTemp${counter}.csv' using 1:2 with lines "
    for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [expr {$i*2+1}]:[expr {$i*2+2}] with lines "
    }
    set gnuplotCmdString "
        $autoTitleStr
        $xlabelStr
        $ylabelStr
        $xscaleStr
        $yscaleStr
        $gridStr
        $commandStr
        $xlabelStrUnset
        $ylabelStrUnset
        $xscaleStrUnset
        $yscaleStrUnset
        $gridStrUnset
    "
    return [dict create cmdString $gnuplotCmdString file "gnuplotTemp${counter}.csv"]
}



proc gnuplotutil::multiplotXNYN {layout args} {
    # Plots 2D graphs in Gnuplot with individual x-values and by using multiplot.
    #  layout - list of layout configurations values, for example, {2 2}
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -plots - argument that provides the list of individual plots, the number of plots is not restricted and must be provided
    #    at the end of command after all switches, the inputs syntax is the same as [::gnuplotutil::plotXNYN]
    # Returns: gnuplot window with plotted data as multiplot
    # ```
    # Example:
    # set x1 [list 1 2 3 4 5 6]
    # set y1 [list 1 4 9 16 25 36]
    # set x2 [list 6 5 4 3 2 1]
    # set y2 [list 36 25 16 9 4 1]
    # set x3 [list 7 8 9 10]
    # set y3 [list 49 64 81 100]
    # set plot1 [list -xlog -ylog -xlabel "x label" -ylabel "y label" -grid -names [list name1 name2 name3] -columns $x1 $y1 $x2 $y2 $x3 $y3]
    # set plot2 [list -ylabel "y label" -grid -names [list name1 name2] -columns $x1 $y1 $x2 $y2 ]
    # set plot3 [list -xlabel "x label" -ylabel "y label" -names [list name3] -columns $x3 $y3 ]
    # set plot4 [list -grid -names [list name2] -columns $x2 $y2 ]
    # gnuplotutil::multiplotXNYN {2 2} -plots $plot1 $plot2 $plot3 $plot4
    # ```
    set arguments [argparse {
        {-optcmd -argument}
        {-nodelete -boolean}
        {-plots -catchall}
    }]
    if {[info exists optcmd]==0} {
        set optcmd ""
    }
    if {[llength $layout]>2} {
        error "Length of layout arguments is more than 2"
    } else {
        set layoutStr "set multiplot layout [lindex $layout 0],[lindex $layout 1]"
    }

    foreach plot $plots {
        set plotResults [gnuplotutil::plotXNYNMp {*}$plot]
        lappend cmdStrings [dict get $plotResults cmdString]
        lappend fileNames [dict get $plotResults file]
    }
    catch {exec gnuplot << "
        $optcmd
        $layoutStr
        [join $cmdStrings \n]
        unset multiplot
        pause mouse close
    "} errorStr
    puts $errorStr
    if {$nodelete==0} {
        foreach fileName $fileNames {
            file delete $fileName
        }
    }
}

proc gnuplotutil::plotHist {x args} {
    # Plots 2D histograms in Gnuplot with the common x-values.
    #  x - List that contains x-point for 2D histogram
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -xtickfmt - format of xticks
    #  -columns - argument that provides the y data to plot, the number of columns is not restricted and must be provided
    #    at the end of command after all switches
    # Returns: gnuplot window with plotted data
    # ```
    # Example:
    # set x1 [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set y2 [list 0 1 8 27 64 125 216]
    # gnuplotutil::plotHist $x1 -xlabel "x label" -ylabel "y label" -names [list  y1 y2] -columns $y1 $y2
    # ```
    set arguments [argparse -inline {
        {-nodelete -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-optcmd -argument}
        {-names -argument}
        {-xtickfmt -argument}
        {-columns -catchall}
    }]
    set xscaleStr ""
    set yscaleStr ""
    set autoTitleStr ""
    set optcmdStr ""
    set xtickfmt ""
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
    if {[dict exist $arguments xtickfmt]==1} {
        set xtickfmt "sprintf('[dict get $arguments xtickfmt]', \$1)"
    }
    set yColumnCount 0
    foreach val [dict get $arguments columns] {
        if {[llength $val] != [llength $x]} {
            error "Number of points of y-axis data (column $yColumnCount) doesn't match the number of points of x-axis data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dict get $arguments columns]]
    if {([dict exist $arguments names]==1)} {
        if {[llength $columnNames] != [expr {$numCol}]} {
            error "Column names count is not the same as count of data columns"
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
    set counter 0
    while {true} {
        if {[file exists gnuplotTemp${counter}.csv]} {
           incr counter
        } else {
            set resFile [open gnuplotTemp${counter}.csv w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'gnuplotTemp${counter}.csv' using 1:2:xtic(${xtickfmt}) smooth freq w boxes fs transparent"
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr  "${commandStr}, '' using 1:[expr {$i+2}]:xtic(${xtickfmt}) smooth freq w boxes fs transparent"
    }
    catch {exec gnuplot << "
        set mouse
        set style histogram cluster
        set style fill solid 1.0 border lt -1
        $optcmdStr
        $autoTitleStr
        $xlabelStr
        $ylabelStr
        $commandStr
        pause mouse close
    "} errorStr
    puts $errorStr
    if {[dict get $arguments nodelete]==0} {
        file delete gnuplotTemp${counter}.csv
    }
}