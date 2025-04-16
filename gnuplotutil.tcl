package require csv
package require argparse
package require textutil::trim
namespace import ::textutil::trim::trim
package provide gnuplotutil 0.1

namespace eval ::gnuplotutil {

    namespace export plotXYN plotXNYN multiplotXNYN plotHist
    interp alias {} dget {} dict get
    interp alias {} @ {} lindex
    interp alias {} = {} expr
    interp alias {} dexist {} dict exists

    set darkmodeStyleList {{set border lc rgb 'white'} {set xlabel tc rgb 'white'} {set key textcolor rgb 'white'}\
                                   {set grid ytics lt 0 lw 1 lc rgb 'white'} {set grid xtics lt 0 lw 1 lc rgb 'white'}}
    set darkmodeStyle [join $darkmodeStyleList "\n"]
}

proc ::gnuplotutil::AliasesKeysCheck {arguments keys} {
    foreach key $keys {
        if {[dexist $arguments $key]} {
            return $key
        }
    }
    set formKeys [lmap key $keys {subst -$key}]
    return -code error "[join [lrange $formKeys 0 end-1] ", "] or [@ $formKeys end] must be presented"
}

proc ::gnuplotutil::initArgStr {optDict optName varName value} {
    if {[dexist $optDict $optName]} {
        uplevel {*}[list set $varName $value]
    } else {
        uplevel {*}[list set $varName {""}]
    }
    return
}

proc ::gnuplotutil::initTerminalStr {optDict varName} {
    if {[dexist $optDict terminal]} {
        uplevel set $varName [dget $optDict terminal]
    } else {
        global tcl_platform
        if {[string match -nocase *linux* $tcl_platform(os)]} {
            uplevel set $varName x11
        } elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
            uplevel set $varName windows
        } else {
            uplevel set $varName qt
        }
    }
}

