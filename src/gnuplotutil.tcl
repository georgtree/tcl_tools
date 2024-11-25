package require csv
package require argparse

package provide gnuplotutil 0.1

namespace eval ::gnuplotutil {

    namespace export plotXYN plotXNYN multiplotXNYN plotHist
    interp alias {} dget {} dict get
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists
}

proc ::gnuplotutil::plotXYN {x args} {
    # Plots 2D graphs in Gnuplot with the common x-values.
    #  x - List that contains x-point for 2D graph
    #  -xlog - boolean switch of log scale of x axis, default off
    #  -ylog - boolean switch of log scale of y axis, default off
    #  -background - boolean switch to run gnuplot in background, requires -nodelete switch, default off
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -terminal - select terminal, default 'x11' on linux and 'windows' on windows
    #  -grid - boolean switch that enables display of grid, default off
    #  -darkmode - boolean switch that enables dark mode for graph, default off
    #  -path - location of temporary file, default is current location
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns - argument that provides the y data to plot, the number of columns is not restricted and must 
    #    be provided at the end of command after all switches
    # Returns: gnuplot window with plotted data
    # ```
    # Example:
    # set x [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set y2 [list 0 1 8 27 64 125 216]
    # gnuplotutil::plotXYN $x -xlog -ylog -xlabel "x label" -ylabel "y label" -grid -names [list  y1 y2]
    # -columns $y1 $y2
    # ```
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-background -boolean -require {nodelete}}
        {-nodelete -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-optcmd -argument}
        {-terminal -argument}
        {-grid -boolean}
        {-darkmode -boolean}
        {-path -argument -default "."}
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
    set backgroundStr ""
    set darkmodeStr ""
    if {[dget $arguments xlog]==1} {
        set xscaleStr "set logscale x"
    }
    if {[dget $arguments ylog]==1} {
        set yscaleStr "set logscale y"
    }
    if {[dget $arguments grid]==1} {
        set gridStr "set grid"
    }
    if {[dexist $arguments names]==1} {
        set columnNames [dget $arguments names]
    }
    if {[dexist $arguments xlabel]==1} {
        set xlabelStr "set xlabel '[dget $arguments xlabel]'"
    }
    if {[dexist $arguments ylabel]==1} {
        set ylabelStr "set ylabel '[dget $arguments ylabel]'"
    }
    if {[dexist $arguments optcmd]==1} {
        set optcmdStr [dget $arguments optcmd]
    }
    if {[dexist $arguments terminal]==1} {
        set terminalStr [dget $arguments terminal]
    } else {
        global tcl_platform
        if {[string match -nocase *linux* $tcl_platform(os)]} {
            set terminalStr x11
        } elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
            set terminalStr windows
        } else {
            set terminalStr qt
        }
    }
    if {[dget $arguments darkmode]==1} {
        set darkmodeStr "
            set term $terminalStr noenhanced background rgb 'black'
            set border lc rgb 'white'
            set xlabel tc rgb 'white'
            set key textcolor rgb 'white'
            set grid ytics lt 0 lw 1 lc rgb 'white'
            set grid xtics lt 0 lw 1 lc rgb 'white'
        "
    } else {
        set darkmodeStr "
            set term $terminalStr noenhanced
        "
    }
    set yColumnCount 0
    foreach val [dget $arguments columns] {
        if {[llength $val] != [llength $x]} {
            error "Number of points of y-axis data (column $yColumnCount) doesn't match the number of points of x-axis\
                    data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dget $arguments columns]]
    if {([dexist $arguments names]==1)} {
        if {[llength $columnNames] != [= {$numCol}]} {
            error "Column names count is not the same as count of data columns"
            set autoTitleStr ""
        } else {
            lappend outList "{ } $columnNames"
            set autoTitleStr "set key autotitle columnheader"
        }
    }
    set numRow [llength $x]
    for {set i 0} {$i<$numRow} {incr i} {
        set row [@ $x $i]
        foreach val [dget $arguments columns] {
            lappend row [@ $val $i]
        }
        lappend outList $row
    }
    # save data to temporary file
    set counter 0
    while {true} {
        set filePath [file join [dget $arguments path] gnuplotTemp${counter}.csv]
        if {[file exists $filePath]} {
           incr counter
        } else {
            set resFile [open $filePath w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot '[file join [dget $arguments path] gnuplotTemp${counter}.csv]' using 1:2 with lines "
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr  "${commandStr}, '' using 1:[= {$i+2}] with lines "
    }
    set commandStr "
        set mouse
        $darkmodeStr
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
    if {[dget $arguments background]==1} {
        set status [catch {exec gnuplot << "
            $commandStr
            " & } errorStr]
    } else {
        set status [catch {exec gnuplot << "
            $commandStr
            "} errorStr]
    }
    
    if {[dget $arguments nodelete]==0} {
            file delete $filePath
    }   
    if {$status>0} {
        return $errorStr
    } else {
        return
    }
}

proc ::gnuplotutil::plotXNYN {args} {
    # Plots 2D graphs in Gnuplot with individual x-values.
    # Creates input and command files to plot 2D graphs with the individual x points, and sends it to gnuplot.
    #  -xlog - arg xlog boolean switch of log scale of x axis, default off
    #  -ylog - boolean switch of log scale of y axis, default off
    #  -background - boolean switch to run gnuplot in background, requires -nodelete switch, default off
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -terminal - select terminal, default 'x11' on linux and 'windows' on windows
    #  -grid - boolean switch that enables display of grid, default off
    #  -darkmode - boolean switch that enables dark mode for graph, default off
    #  -path - location of temporary file, default is current location
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns -  argument that provides the x and y data to plot, the number of columns is not restricted and must 
    #    be provided at the end of command after all switches
    # Returns: gnuplot window with plotted data
    # ```
    # Example:
    # set x1 [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set x2 [list 0 1 2 3 4 5 6 7]
    # set y2 [list 0 1 8 27 64 125 216 350]
    # gnuplotutil::plotXNYN -xlog -ylog -xlabel "x label" -ylabel "y label" -darkmode -grid -names [list y1 y2]
    # -columns $x1 $y1 $x2 $y2
    # ```
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-background -boolean -require {nodelete}}
        {-nodelete -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-optcmd -argument}
        {-terminal -argument}
        {-grid -boolean}
        {-darkmode -boolean}
        {-path -argument -default ""}
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
    set backgroundStr ""
    set darkmodeStr ""
    if {[dget $arguments xlog]==1} {
        set xscaleStr "set logscale x"
    }
    if {[dget $arguments ylog]==1} {
        set yscaleStr "set logscale y"
    }
    if {[dget $arguments grid]==1} {
        set gridStr "set grid"
    }
    if {[dexist $arguments names]==1} {
        set columnNames [dget $arguments names]
    }
    if {[dexist $arguments xlabel]==1} {
        set xlabelStr "set xlabel '[dget $arguments xlabel]'"
    }
    if {[dexist $arguments ylabel]==1} {
        set ylabelStr "set ylabel '[dget $arguments ylabel]'"
    }
    if {[dexist $arguments optcmd]==1} {
        set optcmdStr [dget $arguments optcmd]
    }
    if {[dexist $arguments terminal]==1} {
        set terminalStr [dget $arguments terminal]
    } else {
        global tcl_platform
        if {[string match -nocase *linux* $tcl_platform(os)]} {
            set terminalStr x11
        } elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
            set terminalStr windows
        } else {
            set terminalStr qt
        }
    }
    if {[dget $arguments darkmode]==1} {
        set darkmodeStr "
            set term $terminalStr noenhanced background rgb 'black'
            set border lc rgb 'white'
            set xlabel tc rgb 'white'
            set key textcolor rgb 'white'
            set grid ytics lt 0 lw 1 lc rgb 'white'
            set grid xtics lt 0 lw 1 lc rgb 'white'
        "
    } else {
        set darkmodeStr "
            set term $terminalStr noenhanced
        "
    }
    set columnsNum [llength [dget $arguments columns]]
    if {$columnsNum % 2 != 0} {
        error "Number of data columns $columnsNum is odd"
    }
    set dataNum [= {int($columnsNum/2)}]
    set yColumnCount 0
    for {set i 0} {$i<$dataNum} {incr i} {
        set xLen [llength [@ [dget $arguments columns] [= {int($i*2)}]]]
        set yLen [llength [@ [dget $arguments columns] [= {int($i*2+1)}]]]
        lappend xLengths $xLen
        if {$xLen != $yLen} {
            error "Number of points of y-axis data (column [= {1+$yColumnCount}]) doesn't match the number of points\
                    of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dexist $arguments names]==1)} {
            set headerString {}
        if {[llength $columnNames] != [= {$dataNum}]} {
            error "Column names count is not the same as count of data columns"
            set autoTitleStr ""
        } else {
            for {set i 0} {$i<=$dataNum} {incr i} {
                set headerString "${headerString} { } [@ $columnNames $i]"
            }
            lappend outList $headerString
            set autoTitleStr "set key autotitle columnheader"
        }
    }
    set numRow [tcl::mathfunc::max {*}$xLengths]
    for {set i 0} {$i<$numRow} {incr i} {
        set row {}
        for {set j 0} {$j<$dataNum} {incr j} {
            set columns [dget $arguments columns]
            set xVal [@ [@ $columns [= {int($j*2)}]] $i]
            set yVal [@ [@ $columns [= {int($j*2+1)}]] $i]
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
        set filePath [file join [dget $arguments path] gnuplotTemp${counter}.csv]
        if {[file exists $filePath]} {
           incr counter
        } else {
            set resFile [open $filePath w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot '[file join [dget $arguments path] gnuplotTemp${counter}.csv]' using 1:2 with lines "
    for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [= {$i*2+1}]:[= {$i*2+2}] with lines "
    }
    set commandStr "
        set mouse
        $darkmodeStr
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
    if {[dget $arguments background]==1} {
        set status [catch {exec gnuplot << "
            $commandStr
            " & } errorStr]
    } else {
        set status [catch {exec gnuplot << "
            $commandStr
            "} errorStr]
    }
    
    if {[dget $arguments nodelete]==0} {
        file delete $filePath
    }   
    if {$status>0} {
        return $errorStr
    } else {
        return
    }
}


proc ::gnuplotutil::plotXNYNMp {args} {
    # Auxilary function for gnuplotutil::multiplotXNYN, creates command strings and data files
    #  for individual plots
    #  -xlog - arg xlog boolean switch of log scale of x axis, default off
    #  -ylog - boolean switch of log scale of y axis, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -grid - boolean switch that enables display of grid, default off
    #  -path - location of temporary file, default is current location
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns -  argument that provides the x and y data to plot, the number of columns is not restricted and must 
    #    be provided at the end of command after all switches
    # Returns: list that contains command script and name of data file 
    set arguments [argparse -inline {
        {-xlog -boolean}
        {-ylog -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-grid -boolean}
        {-path -argument -default "."}
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
    if {[dget $arguments xlog]==1} {
        set xscaleStr "set logscale x"
        set xscaleStrUnset "unset logscale x"
    }
    if {[dget $arguments ylog]==1} {
        set yscaleStr "set logscale y"
        set yscaleStrUnset "unset logscale y"
    }
    if {[dget $arguments grid]==1} {
        set gridStr "set grid"
        set gridStrUnset "unset grid"
    }
    if {[dexist $arguments names]==1} {
        set columnNames [dget $arguments names]
    }
    if {[dexist $arguments xlabel]==1} {
        set xlabelStr "set xlabel '[dget $arguments xlabel]'"
        set xlabelStrUnset "unset xlabel"
    }
    if {[dexist $arguments ylabel]==1} {
        set ylabelStr "set ylabel '[dget $arguments ylabel]'"
        set ylabelStrUnset "unset ylabel"
    }
    set columnsNum [llength [dget $arguments columns]]
    if {$columnsNum % 2 != 0} {
        error "Number of data columns $columnsNum is odd"
    }
    set dataNum [= {int($columnsNum/2)}]
    set yColumnCount 0
    for {set i 0} {$i<$dataNum} {incr i} {
        set xLen [llength [@ [dget $arguments columns] [= {int($i*2)}]]]
        set yLen [llength [@ [dget $arguments columns] [= {int($i*2+1)}]]]
        lappend xLengths $xLen
        if {$xLen != $yLen} {
            error "Number of points of y-axis data (column [= {1+$yColumnCount}]) doesn't match the number of points\
                    of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dexist $arguments names]==1)} {
            set headerString {}
        if {[llength $columnNames] != [= {$dataNum}]} {
            error "Column names count is not the same as count of data columns"
            set autoTitleStr ""
        } else {
            for {set i 0} {$i<=$dataNum} {incr i} {
                set headerString "${headerString} { } [@ $columnNames $i]"
            }
            lappend outList $headerString
            set autoTitleStr "set key autotitle columnheader"
        }
    }
    set numRow [tcl::mathfunc::max {*}$xLengths]
    for {set i 0} {$i<$numRow} {incr i} {
        set row {}
        for {set j 0} {$j<$dataNum} {incr j} {
            set columns [dget $arguments columns]
            set xVal [@ [@ $columns [= {int($j*2)}]] $i]
            set yVal [@ [@ $columns [= {int($j*2+1)}]] $i]
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
        set filePath [file join [dget $arguments path] gnuplotTemp${counter}.csv]
        if {[file exists $filePath]} {
           incr counter
        } else {
            set resFile [open $filePath w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'gnuplotTemp${counter}.csv' using 1:2 with lines "
    for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [= {$i*2+1}]:[= {$i*2+2}] with lines "
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
    return [dict create cmdString $gnuplotCmdString file $filePath]
}



proc ::gnuplotutil::multiplotXNYN {layout args} {
    # Plots 2D graphs in Gnuplot with individual x-values and by using multiplot.
    #  layout - list of layout configurations values, for example, {2 2}
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -background - boolean switch to run gnuplot in background, requires -nodelete switch, default off
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -terminal - select terminal, default 'x11' on linux and 'windows' on windows
    #  -darkmode - boolean switch that enables dark mode for graph, default off
    #  -path - location of temporary file, default is current location
    #  -plots - argument that provides the list of individual plots, the number of plots is not restricted and must 
    #    be provided at the end of command after all switches, the inputs syntax is the same as
    #    [::gnuplotutil::plotXNYN]
    # Returns: gnuplot window with plotted data as multiplot
    # ```
    # Example:
    # set x1 [list 1 2 3 4 5 6]
    # set y1 [list 1 4 9 16 25 36]
    # set x2 [list 6 5 4 3 2 1]
    # set y2 [list 36 25 16 9 4 1]
    # set x3 [list 7 8 9 10]
    # set y3 [list 49 64 81 100]
    # set plot1 [list -xlog -ylog -xlabel "x label" -ylabel "y label" -grid -names [list name1 name2 name3]
    # -columns $x1 $y1 $x2 $y2 $x3 $y3]
    # set plot2 [list -ylabel "y label" -grid -names [list name1 name2] -columns $x1 $y1 $x2 $y2 ]
    # set plot3 [list -xlabel "x label" -ylabel "y label" -names [list name3] -columns $x3 $y3 ]
    # set plot4 [list -grid -names [list name2] -columns $x2 $y2 ]
    # gnuplotutil::multiplotXNYN {2 2} -plots $plot1 $plot2 $plot3 $plot4
    # ```
    set arguments [argparse -inline {
        {-nodelete -boolean}
        {-background -boolean -require {nodelete}}
        {-optcmd -argument}
        {-terminal -argument}
        {-darkmode -boolean}
        {-path -argument -default "."}
        {-plots -catchall}
    }]
    if {[dexist $arguments optcmd]==0} {
        set optcmd ""
    }
    if {[llength $layout]>2} {
        error "Length of layout arguments is more than 2"
    } else {
        set layoutStr "set multiplot layout [@ $layout 0],[@ $layout 1]"
    }
    if {[dexist $arguments terminal]==1} {
        set terminalStr [dget $arguments terminal]
    } else {
        global tcl_platform
        if {[string match -nocase *linux* $tcl_platform(os)]} {
            set terminalStr x11
        } elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
            set terminalStr windows
        } else {
            set terminalStr qt
        }
    }
    if {[dget $arguments darkmode]==1} {
        set darkmodeStr "
            set term $terminalStr noenhanced background rgb 'black'
            set border lc rgb 'white'
            set xlabel tc rgb 'white'
            set key textcolor rgb 'white'
            set grid ytics lt 0 lw 1 lc rgb 'white'
            set grid xtics lt 0 lw 1 lc rgb 'white'
        "
    } else {
        set darkmodeStr "
            set term $terminalStr noenhanced
        "
    }
    foreach plot [dget $arguments plots] {
        set plotResults [gnuplotutil::plotXNYNMp {*}$plot]
        lappend cmdStrings [dget $plotResults cmdString]
        lappend fileNames [dget $plotResults file]
    }
    set commandStr "
        $optcmd
        $darkmodeStr
        $layoutStr
        [join $cmdStrings \n]
        unset multiplot
        pause mouse close
    "
    if {[dget $arguments background]==1} {
        set status [catch {exec gnuplot << "
            $commandStr
            " & } errorStr]
    } else {
        set status [catch {exec gnuplot << "
            $commandStr
            "} errorStr]
    }
    if {[dget $arguments nodelete]==0} {
        foreach fileName $fileNames {
            file delete $fileName
        }
    }
    if {$status>0} {
        return $errorStr
    } else {
        return
    }
}

proc ::gnuplotutil::plotHist {x args} {
    # Plots 2D histograms in Gnuplot with the common x-values.
    #  x - List of strings that contains x-point for 2D histogram
    #  -nodelete - boolean switch that disables deleting of temporary file after end of plotting, default off
    #  -xlabel - argument to set x-axis label to display, string must be provided after it
    #  -ylabel - argument to set y-axis label to display, string must be provided after it
    #  -style - set style of diagram, must be clustered, rowstacked or columnstacked
    #  -gap - gap between columns in clustered style,-style argument is required
    #  -boxwidth - width of columns, must be in range (0,1]
    #  -fill - set fill of columns, must be empty or solid
    #  -grid - set grid of histogram
    #  -background - boolean switch to run gnuplot in background, requires -nodelete switch, default off
    #  -terminal - select terminal, default 'x11' on linux and 'windows' on windows
    #  -path - location of temporary file, default is current location
    #  -darkmode - boolean switch that enables dark mode for graph, default off
    #  -transparent - add transparent modificator to filling of columns, -fill argument is required
    #  -density - set density of solid filling, -fill argument is required
    #  -border - set border of columns with particular style, -fill argument is required
    #  -optcmd - argument with optional string that may contain additional commands to gnuplot
    #  -names - argument that enable setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 1+number of y data colums
    #  -columns - argument that provides the y data to plot, the number of columns is not restricted and must be 
    #    provided at the end of command after all switches
    # Returns: gnuplot window with plotted data
    # ```
    # Example:
    # set x1 [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set y2 [list 0 1 8 27 64 125 216]
    # gnuplotutil::plotHist $x1 -style clustered -fill solid -xlabel "x label" -ylabel "y label" -names [list y1 y2]
    # -columns $y1 $y2]
    # ```
    set arguments [argparse -inline {
        {-nodelete -boolean}
        {-xlabel -argument}
        {-ylabel -argument}
        {-style -argument -enum {clustered rowstacked columnstacked} -required}
        {-gap -argument -require {style}}
        {-optcmd -argument}
        {-grid -boolean}
        {-background -boolean -require {nodelete}}
        {-terminal -argument}
        {-path -argument -default "."}
        {-darkmode -boolean}
        {-names -argument}
        {-boxwidth -argument}
        {-fill -argument -enum {empty solid}}
        {-density -argument -require {fill}}
        {-transparent -boolean -require {fill}}
        {-border -argument -require {fill}}
        {-columns -catchall}
    }]
    set xscaleStr ""
    set yscaleStr ""
    set autoTitleStr ""
    set optcmdStr ""
    set styleStr ""
    set gridStr ""
    set boxwidthStr ""
    set fillStr ""
    set backgroundStr ""
    set darkmodeStr ""
    if {[dexist $arguments names]} {
        set columnNames [dget $arguments names]
    }
    if {[dexist $arguments optcmd]} {
        set optcmdStr [dget $arguments optcmd]
    }
    if {[dexist $arguments terminal]==1} {
        set terminalStr [dget $arguments terminal]
    } else {
        global tcl_platform
        if {[string match -nocase *linux* $tcl_platform(os)]} {
            set terminalStr x11
        } elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
            set terminalStr windows
        } else {
            set terminalStr qt
        }
    }
    if {[dget $arguments darkmode]==1} {
        set darkmodeStr "
            set term $terminalStr noenhanced background rgb 'black'
            set border lc rgb 'white'
            set xlabel tc rgb 'white'
            set key textcolor rgb 'white'
            set grid ytics lt 0 lw 1 lc rgb 'white'
            set grid xtics lt 0 lw 1 lc rgb 'white'
        "
    } else {
        set darkmodeStr "
            set term $terminalStr noenhanced
        "
    }
    if {[dget $arguments grid]==1} {
        set gridStr "set grid"
    }
    if {[dexist $arguments xlabel]} {
        set xlabelStr "set xlabel '[dget $arguments xlabel]'"
    }
    if {[dexist $arguments ylabel]} {
        set ylabelStr "set ylabel '[dget $arguments ylabel]'"
    }
    if {[dexist $arguments ylabel]} {
        set ylabelStr "set ylabel '[dget $arguments ylabel]'"
    }
    if {[dexist $arguments boxwidth]} {
        set boxwidthStr "set boxwidth '[dget $arguments boxwidth]'"
    }
    if {[dexist $arguments fill]} {
        if {[dget $arguments transparent]==1} {
            set fillStr "set style fill transparent [dget $arguments fill]"
        } else {
            set fillStr "set style fill [dget $arguments fill]"
        }
        if {[dexist $arguments density]} {
            append fillStr " [dget $arguments density]"
        }
        if {[dexist $arguments border]} {
            append fillStr " border lt [dget $arguments border]"
        }
    }
    if {[dexist $arguments style]} {
        if {([dexist $arguments gap]) && ([dget $arguments style] in {clustered})} {
             set styleStr "set style histogram [dget $arguments style] gap [dget $arguments gap]"
        } else {
            set styleStr "set style histogram [dget $arguments style]"
        }
    }
    set yColumnCount 0
    foreach val [dget $arguments columns] {
        if {[llength $val] != [llength $x]} {
            error "Number of points of y-axis data (column $yColumnCount) doesn't match the number of points of x-axis\
                    data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dget $arguments columns]]
    if {([dexist $arguments names]==1)} {
        if {[llength $columnNames] != [= {$numCol}]} {
            error "Column names count is not the same as count of data columns"
            set autoTitleStr ""
        } else {
            lappend outList "{ } $columnNames"
            set autoTitleStr "set key autotitle columnheader"
        }
    }
    set numRow [llength $x]
    for {set i 0} {$i<$numRow} {incr i} {
        set row [@ $x $i]
        foreach val [dget $arguments columns] {
            lappend row [@ $val $i]
        }
        lappend outList $row
    }
    # save data to temporary file
    set counter 0
    while {true} {
        set filePath [file join [dget $arguments path] gnuplotTemp${counter}.csv]
        if {[file exists $filePath]} {
           incr counter
        } else {
            set resFile [open $filePath w+]
            break
        }
    }
    puts $resFile [::csv::joinlist $outList " "]
    close $resFile
    # create command strings for gnuplot
    set commandStr "plot 'gnuplotTemp${counter}.csv' using 2:xtic(1)"
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr  "${commandStr}, '' using [= {$i+2}]"
    }
    set commandStr "
        set mouse
        set style data histogram
        $styleStr
        $fillStr
        $optcmdStr
        $gridStr
        $autoTitleStr
        $xlabelStr
        $ylabelStr
        $boxwidthStr
        $commandStr
        pause mouse close
    "
    if {[dget $arguments background]==1} {
        set status [catch {exec gnuplot << "
            $commandStr
            " & } errorStr]
    } else {
        set status [catch {exec gnuplot << "
            $commandStr
            "} errorStr]
    }
    if {[dget $arguments nodelete]==0} {
        file delete $filePath
    }   
    if {$status>0} {
        return $errorStr
    } else {
        return
    }
}