proc ::gnuplotutil::plotXYN {x args} {
    # Plots 2D graphs in Gnuplot with the common x-values.
    #  x - list of x-point for 2D graph
    #  -xlog - enables log scale of x axis
    #  -ylog - enables log scale of y axis
    #  -background - enables running gnuplot in background, requires -nodelete or -inline switch
    #  -inline - provides data directly in command string, without creating temporary file
    #  -nodelete - disables deleting of temporary file after end of plotting
    #  -xlabel - provides x-axis label to display, string must be provided after it
    #  -ylabel - provides y-axis label to display, string must be provided after it
    #  -optcmd - provides optional string that may contain additional commands to gnuplot
    #  -terminal - selects terminal, default 'x11' on Linux and 'windows' on Windows
    #  -grid - enables display of grid
    #  -darkmode - enables dark mode for graph
    #  -output - command redirects output to the specified file or device
    #  -size - provides size of the window, must be list with two elements: width and height in pixels
    #  -path - provides location of temporary file, default is the current location
    #  -names - enables setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length equal to the number of y data colums
    #  -lstyles - set individual styles for each graph
    #    in the same order as data columns provided, must have the length 2*(number of x-y data pairs)
    #  -columns - provides the y data to plot, the number of columns is not restricted and must be provided at the end
    #    of command after all switches
    # Returns: creates gnuplot window with plotted data, and returns string contains commands sent to gnuplot
    # Synopsis: x ?-xlog? ?-ylog? ?-background? ?-nodelete? ?-xlabel string? ?-ylabel string? ?-optcmd string?
    #   ?-terminal? ?-grid? ?-darkmode? ?-size list? ?-path string? ?-names list? ?-lstyles list? ?-output string?
    #   -columns yList1 ?yList2 ...?
    # ```
    # Example:
    # set x [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set y2 [list 0 1 8 27 64 125 216]
    # gnuplotutil::plotXYN $x -xlog -ylog -xlabel "x label" -ylabel "y label" -grid -names [list  y1 y2]
    # -columns $y1 $y2
    # ```
    set arguments [argparse -inline {
        -xlog
        -ylog
        -background
        -inline
        {-nodelete -forbid inline}
        -xlabel=
        -ylabel=
        -optcmd=
        -terminal=
        {-size= -default {800 600}}
        -grid
        -darkmode
        -output=
        {-path= -default {}}
        -names=
        -lstyles=
        {-columns -catchall}
    }]
    if {[dexist $arguments background]} {
        AliasesKeysCheck $arguments {nodelete inline}
    }
    initArgStr $arguments xlog xscaleStr {{set logscale x}}
    initArgStr $arguments ylog yscaleStr {{set logscale y}}
    initArgStr $arguments grid gridStr {{set grid}}
    initArgStr $arguments output outputStr {"set output '[dget $arguments output]'"}
    initArgStr $arguments xlabel xlabelStr {"set xlabel '[dget $arguments xlabel]'"}
    initArgStr $arguments ylabel ylabelStr {"set ylabel '[dget $arguments ylabel]'"}
    initArgStr $arguments names columnNames {[dget $arguments names]}
    initArgStr $arguments lstyles lineStyles {[dget $arguments lstyles]}
    initArgStr $arguments optcmd optcmdStr {[dget $arguments optcmd]}
    initTerminalStr $arguments terminalStr
    if {[dexist $arguments darkmode]} {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced background rgb 'black'"
        append darkmodeStr "\n" $::gnuplotutil::darkmodeStyle
    } else {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced"
    }
    set yColumnCount 0
    foreach val [dget $arguments columns] {
        if {[llength $val]!=[llength $x]} {
            return -code error "Number of points '[llength $val]' of y-axis data (column $yColumnCount) doesn't match\
                    the number of points '[llength $x]' of x-axis data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dget $arguments columns]]
    if {([dexist $arguments names])} {
        if {[llength $columnNames]!=[= {$numCol}]} {
            return -code error "Column names count '[llength $columnNames]' is not the same as count '$numCol' of data\
                    columns"
        } else {
            foreach columnName $columnNames {
                lappend processedNames "\"$columnName\""
            }
            lappend outList "{ } [join $processedNames]"
            set autoTitleStr {set key autotitle columnheader}
        }
    } else {
        set autoTitleStr {}
    }
    if {([dexist $arguments lstyles])} {
        if {[llength $lineStyles]!=$numCol} {
            return -code error "Lines styles count '[llength $lineStyles]' is not the same as count '$numCol' of data\
                    columns"
        }
    } else {
        for {set i 0} {$i<$numCol} {incr i} {
            lappend lineStyles {with lines}
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
    # save data to temporary file or use inline data block
    if {[dexist $arguments inline]} {
        set inlineData "\$data << EOD\n[::csv::joinlist $outList " "]\nEOD\n"
    } else {
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
        puts $resFile [::csv::joinlist $outList { }]
        close $resFile
    }
    # create command strings for gnuplot
    if {[dexist $arguments inline]} {
        set commandStr "$inlineData plot \$data using 1:2 [@ $lineStyles 0] "
    } else {
        set commandStr "plot '[file join [dget $arguments path] gnuplotTemp${counter}.csv]' using 1:2 [@ $lineStyles 0] "
    }
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr "${commandStr}, '' using 1:[= {$i+2}] [@ $lineStyles $i] "
    }
    set commandList [list {set mouse} $outputStr $darkmodeStr $optcmdStr $autoTitleStr $xlabelStr $ylabelStr $xscaleStr\
                             $yscaleStr $gridStr $commandStr {pause mouse close}]
    set commandStr [join [lmap elem $commandList {= {$elem eq {} ? [continue] : $elem}}] "\n"]
    if {[dexist $arguments background]} {
        set status [catch {exec gnuplot << "\n$commandStr\n" & } errorStr]
    } else {
        set status [catch {exec gnuplot << "\n$commandStr\n"} errorStr]
    }
    if {![dexist $arguments nodelete] && ![dexist $arguments inline]} {
        file delete $filePath
    }  
    if {$status>0} {
        return $errorStr
    } else {
        return $commandStr
    }
}

proc ::gnuplotutil::plotXNYN {args} {
    # Plots 2D graphs in Gnuplot with individual x-values.
    #  -xlog - enables log scale of x axis
    #  -ylog - enables log scale of y axis
    #  -background - enables running gnuplot in background, requires -nodelete or -inline switch
    #  -inline - provides data directly in command string, without creating temporary file
    #  -nodelete - disables deleting of temporary file after end of plotting
    #  -xlabel - provides x-axis label to display, string must be provided after it
    #  -ylabel - provides y-axis label to display, string must be provided after it
    #  -optcmd - provides optional string that may contain additional commands to gnuplot
    #  -terminal - selects terminal, default 'x11' on Linux and 'windows' on Windows
    #  -size - provides size of the window, must be list with two elements: width and height in pixels
    #  -grid - enables display of grid
    #  -darkmode - enables dark mode for graph
    #  -output - command redirects output to the specified file or device
    #  -path - provides location of temporary file, default is the current location
    #  -names - enables setting the column names of provided data, value must be provided as list
    #  -lstyles - set individual styles for each graph in the same order as data columns provided,
    #    must have the length 2*(number of x-y data pairs)
    #  -columns -  provides the x and y data to plot, the number of columns is not restricted and must 
    #    be provided at the end of command after all switches
    # Returns: creates gnuplot window with plotted data, and returns string contains commands sent to gnuplot
    # Synopsis: ?-xlog? ?-ylog? ?-background? ?-nodelete? ?-xlabel string? ?-ylabel string? ?-optcmd string?
    #   ?-terminal? ?-grid? ?-darkmode? ?-size list? ?-path string? ?-names list? ?-lstyles list? ?-output string?
    #   -columns xList1 yList1 ?xList2 yList2 ...?
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
        -xlog
        -ylog
        -background
        -inline
        {-nodelete -forbid inline}
        -xlabel=
        -ylabel=
        -optcmd=
        -terminal=
        {-size= -default {800 600}}
        -grid
        -darkmode
        -output=
        {-path= -default {}}
        -names=
        -lstyles=
        {-columns -catchall}
    }]
    if {[dexist $arguments background]} {
        AliasesKeysCheck $arguments {nodelete inline}
    }
    initArgStr $arguments xlog xscaleStr {{set logscale x}}
    initArgStr $arguments ylog yscaleStr {{set logscale y}}
    initArgStr $arguments grid gridStr {{set grid}}
    initArgStr $arguments output outputStr {"set output '[dget $arguments output]'"}
    initArgStr $arguments xlabel xlabelStr {"set xlabel '[dget $arguments xlabel]'"}
    initArgStr $arguments ylabel ylabelStr {"set ylabel '[dget $arguments ylabel]'"}
    initArgStr $arguments names columnNames {[dget $arguments names]}
    initArgStr $arguments lstyles lineStyles {[dget $arguments lstyles]}
    initArgStr $arguments optcmd optcmdStr {[dget $arguments optcmd]}
    initTerminalStr $arguments terminalStr
    if {[dexist $arguments darkmode]} {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced background rgb 'black'"
        append darkmodeStr "\n" $::gnuplotutil::darkmodeStyle
    } else {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced"
    }
    set columnsNum [llength [dget $arguments columns]]
    if {$columnsNum % 2 != 0} {
        return -code error {Number of data columns $columnsNum is odd}
    }
    set dataNum [= {int($columnsNum/2)}]
    set yColumnCount 0
    for {set i 0} {$i<$dataNum} {incr i} {
        set xLen [llength [@ [dget $arguments columns] [= {int($i*2)}]]]
        set yLen [llength [@ [dget $arguments columns] [= {int($i*2+1)}]]]
        lappend xLengths $xLen
        if {$xLen != $yLen} {
            return -code error "Number of points '$yLen' of y-axis data (column [= {1+$yColumnCount}]) doesn't match the\
                    number of points '$xLen' of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dexist $arguments names])} {
            set headerString {}
        if {[llength $columnNames]!=$dataNum} {
            return -code error "Column names count '[llength $columnNames]' is not the same as count '$dataNum' of data\
                    columns"
        } else {
            for {set i 0} {$i<=$dataNum} {incr i} {
                set headerString "${headerString} { } \"[@ $columnNames $i]\""
            }
            lappend outList $headerString
            set autoTitleStr {set key autotitle columnheader}
        }
    } else {
        set autoTitleStr {}
    }
    if {([dexist $arguments lstyles])} {
        if {[llength $lineStyles]!=$dataNum} {
            return -code error "Lines styles count '[llength $lineStyles]' is not the same as count '$dataNum' of data\
                    columns"
        }
    } else {
        for {set i 0} {$i<$dataNum} {incr i} {
            lappend lineStyles {with lines}
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
    # save data to temporary file or use inline data block
    if {[dexist $arguments inline]} {
        set inlineData "\$data << EOD\n[::csv::joinlist $outList " "]\nEOD\n"
    } else {
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
        puts $resFile [::csv::joinlist $outList { }]
        close $resFile
    }
    # create command strings for gnuplot
    if {[dexist $arguments inline]} {
        set commandStr "$inlineData plot \$data using 1:2 [@ $lineStyles 0] "
    } else {
        set commandStr "plot '[file join [dget $arguments path] gnuplotTemp${counter}.csv]' using 1:2 [@ $lineStyles 0] "
    }
    for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [= {$i*2+1}]:[= {$i*2+2}] [@ $lineStyles $i] "
    }
    set commandList [list {set mouse} $outputStr $darkmodeStr $optcmdStr $autoTitleStr $xlabelStr $ylabelStr $xscaleStr\
                             $yscaleStr $gridStr $commandStr {pause mouse close}]
    set commandStr [join [lmap elem $commandList {= {$elem eq {} ? [continue] : $elem}}] "\n"]
    if {[dexist $arguments background]} {
        set status [catch {exec gnuplot << "\n$commandStr\n" & } errorStr]
    } else {
        set status [catch {exec gnuplot << "\n$commandStr\n"} errorStr]
    }
    if {![dexist $arguments nodelete] && ![dexist $arguments inline]} {
        file delete $filePath
    }
    if {$status>0} {
        return $errorStr
    } else {
        return $commandStr
    }
}


proc ::gnuplotutil::plotXNYNMp {args} {
    # Auxilary function for gnuplotutil::multiplotXNYN, creates command strings and data files
    #  for individual plots
    #  -xlog - enables log scale of x axis
    #  -ylog - enables log scale of y axis
    #  -xlabel - provides x-axis label to display, string must be provided after it
    #  -ylabel - provides y-axis label to display, string must be provided after it
    #  -grid - enables display of grid
    #  -size - set size of the subplot
    #  -origin - set origin of the subplot
    #  -optcmd - provides optional string that may contain additional commands to gnuplot
    #  -path - provides location of temporary file, default is current location
    #  -inline - provides data directly in command string, without creating temporary file, and passes datablock number
    #  -names - enables setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length 2*(number of x-y data pairs)
    #  -lstyles - set individual styles for each graph in the same order as data columns provided,
    #    must have the length 2*(number of x-y data pairs)
    #  -columns -  provides the x and y data to plot, the number of columns is not restricted and must 
    #    be provided at the end of command after all switches
    # Returns: list that contains command script and name of data file
    # Synopsis: ?-xlog? ?-ylog? ?-xlabel string? ?-ylabel string? ?-grid? ?-path string? ?-names list?
    #   -columns xList1 yList1 ?xList2 yList2 ...? 
    set arguments [argparse -inline {
        -xlog
        -ylog
        -inline=
        -xlabel=
        -ylabel=
        -grid
        -size=
        -origin=
        -optcmd=
        {-path= -default {}}
        -names=
        -lstyles=
        {-columns -catchall}
    }]
    initArgStr $arguments size sizeStr {"set size [join [dget $arguments size] ,]"}
    initArgStr $arguments origin originStr {"set origin [join [dget $arguments origin] ,]"}
    initArgStr $arguments xlog xscaleStr {{set logscale x}}
    initArgStr $arguments xlog xscaleStrUnset {{unset logscale x}}
    initArgStr $arguments ylog yscaleStr {{set logscale y}}
    initArgStr $arguments ylog yscaleStrUnset {{unset logscale y}}
    initArgStr $arguments grid gridStr {{set grid}}
    initArgStr $arguments grid gridStrUnset {{unset grid}}
    initArgStr $arguments lstyles lineStyles {[dget $arguments lstyles]}
    initArgStr $arguments names columnNames {[dget $arguments names]}
    initArgStr $arguments xlabel xlabelStr {"set xlabel '[dget $arguments xlabel]'"}
    initArgStr $arguments xlabel xlabelStrUnset {{unset xlabel}}
    initArgStr $arguments ylabel ylabelStr {"set ylabel '[dget $arguments ylabel]'"}
    initArgStr $arguments ylabel ylabelStrUnset {{unset ylabel}}
    initArgStr $arguments optcmd optcmdStr {[dget $arguments optcmd]}
    set columnsNum [llength [dget $arguments columns]]
    if {$columnsNum % 2 != 0} {
        return -code error "Number of data columns '$columnsNum' is odd"
    }
    set dataNum [= {int($columnsNum/2)}]
    set yColumnCount 0
    for {set i 0} {$i<$dataNum} {incr i} {
        set xLen [llength [@ [dget $arguments columns] [= {int($i*2)}]]]
        set yLen [llength [@ [dget $arguments columns] [= {int($i*2+1)}]]]
        lappend xLengths $xLen
        if {$xLen != $yLen} {
            return -code error "Number of points '$yLen' of y-axis data (column [= {1+$yColumnCount}]) doesn't match the\
                    number of points '$xLen' of x-axis data (column $yColumnCount)"
        }
        incr yColumnCount
    }
    # fill output structure with values
    if {([dexist $arguments names])} {
            set headerString {}
        if {[llength $columnNames]!=$dataNum} {
            return -code error "Column names count '[llength $columnNames]' is not the same as count '$dataNum' of data\
                    columns"
        } else {
            for {set i 0} {$i<=$dataNum} {incr i} {
                set headerString "${headerString} { } \"[@ $columnNames $i]\""
            }
            lappend outList $headerString
            set autoTitleStr {set key autotitle columnheader}
        }
    } else {
        set autoTitleStr {}
    }
    if {([dexist $arguments lstyles])} {
        if {[llength $lineStyles]!=$dataNum} {
            return -code error "Lines styles count '[llength $lineStyles]' is not the same as count '$dataNum' of data\
                    columns"
        }
    } else {
        for {set i 0} {$i<$dataNum} {incr i} {
            lappend lineStyles {with lines}
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
    if {[dexist $arguments inline]} {
        set inlineData "\$data[dget $arguments inline] << EOD\n[::csv::joinlist $outList " "]\nEOD\n"
    } else {
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
        puts $resFile [::csv::joinlist $outList { }]
        close $resFile
    }
    # create command strings for gnuplot
    if {[dexist $arguments inline]} {
        set commandStr "$inlineData plot \$data[dget $arguments inline] using 1:2 [@ $lineStyles 0] "
    } else {
        set commandStr "plot '[file join [dget $arguments path] gnuplotTemp${counter}.csv]' using 1:2 [@ $lineStyles 0] "
    }
     for {set i 1} {$i<$dataNum} {incr i} {
        set commandStr  "${commandStr}, '' using [= {$i*2+1}]:[= {$i*2+2}] [@ $lineStyles $i] "
    }
    set commandList [list $optcmdStr $sizeStr $originStr $autoTitleStr $xlabelStr $ylabelStr $xscaleStr $yscaleStr\
                             $gridStr $commandStr $xlabelStrUnset $ylabelStrUnset $xscaleStrUnset $yscaleStrUnset\
                             $gridStrUnset]
    set commandStr [join [lmap elem $commandList {= {$elem eq {} ? [continue] : $elem}}] "\n"]
    if {[dexist $arguments inline]} {
        return [dict create cmdString $commandStr]
    } else {
        return [dict create cmdString $commandStr file $filePath]
    }
    
}

proc ::gnuplotutil::multiplotXNYN {args} {
    # Plots 2D graphs in Gnuplot with individual x-values and using multiplot to display.
    #  -layout - list of layout configurations values, for example, {2 2}
    #  -nodelete - disables deleting of temporary file after end of plotting
    #  -background - enables running gnuplot in background, requires -nodelete or -inline switch
    #  -inline - provides data directly in command string, without creating temporary file
    #  -optcmd - provides optional string that may contain additional commands to gnuplot
    #  -terminal - provides terminal, default 'x11' on linux and 'windows' on windows
    #  -size - provides size of the window, must be list with two elements: width and height in pixels
    #  -darkmode - enables dark mode for graph
    #  -plots - provides the list of individual plots, the number of plots is not restricted and must 
    #    be provided at the end of command after all switches, the inputs syntax is the same as in
    #    [::gnuplotutil::plotXNYNMp]
    # Returns: creates gnuplot window with plotted data, and returns string contains commands sent to gnuplot
    # Synopsis: layoutList ?-background? ?-nodelete? ?-optcmd string? ?-terminal? ?-darkmode? ?-size list?
    #   -columns plotList1 ?plotList2 ...?
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
        -layout=
        -nodelete
        -background
        -inline
        -optcmd=
        -terminal=
        {-size= -default {800 600}}
        -darkmode
        {-plots -catchall}
    }]
    if {[dexist $arguments background]} {
        AliasesKeysCheck $arguments {nodelete inline}
    }
    initArgStr $arguments optcmd optcmdStr {[dget $arguments optcmd]}
    if {[dict exists $arguments layout]} {
        if {[llength [dict get $arguments layout]]>2} {
            return -code error {Length of layout arguments is more than 2}
        } else {
            set layoutStr "set multiplot layout [@ [dict get $arguments layout] 0],[@ [dict get $arguments layout] 1]"
        }
    } else {
        set layoutStr {set multiplot}
    }
    initTerminalStr $arguments terminalStr
    if {[dexist $arguments darkmode]} {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced background rgb 'black'"
        append darkmodeStr "\n" $::gnuplotutil::darkmodeStyle
    } else {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced"
    }
    set i 0
    foreach plot [dget $arguments plots] {
        if {[dexist $arguments inline]} {
            set plotResults [gnuplotutil::plotXNYNMp -inline $i {*}$plot]
        } else {
            set plotResults [gnuplotutil::plotXNYNMp {*}$plot]
            lappend fileNames [dget $plotResults file]
        }
        lappend cmdStrings [dget $plotResults cmdString]
        incr i
    }
    set commandList [list $optcmdStr $darkmodeStr $layoutStr [join $cmdStrings \n] {unset multiplot} {pause mouse close}]
    set commandStr [join [lmap elem $commandList {= {$elem eq {} ? [continue] : $elem}}] "\n"]
    if {[dexist $arguments background]} {
        set status [catch {exec gnuplot << "\n$commandStr\n" & } errorStr]
    } else {
        set status [catch {exec gnuplot << "\n$commandStr\n"} errorStr]
    }
    if {![dexist $arguments nodelete] && ![dexist $arguments inline]} {
        foreach fileName $fileNames {
            file delete $fileName
        }
    }
    if {$status>0} {
        return $errorStr
    } else {
        return $commandStr
    }
}

proc ::gnuplotutil::plotHist {x args} {
    # Plots 2D histograms in Gnuplot with the common x-values.
    #  x - List of strings that contains x-point for 2D histogram
    #  -nodelete - disables deleting of temporary file after end of plotting
    #  -xlabel - provides x-axis label to display, string must be provided after it
    #  -ylabel - provides y-axis label to display, string must be provided after it
    #  -style - provides style of diagram, must be clustered, rowstacked or columnstacked
    #  -gap - provides gap between columns in clustered style, -style argument is required
    #  -boxwidth - provides width of columns, must be in range (0,1]
    #  -fill - provides fill of columns, must be empty or solid
    #  -grid - enables grid of histogram
    #  -background - enables running gnuplot in background, requires -nodelete switch
    #  -inline - provides data directly in command string, without creating temporary file
    #  -terminal - provides terminal, default 'x11' on linux and 'windows' on windows
    #  -size - provides size of the window, must be list with two elements: width and height in pixels
    #  -path - provides location of temporary file, default is current location
    #  -darkmode - enables dark mode for graph
    #  -output - command redirects output to the specified file or device
    #  -transparent - enables transparency to filling of columns, -fill argument is required
    #  -density - provides density of solid filling, -fill argument is required
    #  -border - provides border of columns with particular style, -fill argument is required
    #  -optcmd - provides optional string that may contain additional commands to gnuplot
    #  -names - enables setting the column names of provided data, value must be provided as list
    #    in the same order as data columns provided, must have the length equal to number of y data colums
    #  -columns - provides the y data to plot, the number of columns is not restricted and must be 
    #    provided at the end of command after all switches
    # Returns: creates gnuplot window with plotted data, and returns string contains commands sent to gnuplot
    # Synopsis: x -style ?-gap value? ?-boxwidth value? ?-fill value? ?-transparent? ?-density value? ?-border value?
    #   ?-background? ?-nodelete? ?-xlabel string? ?-ylabel string? ?-optcmd string? ?-terminal? ?-grid? ?-darkmode?
    #   ?-size list? ?-path string? ?-names list? -columns xList1 ?xList2 ...?
    # ```
    # Example:
    # set x1 [list 0 1 2 3 4 5 6]
    # set y1 [list 0 1 4 9 16 25 36]
    # set y2 [list 0 1 8 27 64 125 216]
    # gnuplotutil::plotHist $x1 -style clustered -fill solid -xlabel "x label" -ylabel "y label" -names [list y1 y2]
    # -columns $y1 $y2]
    # ```
    set arguments [argparse -inline {
        {-nodelete -forbid inline}
        -xlabel=
        -ylabel=
        {-style= -enum {clustered rowstacked columnstacked} -required}
        {-gap= -require {style}}
        -optcmd=
        -grid
        -background
        -inline
        -terminal=
        {-size= -default {800 600}}
        {-path= -default {}}
        -darkmode
        -output=
        -names=
        -boxwidth=
        {-fill= -enum {empty solid}}
        {-density= -require {fill}}
        {-transparent -require {fill}}
        {-border= -require {fill}}
        {-columns -catchall}
    }]
    if {[dexist $arguments background]} {
        AliasesKeysCheck $arguments {nodelete inline}
    }
    initArgStr $arguments xlog xscaleStr {{set logscale x}}
    initArgStr $arguments ylog yscaleStr {{set logscale y}}
    initArgStr $arguments grid gridStr {{set grid}}
    initArgStr $arguments output outputStr {"set output '[dget $arguments output]'"}
    initArgStr $arguments xlabel xlabelStr {"set xlabel '[dget $arguments xlabel]'"}
    initArgStr $arguments ylabel ylabelStr {"set ylabel '[dget $arguments ylabel]'"}
    initArgStr $arguments names columnNames {[dget $arguments names]}
    initArgStr $arguments optcmd optcmdStr {[dget $arguments optcmd]}
    initArgStr $arguments boxwidth boxwidthStr {"set boxwidth '[dget $arguments boxwidth]'"}
    initTerminalStr $arguments terminalStr
    if {[dexist $arguments darkmode]} {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced background rgb 'black'"
        append darkmodeStr "\n" $::gnuplotutil::darkmodeStyle
    } else {
        set darkmodeStr "set term $terminalStr size [join [dget $arguments size] ,] noenhanced"
    }
    if {[dexist $arguments fill]} {
        if {[dexist $arguments transparent]} {
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
    } else {
        set fillStr {}
    }
    if {[dexist $arguments style]} {
        if {([dexist $arguments gap]) && ([dget $arguments style] in {clustered})} {
            set styleStr "set style histogram [dget $arguments style] gap [dget $arguments gap]"
        } else {
            set styleStr "set style histogram [dget $arguments style]"
        }
    } else {
        set styleStr {}
    }
    set yColumnCount 0
    foreach val [dget $arguments columns] {
        if {[llength $val] != [llength $x]} {
            return -code error "Number of points '[llength $val]' of y-axis data (column $yColumnCount) doesn't match\
                    the number of points '[llength $x]' of x-axis data"
            incr yColumnCount
        }
    }
    # fill output structure with values
    set numCol [llength [dget $arguments columns]]
    if {([dexist $arguments names])} {
        if {[llength $columnNames]!=[= {$numCol}]} {
            return -code error "Column names count '[llength $columnNames]' is not the same as count '$numCol' of data\
                    columns"
        } else {
            foreach columnName $columnNames {
                lappend processedNames "\"$columnName\""
            }
            lappend outList "{ } [join $processedNames]"
            set autoTitleStr {set key autotitle columnheader}
        }
    } else {
        set autoTitleStr {}
    }
    set numRow [llength $x]
    for {set i 0} {$i<$numRow} {incr i} {
        set row [@ $x $i]
        foreach val [dget $arguments columns] {
            lappend row [@ $val $i]
        }
        lappend outList $row
    }
    # save data to temporary file or use inline data block
    if {[dexist $arguments inline]} {
        set inlineData "\$data << EOD\n[::csv::joinlist $outList " "]\nEOD\n"
    } else {
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
        puts $resFile [::csv::joinlist $outList { }]
        close $resFile
    }
    # create command strings for gnuplot
    if {[dexist $arguments inline]} {
        set commandStr "$inlineData plot \$data using 2:xtic(1) "
    } else {
        set commandStr "plot 'gnuplotTemp${counter}.csv' using 2:xtic(1)"
    }
    for {set i 1} {$i<$numCol} {incr i} {
        set commandStr  "${commandStr}, '' using [= {$i+2}]"
    }
    set commandList [list {set mouse} $outputStr $darkmodeStr {set style data histogram} $styleStr $fillStr $optcmdStr\
                             $gridStr $autoTitleStr $xlabelStr $ylabelStr $boxwidthStr $commandStr {pause mouse close}]
    set commandStr [join [lmap elem $commandList {= {$elem eq {} ? [continue] : $elem}}] "\n"]
    if {[dexist $arguments background]} {
        set status [catch {exec gnuplot << "\n$commandStr\n" & } errorStr]
    } else {
        set status [catch {exec gnuplot << "\n$commandStr\n"} errorStr]
    }
    if {![dexist $arguments nodelete] && ![dexist $arguments inline]} {
        file delete $filePath
    }
    if {$status>0} {
        return $errorStr
    } else {
        return $commandStr
    }
}
