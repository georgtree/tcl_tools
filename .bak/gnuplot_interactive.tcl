#!/usr/local/bin/expectkjp

# 
# tkgnuplot: tkgproll 繧偵さ繝斐�縺� term=tkcanvas 縺ｨ expectk 逕ｨ縺ｫ譖ｸ縺肴鋤縺�
# 
#     [2002/09/19] ITO Akinori.  add terminal option dialog and help button,
#                                    datafile manager, key location menu.
#     [2000/06/23] OSHIRO Naoki. add bind for wheel mouse (showCurrent, Help).
#                                evaluation change for 3.7 patchlevel 1.
#     [2000/02/26] OSHIRO Naoki. help: keep yview history and paging by keys.
#     [2000/02/25] OSHIRO Naoki. add popup menu to popupCanvasSnapshot.
#     [1999/11/02] OSHIRO Naoki. add window focus and grab for gp_dialog proc.
#     [1999/06/17] OSHIRO Naoki. add snapshot editor/gif image generator.
#     [1999/06/14] OSHIRO Naoki. add command history.
#     [1999/06/09] OSHIRO Naoki. add gp_helptopic_ignore var.
#     [1999/06/05] OSHIRO Naoki. add key bind of changeView/Scale.
#     [1999/06/04] OSHIRO Naoki. add canvas snapshot.
#     [1999/05/30] OSHIRO Naoki. add view scale.
#     [1999/02/07] OSHIRO Naoki.
#

#
# Requirements:
#   a. GNUPLOT 3.6 after (need tkcanvas terminal).
#   b. Expectk (for interactive access to GNUPLOT).
#


############################################################
# Initialize
set width 320
set height 200

switch 1 {
    0 {set gp_program "./gnuplot"}
    1 {set gp_program "gnuplot"}
    2 {set gp_program "gnuplot37"}
}

set gp_term "tkcanvas"
set gp_plotform "plot"
set gp_curgraph "sin(x)"
set gp_web_browser "netscape -remote \"OpenURL(%s)\""
set gp_initfile "$env(HOME)/.tkgprc"
set gp_savescriptfilename "tkgnuplot_tmp.gpt"
set gp_termname tgif
set gp_termopt ""
set gp_use_tmpfile 1
set gp_x11_size "350x240"
set gp_x11_sizesub  "150x150"
set gp_datafilemgr_window 0

############################################################
# Load user setting file
if {[file exists $gp_initfile]} {
    source $gp_initfile
}

############################################################
# Make widgets

############################################################
# frame
frame .m -borderwidth 2 -relief raised; # menu
frame .com                            ; # command
frame .fc -borderwidth 2              ; # canvas

############################################################
# canvas
label .com.l -text "Command:"
entry .com.e
canvas .fc.c -background white -width $width -height $height

############################################################
# menu
menubutton .m.file -menu .m.file.menu -text "File" -underline 0
menubutton .m.edit -menu .m.edit.menu -text "Edit" -underline 0
menubutton .m.plot -menu .m.plot.menu -text "Plot" -underline 0
menubutton .m.style -menu .m.style.menu -text "Style" -underline 0
menubutton .m.option -menu .m.option.menu -text "Options" -underline 0
menubutton .m.about -menu .m.about.menu -text "About" -underline 0

############################################################
#
pack .m.file .m.edit .m.plot .m.style .m.option -side left
pack .m.about -side right
pack .fc.c -expand yes -fill both -side bottom
pack .com.l -side left
pack .com.e -fill x
pack .m -anchor nw -side top -fill x
pack .com -anchor nw -side top -fill x
pack .fc -anchor nw -side top -fill both -expand yes
update

############################################################
set env(PAGER) "cat"

############################################################
#
log_user 0
spawn -noecho $gp_program -geometry $gp_x11_sizesub
set gp_subspawnid $spawn_id
expect "gnuplot>"
exp_send "set term $gp_term\r"
expect "gnuplot>"

############################################################
#
spawn -noecho $gp_program -geometry $gp_x11_size
set gp_spawnid $spawn_id
expect "gnuplot>"
exp_send "set term $gp_term\r"
expect "gnuplot>"
exp_send "show view\r"
expect "view is"
expect -re "(\[0-9\]+) rot_x, "
set xroll $expect_out(1,string)
expect -re "(\[0-9\]+) rot_z, "
set zroll $expect_out(1,string)
expect -re "(\[0-9\]+) scale, "
set splot_scale $expect_out(1,string)
expect -re "(\[0-9\]+) scale_z"
set splot_scale_z $expect_out(1,string)
expect "gnuplot>"

############################################################
# menu contents
# (these may evaluate after first update and invoke gnuplot process)
set m .m.about.menu
menu $m
$m add command -label "Gnuplot Help" -underline 8 -command "set idx \[$m index active\]; displayHelp {{} 0}; after 3 popupHelp $m \$idx"
$m add command -label "Gnuplot Version" -underline 8 -command {displayGnuplotVersion}
$m add separator
$m add cascade -label "Window" -underline 0 -menu .m.about.menu.window
$m add separator
$m add command -label "About..." -underline 0 -command {displayAbout}

set m .m.about.menu.window
menu $m
$m add command -label "Zoom +" -command {setWindowSize .fc.c [expr [.fc.c cget -width]*2] [expr [.fc.c cget -height]*2]}
$m add command -label "Zoom -" -command {setWindowSize .fc.c [expr [.fc.c cget -width]/2] [expr [.fc.c cget -height]/2]}
$m add separator
$m add command -label "320x320" -command "setWindowSize .fc.c 320 320"
$m add command -label "320x200" -command "setWindowSize .fc.c 320 200"
$m add command -label "320x150" -command "setWindowSize .fc.c 320 150"
$m add command -label "320x100" -command "setWindowSize .fc.c 320 100"
$m add command -label "200x320" -command "setWindowSize .fc.c 200 320"

set m .m.file.menu
menu $m
$m add command -label "Data File Open" -underline 0 -command openPlotFile
$m add command -label "Open Datafile Manager" -command openDatafileManager
$m add command -label "Load Script" -underline 0 -command loadScriptFile
$m add command -label "Save Script" -underline 0 -command {gprollSaveScriptPre}
$m add command -label ""
$m add command -label "Print" -underline 0 -command {gprollPrintPre}
$m add command -label "Print Setup" -underline 7 -command {gprollPrintPre}
$m add separator
$m add command -label "Show Current" -underline 5 -command {gp_showCurrent}
$m add separator
$m add command -label "Quit" -underline 0 -command {exit}

set m .m.edit.menu
menu $m
$m add command -label "Snapshot" -underline 0 -command {popupCanvasSnapshot $gp_canvas}

set m .m.plot.menu
menu $m
$m add radiobutton -label "2D Plot" -underline 0 -value "plot" -variable gp_plotform -command changePlotForm
$m add radiobutton -label "3D Plot (splot)" -underline 0 -value "splot" -variable gp_plotform -command  changePlotForm
$m add command -label "Replot" -underline 0 -command "updateCanvas {rep}"
$m add separator
$m add checkbutton -label "ViewBox Update" -underline 4 -variable gp_viewbox_update
$m add command -label "View Point Selector" -underline 0 -command {makeViewPointSelector}
$m add checkbutton -label "Main Terminal (X11)" -underline 0 -variable gp_term -onvalue x11 -offvalue tkcanvas -command {updateCanvas [list "set term x11 reset; set term $gp_term" rep]}

set m .m.option.menu
menu $m
menu $m.keymenu
$m add cascade -label "Key positon" -menu $m.keymenu
$m add checkbutton -label "Grid" -underline 0 -onvalue grid -offvalue nogrid -variable chkgri -command {updateCanvas [list "set $chkgri" rep]}
$m add separator
$m add checkbutton -label "Parametric" -underline 0 -onvalue parametric -offvalue noparametric -variable chkpar -command {updateCanvas [list "set $chkpar" rep]}
$m add checkbutton -label "Dgrid3D" -underline 0 -onvalue dgrid3d -offvalue nodgrid3d -variable chkdgr -command {updateCanvas [list "set $chkdgr" rep]}
$m add checkbutton -label "Hidden3D" -underline 0 -onvalue hidden3d -offvalue nohidden3d -variable chkhid -command {updateCanvas [list "set $chkhid" rep]}
$m add checkbutton -label "Contour (b)" -underline 0 -onvalue contour -offvalue nocontour -variable chkcntr -command {updateCanvas [list "set $chkcntr" rep]}
$m add separator
$m add command -label "Label" -underline 0 -state disabled
$m add command -label "Range" -underline 0 -state disabled
$m add command -label "Data Using" -underline 0 -state disabled

$m.keymenu add command -label "Upper Left" -command {updateCanvas [list "set key left top" rep]}
$m.keymenu add command -label "Upper Right" -command {updateCanvas [list "set key right top" rep]}
$m.keymenu add command -label "Lower Left" -command {updateCanvas [list "set key left bottom" rep]}
$m.keymenu add command -label "Lower Right" -command {updateCanvas [list "set key right bottom" rep]}
$m.keymenu add command -label "Outside" -command {updateCanvas [list "set key outside" rep]}
$m.keymenu add command -label "None" -command {updateCanvas [list "set nokey" rep]}


set m .m.style.menu
menu $m
$m add radiobutton -label "Lines" -underline 0 -value "data style lines" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Points" -underline 0 -value "data style points" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Linespoints" -underline 2 -value "data style linespoints" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Dots" -underline 0 -value "data style dots" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Steps" -underline 0 -value "data style steps" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Impulses" -underline 0 -value "data style impulses" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Errorbars" -underline 0 -value "data style errorbars" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Boxes" -underline 0 -value "data style boxes" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}
$m add radiobutton -label "Boxerrorbars" -underline 1 -value "data style boxerrorbars" -variable chkstl -command {updateCanvas [list "set $chkstl" rep]}

############################################################
# Initialize (internal variables)
set gp_com ""
set gp_outputfilename ""
set gp_preext ""
set gp_comhist ""
set gp_comhist_n 0
set gp_helptopic ""
set gp_helptopic_ignore {
    {gnuplot} {using 1:2:4} {using ::4}
    {set data time} {column(x)} {valid(x)}
    {ratio} {pi} {)} {[]} {[]} {-} {!} {'-'} {#} {&&} {||} {$} {$$}
    {$$n} {t**2} {sin(t)}
    {max} {min} {set xdata time} {set ydata time} {reverse} {noreverse}
    {column(n)} {set output "STDOUT"} splot_overview
    {index <m>} {index <m>:<n>} {index <m>:<n>:<p>}
    {plot 'file' using 1} {plot 'file' using 0:1}
    {set xrange [1:0]} {set xrange [0:1] reverse}
    {small} {large} {top} {bottom} {rotate} {left} {right} {center}
    {set title ,-1} {notitle} {title ''} {title ' '}
    {outside} {below} {box {...}} {linetype} {samplen 4} {spacing 1.25}
    {title "<text>"} {nobox} {set key left Left reverse} {set clabel}
    {first} {second} {nohead} {linewidth} {lt} {lw} {writeback}
    {plot sin(t),cos(t)} {ratio 1} {square} {nosquare} {noratio}
    {-display} {display} {xterm} {set terminal x11 <n>} {gplt <n>}
    {-persist} {close} {feed} {iris4d} {comp} {landscape} 
    portrait default defaults solid defaultplex simplex duplex iso_8859_1
    ISO-Latin1 cp850 cp437 {set encoding iso_8859_1} {"<fontname>"}
    {<fontsize>} {-rv} {gnuplot*reverseVideo: on} noenhanced dashed
    pointtype intensity {blue, 0.5} tek40xx norotate fontsize font
    winword6 width interval big metric inches depth thickness bfig
    {pause 0} {plot data-file using} {set xtics axis nomirror}
    {set ytics axis nomirror} {set grid polar} {set range} 
    {set size square} {set angles radians} {?:} 1/0 lf 
    {using 0+(complicated expression)} {plot 'file' using 1:2}
    {plot 'file'} file {plot 'file' using ($1):($2)} tm_hour e s v t
    tm_mday tm_min tm_mon tm_sec tm_wday tm_yday tm_year 
    {copy file /b lpt1:} {set {x/y}label} {<vert>} {<horiz>} detailed 
    {set encoding cp850} hp7580b hp7550 cg_times univers stick colour
    polyline vectors medium {-gray} auxfile .tex .ps hacktext nounit
    {set label "Hallo" at x,y font "Helvetica,34"} {"Helvetica"} 18
    {[1,1]} base both {set nosurface; set contour base} {""} {"-"} 
    {set xlabel -1} {set syntax} {set logscale xy} start_point
    start_block block_incr smooth unique cntrparams {splot grid data} 
    {with lines} {set contour surface} {with linespoints}
    {offset <offset>} {undefined <level>} {set {no}hidden3d}
    {{no}mirror} {offset 0} {trianglepattern <bitpattern>} noundefined
    noaltdiagonal undefined altdiagonal trianglepattern bentover
    cubicspline linear bspline order levels incremental discrete
    {levels discrete} {set cntrparms levels <n>}
    {set cntrparam levels <n>} -clear -mono -raise -noraise -tvtwm 
    {gnuplot*pointsize: <v>} {-pointsize <v>} {-pointsize 2} 
    {-pointsize 0.5} jk j k axisDashes 
    {set terminal xlib; set output "|gnuplot_x11"} {set output "PRN"} 
    {cos(u)*cos(v),cos(u)*sin(v),sin(u)} {using 1:2:3:(1)}
    {fit multibranch} via .old {update 'fred'}
    {!rename fred fred.old; update 'fred.old' 'fred'}
    /dev/lp {set missing 'NaNq'} adjustable_parameters beginners_guide 
    control error_estimate errors parameters {via "file"}
    {via var1, var2, ...} {boxwidth = -2.0} {set boxwidth -2.0} 
    {set style <style>} {set pointsize 2; plot x w p ps 3} {<integer>} 
    axis nomirror mirror {set {x|x2|y|y2|z}tics} {axis|border} 
    {border mirror norotate} specifiers 
    {border nomirror norotate} {{axis | border}} autofreq {set xtic (} 
    all one two {noclip points} {clip one} {noclip two}
    {set clip points} in version 
    {set xzeroaxis l; set yzeroaxis l} {set zeroaxis l} 
    {set noxzeroaxis; set noyzeroaxis} {set format x "string"} 
    {{x,y,z}{d,m}tics} nolinestyle {boldface} boldface {help plotting}
    {p f(x) w l} start-up logout gulam endcli 
    {plot f(x) with lines} GNUPLOT.INI 
    {fit f(x) 'file' via} gnufit {Time/Date data} enhpost {"%l %L"} 
    gif leastsq {run leastsq} {plot data-file special-filenames} 
    {plot 'datafile' using 1:($2-f($1))}
    {11:11  25/12/76  21.0} {using n:n} 
    {star_point} {end_point} {point_incr} {end_block}
}
set gp_helptopichist() ""
set gp_helphist {{"" 0}}
set gp_helpwindow 0
set gp_viewrolling 0
set gp_viewscaling 0
set gp_viewbox_update 1
set gp_snapshot_id 0
set snapshot_edit 1
set snapshot_cur_mode "select"
set snapshot_cur_edit_id ""
set snapshot_cur_edit_coord ""
set snapshot_cur_scaleratio .9
set snapshot_grab(x) ""
set snapshot_grab(y) ""
set snapshot_grab(id) ""
set updating 0

############################################################
# term setup
foreach {term ext} {\
  cgm .cgm fig .fig png .png pstex .tex tkcanvas .tk pstricks .ps \
  tgif .obj postscript .ps texdraw .tex emtex .tex latex .tex \
  pslatex .tex pstricks .tex eepc .eepic gpic .gpic tpic .tpic \
  mf .mf mif .mif dxf .dxf table .tbl aed512 .aed aed767 .aed \
  aifm .aif bitgraph .bit corel .cor dxy800a .dxy epson_180dpi .txt \
  epson_60dpi .txt epson_lx800 .txt excl .txt hp2623A .txt hp2648 .txt \
  hp7580B .txt hp500c .dkj hpgl .txt hpljii .txt hpdj .txt hppj .txt \
  imagen .txt kc_tek40xx .tek km_tek40xx .tek tek410x .tek tek40xx .tek \
  vttek .tek nec_cp6 .cp6 okidata .oki pbm .pbm pcl5 .txt \
  prescribe .txt kyo .kyo qms .qms regis .txt relanar .txt starc .txt \
  tandy_60dpi .txt vx384 .vec\
} {
    set gp_termext($term) $ext
}
set gp_termlist ""

proc initTermList {} {
    global gp_termlist

    exp_send "set term\r"
    expect "Available terminal types:"
    expect "gnuplot>"
    set tmp [lreplace [split $expect_out(buffer) "\n"] end end]
    foreach t $tmp {
	if {[regexp "^\[ \n\r\t]*$" $t]} {continue}
	lappend gp_termlist [list [lindex $t 0] [lrange $t 1 end]]
    }
}

initTermList

############################################################
# Logo image for about menu.
set gplogo_gif {
R0lGODdhSAAzAMIAAAAAAAD/AP8AAP///wAA/wAAAAAAAAAAACwAAAAASAAz
AAAD/giz3P4wykmdGkDlzbv/YCiOmFUx15mqT+C+b2aedN3AuKDvAraWtqAE
58ARZY2fUPha+mbOoEtCWBCu2OwzGZUGugskCkz7krcl5fnKmAp7lp860oNP
qmxBwF6rx6EUcHwQbANVZoOBC4NiYTR2iQ1VVgSINpBJcid8kVYOk4uPDXyN
QIoMnYVtoJ0PnJmAEoORoAsuha0OsyiaFbuftQNmuJu6vGEKuaHGksHCDJPK
A4l2pdKRcFgQZpTXEHDWvt+GzrbclOWj42jLE4naQ9/w68ylALnZWQTK5+rk
853AyRmkT4u/ePSgFQSIDJg+ZgmL9EPlrpk+MRrwyUIYyBGiK3YlWonk2JEi
HZDJTm6MMPGgx4/2pqlc2aJiyVExA56SaPOju5wzg7bZ+dJVTJlFfRYRl1TX
UWpMlxJtJwuJjAtQo5rTSrXqjKxTWyo1SeEo0q40bYkiW7bX2bc9hUmjOhcl
27pnxSasaxYp3ryX0EroKyhIjz2B4U7oO02HYTeX/mI0BUbvmWNcyFi+3DBz
FMicB7tdAjp0BMZlSps+PZoCkdUqWgszohp2BasKaAcYwbu37xC2gz9YUWpx
jTmnjyMXHjoBADs=
}
image create photo gplogo -data $gplogo_gif -format gif
unset gplogo_gif

############################################################
# sets: set apply to lists (like foreach).
proc sets {{vars} {vals}} {
    foreach var $vars {
	upvar $var x
	set x [lindex $vals 0]
	set vals [lreplace $vals 0 0]
    }
}

############################################################
#
proc lreverse {var} {
    set rev_var ""
    while {$var!=""} {
	append rev_var " [lindex $var end]"
	set var [lreplace $var end end]
    }
    return $rev_var
}

############################################################
# send URL
proc sendURL {url} {
    global gp_web_browser
    eval exec [format $gp_web_browser $url]
}

############################################################
# dummy gnuplot proc
proc gnuplot {can} {}

############################################################
# print
proc gprollPrint {} {
    global gp_termname gp_termopt gp_outputfilename
    
    if {$gp_outputfilename==""} {return}
    foreach c [list "set term $gp_termname $gp_termopt" \
	            "set output '$gp_outputfilename'" \
		    "rep" "set output"] {
	exp_send "$c\r"
	expect "gnuplot>"
    }
}

proc gprollPrintPre {} {
    global gp_termname gp_termopt gp_outputfilename

    set t .p
    toplevel $t
    wm title $t "tkgnuplot: Print"
    
    frame $t.t
    frame $t.f
    frame $t.p -borderwidth 2
    frame $t.p.dummy

    label $t.t.l -text "Term: $gp_termname"
    button $t.t.b -text "Sel" -command "gprollTermSelector"
    label $t.f.l -text "File:"
    entry $t.f.e -width 20 -textvariable gp_outputfilename
    button $t.p.dummy.o -text "OK" -command "destroy $t; gprollPrint"
    button $t.p.dummy.c -text "Cancel" -command "destroy $t"

    bind $t <Return>    "destroy $t"
    bind $t <Control-c> "destroy $t"
    bind $t <Control-q> "destroy $t"

    pack $t.t.l -side left
    pack $t.t.b -side right -fill x -expand no
    pack $t.f.l $t.f.e -side left
    pack $t.p.dummy.o $t.p.dummy.c -side left -anchor center
    pack $t.p.dummy -side top
    pack $t.t $t.f -side top -anchor w -fill x
    pack $t.p -anchor center -fill x -expand yes

    if {$gp_outputfilename==""} {
	set gp_outputfilename "foo"
	gprollPrintPreUpdate
    }
    return $t
}

proc gprollPrintPreUpdate {} {
    global gp_termname gp_outputfilename
    global gp_preext gp_termext

    set cur    $gp_termname
    set fname  $gp_outputfilename
    set curExt $gp_termext($cur)
    set t .p
    
    regsub "\." $gp_preext "\\." gp_preext
    regsub "$gp_preext$" $fname "" fname
    append fname "$curExt"
    
    $t.t.l config -text "Term: $cur"
    $t.f.e delete 0 end
    $t.f.e insert 0 $fname
}

proc gprollTermSelector {} {
    global gp_termlist gp_termname gp_outputfilename
    global gp_termopt
    global gp_termext
    global gp_preext

    toplevel .t
    wm title .t "gproll: Terminal Selector"

    set gp_preext $gp_termext($gp_termname)
    
    label .t.l -text "Terminals" -borderwidth 2 -relief raise
    frame .t.f1
    label .t.f1.l -text "Option:"
    entry .t.f1.opt -width 40
    .t.f1.opt insert end $gp_termopt
    listbox .t.lb -width 10 -selectmode single -borderwidth 0 -bg "#ffffff" \
	    -relief sunken -yscrollcommand ".t.scl set"
    listbox .t.lb_comment -width 20 -borderwidth 0 -bg "#ffffff"
    set selcom gprollTermSelectorCommand
    scrollbar .t.scl -orient vertical \
	    -command "$selcom .t.lb .t.lb_comment yview"
    frame .t.p
    label .t.p.cur -text "$gp_termname"
    button .t.p.o -text ok \
	    -command {set gp_termname [.t.lb get [.t.lb curselection]]; \
                      set gp_termopt [.t.f1.opt get]; \
	              destroy .t; gprollPrintPreUpdate}
    button .t.p.c -text cancel -command "destroy .t"
    button .t.p.h -text help -command terminalHelpCommand
    pack .t.l -side top -fill x
    pack .t.f1 -side top -fill x
    pack .t.f1.l -side left
    pack .t.f1.opt -side left
    pack .t.lb .t.lb_comment .t.scl -side left -fill y
    pack .t.p.cur .t.p.o .t.p.c .t.p.h -side top -expand yes -fill x
    pack .t.p -side top -anchor n
    
    foreach m $gp_termlist {
	set f [lindex $m 0]
	.t.lb         insert end $f
	.t.lb_comment insert end [lindex $m 1]
    }
    set curId [lsearch -glob $gp_termlist [format "%s *" $gp_termname]]
    $selcom .t.lb .t.lb_comment see $curId
    .t.lb select set $curId

    bind .t <Return>    "destroy .t; set gp_termname \"tgif\""
    bind .t <Control-c> "destroy .t"
    bind .t.lb <ButtonRelease-1> \
	    ".t.p.cur config -text \[.t.lb get \[.t.lb curselection]]"
    bind .t.lb_comment <ButtonRelease-1> \
	    ".t.lb select set \[.t.lb_comment curselection];\
	     .t.p.cur config -text \[.t.lb get \[.t.lb curselection]]"
    bind .t <q> "destroy .t"
}

proc gprollTermSelectorCommand { w1 w2 type args } {
    eval $w1 $type $args
    eval $w2 $type $args
}

proc terminalHelpCommand {} {
    global gp_termname
    global gp_helptopic gp_helpwindow

    set gp_termname [.t.p.cur cget -text]
    displayHelp [list [list set terminal $gp_termname] 0]
}

############################################################
# save script
proc gprollSetSaveScriptFileName {{w}} {
    global gp_savescriptfilename
    set gp_savescriptfilename [$w get]
}

proc gprollSaveScriptPre {} {
    global gp_savescriptfilename

    toplevel .p
    set t .p
    wm title $t "gproll: Save Script"
    
    frame $t.f
    frame $t.p -borderwidth 2
    frame $t.p.dummy

    label $t.f.l -text "Script Name:"
    entry $t.f.e -width 20
    button $t.p.dummy.o -text "OK" -command "gprollSetSaveScriptFileName $t.f.e; destroy $t"
    button $t.p.dummy.c -text "Cancel" -command "destroy $t"

    bind $t <Return>    "gprollSetSaveScriptFileName $t.f.e; destroy $t"
    bind $t <Control-c> "destroy $t"
    bind $t <q> "destroy $t"

    pack $t.f.l $t.f.e -side left
    pack $t.p.dummy.o $t.p.dummy.c -side left -anchor center
    pack $t.p.dummy -side top
    pack $t.f -side top -anchor w -fill x
    pack $t.p -anchor center -fill x -expand yes
    $t.f.e insert 0 $gp_savescriptfilename

    tkwait variable gp_savescriptfilename
    set fid [open "$gp_savescriptfilename" w]
    gprollSaveScript $fid
    close $fid
}

proc gprollSaveScript {{fid}} {
    set ftmp "/tmp/tkgproll_[pid].gpt"

    exp_send "save '$ftmp'\r"
    expect "gnuplot>"
    set ftmpId [open $ftmp "r"]
    exec "sleep" "1"
    while {[gets $ftmpId tmp]>-1} {
	puts $fid $tmp
    }
    close $ftmpId
    exec "rm" "$ftmp"
}

proc gp_getCurrentState {} {
    set ftmp "/tmp/tkgproll_[pid].gpt"
    exp_send "save '$ftmp'\r"
    expect "gnuplot>"
    set ftmpId [open $ftmp "r"]
    #exec "sleep" "1"
    set buf ""
    while {[gets $ftmpId tmp]>-1} {
	append buf "$tmp\n"
    }
    close $ftmpId
    exec "rm" "$ftmp"
    return $buf
}

proc gp_setCurrentState {{buf}} {
    set ftmp "/tmp/tkgproll_[pid].gpt"
    set ftmpId [open $ftmp "w"]
    foreach str [list $buf] {
	puts $ftmpId "$str"
    }
    close $ftmpId
    exp_send "load '$ftmp'\r"
    expect "gnuplot>"
    exec "rm" "$ftmp"
}

proc gp_pushCurrentState {} {
    global gp_currentstate
    
    set gp_currentstate [gp_getCurrentState]
}

proc gp_popCurrentState {} {
    global gp_currentstate
    
    gp_setCurrentState $gp_currentstate
}

proc gp_showCurrent {} {
    set buf [gp_getCurrentState]
    set t .showcur
    toplevel $t
    wm title $t "Tkgnuplot: Current State"
    text $t.text -width 80 -height 40 -background white \
	-state disabled -yscrollcommand "$t.scroll set"
    scrollbar $t.scroll -orient vertical -command "$t.text yview"
    frame  $t.f
    button $t.f.edit -text "Edit" -state disabled
    button $t.f.save -text "Save" -command "gprollSaveScriptPre"
    button $t.f.close -text "Close" -command "destroy $t"
    
    pack $t.f.edit $t.f.save $t.f.close -side left
    pack $t.f -side bottom
    pack $t.scroll -side right -expand no -fill y
    pack $t.text -fill both -expand true -side top

    bind $t <q> "destroy $t"
    bind $t <Control-w> "destroy $t"

    # bind for wheel mouse
    bind $t <Button-4> [list $t.text yview scroll -5 units]
    bind $t <Button-5> [list $t.text yview scroll 5 units]
    bind $t <Shift-Button-4> [list $t.text yview scroll -1 units]
    bind $t <Shift-Button-5> [list $t.text yview scroll 1 units]
    bind $t <Control-Button-4> [list $t.text yview scroll -1 page]
    bind $t <Control-Button-5> [list $t.text yview scroll 1 page]

    $t.text configure -state normal
    $t.text insert 0.0 $buf
    $t.text configure -state disabled
}

############################################################
#
proc displayAbout {} {
    set t [toplevel .gpab]
    wm title $t "Tkgnuplot About..."
    set c $t.c
    set width 250
    set height 150
    canvas $c -width $width -height $height
    $c create text [expr $width/2] [expr $height*.56] \
	    -justify center -font {Helvetica 14} \
	    -text "Tkgproll, Tkgnuplot\nGNUPLOT graphical user interface"
    $c create text [expr $width*.5] [expr $height*.85] \
	    -justify center -font {Helvetica 12} \
	    -text "OSHIRO Naoki\nn-oshiro@tec.u-ryukyu.ac.jp\n1996-1999"
    $c create image [expr $width*.5] [expr $height*.25] -image gplogo
    button $t.b -text OK -command "destroy $t"
    pack $c $t.b -side top
    bind $t <Key-Return> "destroy $t; focus -force ."
    focus $t
    grab $t
}

proc displayGnuplotVersion {} {
    set t [toplevel .gpgv]
    wm title $t "Tkgnuplot: GNUPLOT version"
    set c $t.c
    set width 450
    set height 250
    canvas $c -width $width -height $height -background white
    exp_send "show version\r"
    expect "show version\r"
    expect "gnuplot>"
    set ver $expect_out(buffer)
    regsub "\ngnuplot>$" $ver "" ver
    regsub "^\[ \t\n\r]*" $ver "" ver
    regsub "\[ \t\n\r]*$" $ver "" ver
    regsub -all "\r" $ver "" ver
    regsub -all "\n\t" $ver "\n" ver
    $c create text 10 10 -justify left -anchor nw -font {Helvetica 14} \
	    -text "$ver"
    button $t.b -text OK -command "destroy $t; focus -force ."
    bind $t <Key-Return> "destroy $t; focus -force ."
    pack $c -expand yes -fill both -side top
    pack $t.b
    focus $t
    grab $t
}

############################################################
#
# GetValue: 縲卦cl/Tk 蜈･髢縲阪え繧ｧ繝ｫ繝�, p.276-277.
proc getValue {{string} {init ""}} {
    global prompt
    set f [toplevel .prompt -borderwidth 10]
    message $f.msg -text $string -width 200
    entry $f.entry -textvariable prompt(result)
    if {$init!=""} {$f.entry delete 0 end; $f.entry insert 0 $init}
    set b [frame $f.buttons -bd 10]
    pack $f.msg $f.entry $f.buttons -side top -fill x
    button $b.ok -text OK \
	    -command {set prompt(ok) 1} -underline 0
    button $b.cancel -text Cancel \
	    -command {set prompt(ok) 0} -underline 0
    pack $b.ok -side left
    pack $b.cancel -side right

    # 繝舌う繝ｳ繝峨ｒ險ｭ螳壹☆繧�
    foreach w [list $f.entry $b.ok $b.cancel] {
	bindtags $w [list .prompt [winfo class $w] $w all]
    }
    bind .prompt <Alt-o> "focus $b.ok; break"
    bind .prompt <Alt-c> "focus $b.cancel; break"
    bind .prompt <Alt-Key> break
    bind .prompt <Return> {set prompt(ok) 1}
    bind .prompt <Control-c> {set prompt(ok) 0}
    
    focus $f.entry
    grab $f
    tkwait variable prompt(ok)
    grab release $f
    after 500 destroy $f
    if {$prompt(ok)} {
	return $prompt(result)
    } else {
	return {}
    }
}

############################################################
# Icon images
set quit_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIkjI+py+0P
D5gQyGdNRjvsnlifp5ETVWZiapKte5YvqKoaGOUFADs=
}
set lupe_plus_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIqjI+pAe1r
nATrHXtbpEznvyHaRHkh2YlcGmach21rN8to8kxKDPF9DSkAADs=
}
set lupe_minus_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAInjI+pAe1r
nATrHXubwoxWH1GTCHadZGaQlpWhy3HvuGlT7X75ByUFADs=
}
set arrow_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIYjI+py+0P
FYgBzGctzrzn+kUadVHmiT4FADs=
}
set box_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIljI8ZwO3f
lgRz0luxy5z1HGmdSC7hd5XkqZqo5bXpm0J2pORGAQA7
}
set circle_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIjjAOpcI1u
mJPwHVotzm9n5lUg14xkZJ2mipJY2JbityQnWQAAOw==
}
set fline_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAImjI+ZwKDX
kFNzvRpYvkZnbEEfuH0SGFHPma6Yp3YOzL4rd0v5WgAAOw==
}
set line_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAISjI+py+0P
o5wM2IszoLz7DwYFADs=
}
set oval_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIjjAOpcI3P
ooNUHolp3Th7z0FgF46jWG6pZZyMc07Iksj2VAAAOw==
}
set pixel_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIXjI+py43g
YoCSUXOrdvnt72GgOCrdVgAAOw==
}
set pline_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIjjGGpG+AM
UZOwrRcjTfvufnGVeIzlOVIgg6ysZZZuGJN1UgAAOw==
}
set poly_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIpjGGpG+AM
34MH2cls2zhJ3nTaGHogiVQnl66o96Ix69bOfZ9thnfUUgAAOw==
}
set rect_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIfjI8ZwO3P
lFxgqmgRzmZzn4GWOJGSeVVcp67Q66xIAQA7
}
set select_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIkhIOpaQ27
nINMzngpsrqG1n2POGolaCooVG5HWLXhCtPzC4sFADs=
}
set text_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIlDI6ZYerH
IGuTmmoniFhqrG3g6I1VaUZiGrLn6qKpTCLsA7tYAQA7
}
set colSpoit_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAImjI+gih3w
InRSTsegplXfllXYtmHGwpgnt7bc9akRO8dmypa0uxcAOw==
}
set print_icon_gif {
R0lGODlhEAAQAPABAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIpjA2pCxft
DnQtoUuj1PX5n2ngJk4Pg1pex55nCotlRcuqTJn4C6O7VgAAOw==
}
set replot_icon_gif {
R0lGODlhEAAQAIAAAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIpjI+pwIzw
moSB1nYmxYs7dTlcMl1d+YGkpWbpabzrJsev5I62Vu96UAAAOw==
}
set grid_icon_gif {
R0lGODlhEAAQAIAAAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIjjI+pq+AP
3wGzGnptwFvzP0UimJWdSZ5q+o2RB6PxOrsvwxQAOw==
}
set popup_icon_gif {
R0lGODlhEAAQAIAAAAAAAP///yH5BAEAAAEALAAAAAAQABAAAAIljA2px9gB
HnSzslgxvtKeqCwb14xlaD5phyTs96puvLILHZ9pAQA7
}

foreach i {quit lupe_plus lupe_minus arrow box circle fline line oval pixel pline poly rect select text colSpoit print replot grid popup} {
    eval image create photo ${i}_icon -format gif -data $${i}_icon_gif
    unset ${i}_icon_gif
}

############################################################
# Canvas snapshot
proc popupCanvasSnapshot {w} {
    global gp_snapshot_id snapshot_edit
    global gp_snapshot_editignore_id
    global snapshot_cur_edit_id snapshot_cur_edit_coord

    set t .csn$gp_snapshot_id
    toplevel $t
    set c $t.c
    set width [$w cget -width]
    set height [$w cget -height]
    canvas $c -width $width -height $height -background white
    frame $t.f
    button $t.f.ok -text "OK" -command "destroy $t"
    label $t.f.l -text "memo:"
    entry $t.f.e
    pack $t.f.l -side left
    pack $t.f.e -side left -fill x -expand yes
    pack $t.f.ok -side left
    pack $t.f -side bottom -fill x
    pack $c
    $t.f.e insert 0 [$t.f.e get]
    wm title $t "tkgnuplot: Snapshot $gp_snapshot_id"
    set gp_snapshot_editignore_id($c) ""
    foreach id [$w find all] {
	set opts ""
	foreach opt [$w itemconfigure $id] {
	    append opts "[lindex $opt 0] [list [lindex $opt end]] "
	}
	set type [$w type $id]
	set id [eval $c create $type [$w coords $id] $opts]
	if {$type!="text"} {
	    lappend gp_snapshot_editignore_id($c) $id
	}
    }
    bind $t <Control-q> "destroy $t"
    bind $t <Control-w> "destroy $t"
    bind $t <Key-less> "updateSnapshot $t.c \[expr \[$t.c cget -width\]/2.0\] \[expr \[$t.c cget -height\]/2.0\]"
    bind $t <Key-greater> "updateSnapshot $t.c \[expr \[$t.c cget -width\]*2\] \[expr \[$t.c cget -height\]*2\]"
    bind $t.c <Button-1> "snapshotButton-1 $t.c %x %y"
    bind $t.c <Button1-Motion> "snapshotButton1-Motion $t.c %x %y"
    bind $t.c <ButtonRelease-1> "snapshotButtonRelease-1 $t.c %x %y"
    bind $t.c <ButtonRelease-2> "snapshotButtonRelease-2 $t.c %x %y"
    bind $t.c <Motion> "snapshotMotion $t.c %x %y"
    bind $t.c <Button-3> "snapshotButton-3 $t.c %x %y %X %Y"
    bind $t.c <Shift-Button-3> "makeColorMenu $t.c %x %y %X %Y"
    bind $t.c <Key-Delete> "snapshotDeleteItem $t.c \$snapshot_cur_edit_id"
    bind $t.c <Control-x> "snapshotDeleteItem $t.c \$snapshot_cur_edit_id"
    bind $t.c <Control-f> "$t.c raise \$snapshot_cur_edit_id"
    bind $t.c <Control-b> "$t.c lower \$snapshot_cur_edit_id"
    bind $t.c <Control-d> "snapshotCopyItem $t.c \$snapshot_cur_edit_id"
    bind $t.c <Alt-parenright> "snapshotScaleSizeItem $t.c"
    bind $t.c <Enter> "focus $t.c"
    bind $t <Alt-p> [subst [list snapshotFileDialog canvasPrint $t.c {PS {.ps .eps .epsi}} "Postscript Out" "Save"]]
    bind $t <Control-Alt-s> [subst [list snapshotFileDialog snapshotCanvasImage $t.c {GIF ".gif"} "Save in GIF format" "Save"]]
    bind $t <Alt-t> {if {$snapshot_edit==1} {set snapshot_edit 0} else {set snapshot_edit 1}}

    incr gp_snapshot_id
    if {0} {
	after 100 bind $t.c <Configure> [list [list eval updateSnapshot $t.c {[expr %w-2]} {[expr %h-2]}]]
    }
}

proc snapshotCanvasImage {{w} {fname} {shrink 1} {margin 0}} {
    set bbox [$w bbox all]
    if {$bbox==""} {return}

    foreach {x0 y0 x1 y1} $bbox {}
    set width [expr ($x1-$x0)]
    set height [expr ($y1-$y0)]
    set width [expr $width/$shrink+$margin*2]
    set height [expr $height/$shrink+$margin*2]

    set t .scimg
    toplevel $t
    set c $t.c
    canvas $c -width $width -height $height -background [$w cget -background]
    wm overrideredirect $t 1
    pack $c 
    bind $t <Control-q> "destroy $t"
    bind $t <Control-w> "destroy $t"
    update
    set id_create ""
    foreach id [$w find all] {
	set opts ""
	foreach opt [$w itemconfigure $id] {
	    set o_name [lindex $opt 0]
	    set o_value [list [lindex $opt end]]
	    if {$o_name=="-arrowshape"} {
		set tmp ""
		foreach v [lindex $o_value 0] {
		    lappend tmp [expr 1.0*$v/$shrink]
		}
		set o_value [list $tmp]
	    } elseif {$o_name=="-width"} {
		set o_value [expr $o_value/$shrink]
	    }
	    append opts "$o_name $o_value "
	}
	lappend id_create "$c create [$w type $id] [$w coords $id] $opts"
    }
    foreach idc $id_create {eval $idc}
    $c move all [expr -$x0+$margin] [expr -$y0+$margin]
    $c scale all $margin $margin [expr 1.0/$shrink] [expr 1.0/$shrink]
    update
    exec xwd -id [winfo id $c] -nobdrs -silent | convert xwd:- gif:- > $fname
    after 500 destroy $t
}

proc snapshotDeleteItem {{w} {id}} {
    if {$id==""} {return}
    $w delete $id
}

proc snapshotCopyItem {{w} {id}} {
    if {$id==""} {return}
    set coord [$w coord $id]
    set opts ""
    foreach opt [$w itemconfigure $id] {
	set o_name [lindex $opt 0]
	set o_value [list [lindex $opt end]]
	append opts "$o_name $o_value "
    }
    set id [lindex $id 0]
    set id_tmp [eval $w create [$w type $id] [$w coords $id] $opts]
    $w move $id_tmp 10 10
}

proc snapshotScaleSizeItem {{w} {ratio ""}} {
    global snapshot_cur_scaleratio
    if {$ratio=={}} {
	set ratio [getValue "Scale Ratio \[X:Y\] or Scale" $snapshot_cur_scaleratio]
	if {$ratio=={}} {return}
	set snapshot_cur_scaleratio $ratio
    }
    sets {ratio_x ratio_y} [split $ratio ":"]
    if {$ratio_y==""} {set ratio_y $ratio_x}
    sets {x0 y0 x1 y1} [$w bbox all]
    $w scale all [expr ($x1+$x0)/2] [expr ($y1+$y0)/2] $ratio_x $ratio_y
}

proc updateSnapshot {{c} {width} {height}} {
    set w [$c cget -width]
    set h [$c cget -height]
    set r_x [expr 1.0*$width/$w]
    set r_y [expr 1.0*$height/$h]
    $c scale all 0 0 $r_x $r_y
    $c configure -width $width
    $c configure -height $height
}

proc snapshotEditText {{w} {x} {y} {id}} {
    set e [winfo parent $w].e
    entry $e
    pack slave $e
    $e delete 0 end
    $e insert 0 [$w itemcget $id -text]
    set e_id [$w create window $x $y -window $e]
    bind $e <Key-Return> "$w itemconfigure $id -text \[$e get\]; destroy $e"
    bind $e <Escape> "destroy $e; set text \[$w itemcget $id -text\]; if {\$text==\"\"} {$w delete $id}"
    update
    focus $e
    grab $e
}

proc snapshotButton-1 {{w} {x} {y}} {
    global snapshot_grab snapshot_edit
    global snapshot_cur_mode snapshot_cur_edit_id snapshot_cur_edit_coord

    if {$snapshot_edit==0} {return}
    set mode $snapshot_cur_mode
    set cur_id $snapshot_cur_edit_id

    set ft 3
    if {$mode=="select"} {
	set id [lindex [$w find overlapping [expr $x-$ft] [expr $y-$ft] [expr $x+$ft] [expr $y+$ft]] 0]
	set snapshot_grab(x) $x
	set snapshot_grab(y) $y
	set snapshot_grab(id) [lindex $id 0]
	set snapshot_cur_edit_id $id
    } elseif {$mode=="text"} {
	snapshotEditText $w $x $y [$w create text $x $y -anchor w]
    } elseif {$mode=="arrow"} {
	set snapshot_cur_edit_id [$w create line $x $y $x $y -arrow last]
    } elseif {$mode=="line"} {
	set snapshot_cur_edit_id [$w create line $x $y $x $y]
    } elseif {$mode=="fline"} {
	set snapshot_cur_edit_id [$w create line $x $y $x $y -smooth 1]
    } elseif {$mode=="pline"} {
	set id $snapshot_grab(id)
	if {$id!="" && [$w type $id]=="line" && $snapshot_cur_edit_coord!=""} {
	    append snapshot_cur_edit_coord "$x $y "
            eval $w coord $id $snapshot_cur_edit_coord
	} else {
            set snapshot_grab(id) [$w create line $x $y $x $y]
	    set snapshot_cur_edit_coord "$x $y "
	}
    } elseif {$mode=="circle"} {
	set snapshot_cur_edit_id [$w create oval $x $y $x $y]
    } elseif {$mode=="rect"} {
	set snapshot_cur_edit_id [$w create rectangle $x $y $x $y]
    } else {
	set snapshot_cur_edit_id ""
    }
}

proc snapshotButton1-Motion {{w} {x} {y}} {
    global snapshot_grab snapshot_edit
    global snapshot_cur_mode snapshot_cur_edit_id snapshot_cur_edit_coord
    global gp_snapshot_editignore_id

    if {$snapshot_edit==0} {return}
    set mode $snapshot_cur_mode
    set cur_id $snapshot_cur_edit_id

    if {($mode=="select" || $mode=="move") && [lsearch $gp_snapshot_editignore_id($w) $cur_id]==-1} {
	set snapshot_cur_mode "move"
	set xx [expr $x-$snapshot_grab(x)]
	set yy [expr $y-$snapshot_grab(y)]
	$w move $snapshot_grab(id) $xx $yy
	set snapshot_grab(x) $x
	set snapshot_grab(y) $y
    } elseif {$mode=="arrow" || $mode=="line" || $mode=="rect" || $mode=="box" || $mode=="circle"} {
	set id [lindex $cur_id 0]
	eval $w coord $id [lrange [$w coord $id] 0 1] $x $y
    } elseif {$mode=="fline"} {
	set id [lindex $cur_id 0]
	eval $w coord $id [$w coord $id] $x $y
    } elseif {$mode=="pline"} {
    } elseif {$mode=="oval"} {
    }
	
}

proc snapshotButtonRelease-1 {{w} {x} {y}} {
    global snapshot_grab snapshot_edit
    global snapshot_cur_mode snapshot_cur_edit_id

    if {$snapshot_edit==0} {return}
    set mode $snapshot_cur_mode
    set cur_id $snapshot_cur_edit_id
    
    if {$mode=="select"} {
    } elseif {$mode=="move"} {
	set snapshot_cur_mode "select"
	set snapshot_grab(id) ""
    }
}

proc snapshotButtonRelease-2 {{w} {x} {y}} {
    global snapshot_grab snapshot_edit
    global snapshot_cur_mode snapshot_cur_edit_id

    if {$snapshot_edit==0} {return}
    set mode $snapshot_cur_mode
    set cur_id $snapshot_cur_edit_id
    
    if {$mode=="select"} {
	set id [lindex [$w find overlapping [expr $x-2] [expr $y-2] [expr $x+2] [expr $y+2]] 0]
	if {[$w type $id]=="text"} {snapshotEditText $w $x $y $id}
    }
}

proc snapshotButton-3 {{w} {x} {y} {bx} {by}} {
    global snapshot_cur_mode snapshot_grab snapshot_cur_edit_id snapshot_cur_edit_coord
    
    if {$snapshot_cur_mode=="pline"}  {
	if {[llength $snapshot_cur_edit_coord]<4} {
	    snapshotMakeFloatMenuBase $w $bx $by
	} else {
	    eval $w coord $snapshot_grab(id) $snapshot_cur_edit_coord
	    set snapshot_grab(id) ""
	    set snapshot_cur_edit_id ""
	    set snapshot_cur_edit_coord ""
	}
    } else {
	snapshotMakeFloatMenuBase $w $bx $by
    }
}

proc snapshotMotion {{w} {x} {y}} {
    global snapshot_grab snapshot_edit
    global snapshot_cur_mode snapshot_cur_edit_id snapshot_cur_edit_coord

    if {$snapshot_edit==0} {return}
    set mode $snapshot_cur_mode
    set cur_id $snapshot_cur_edit_id
    
    if {$mode=="pline"} {
	set id $snapshot_grab(id)
	set coord $snapshot_cur_edit_coord
	if {[llength $coord]>=2} {
	    eval $w coord $id $coord $x $y
	}
    }
}

proc canvasPrint {{c} {fname}} {
    set bbox [$c bbox all]
    set x [lindex $bbox 0]
    set y [lindex $bbox 1]
    set w [expr [lindex $bbox 2]-$x]
    set h [expr [lindex $bbox 3]-$y]
    $c postscript \
	    -file $fname -width $w -height $h -x $x -y $y \
	    -colormode color 
}

proc snapshotFileDialog {{proc} {w} {ext_default} {mess} {type Open}} {
    global gp_plotform
    
    set tmp [tk_get${type}File \
	    -title "tkgnuplot: $mess" \
	    -filetypes "[list $ext_default] {ALL {*}}"]
    if {$tmp != ""} {$proc $w $tmp}
}

proc makeColorMenu {{w} {x} {y} {bx} {by}} {
    set id [lindex [$w find overlapping [expr $x-1] [expr $y-1] [expr $x+1] [expr $y+1]] 0]
    if {$id==""} {return}
    set m .colmenu
    destroy $m
    menu $m -borderwidth 0 -activeborderwidth 1
    set clmn 5
    set i 1
    foreach c {
	000000 1f1f1f 3f3f3f 5f5f5f 7f7f7f
	ffffff efefef dfdfdf bfbfbf 9f9f9f
	ffdfdf ffbfbf ff0000 bf0000 7f0000
	ffdfbf ffbf7f ff7f00 bf3f00 7f1f00
	ffffbf ffff7f ffff00 bfbf00 7f7f00
	dfffbf bfff7f 7fff00 3fbf00 1f7f00
	bfffbf 7fff7f 00ff00 00bf00 007f00
	bfffdf 7fffbf 00ff7f 00bf3f 007f1f
	bfffff 7fffff 00ffff 00bfbf 007f7f
	bfdfff 7fbfff 007fff 003fbf 001f7f
	bfbfff 7f7fff 0000ff 0000bf 00007f
	dfbfff bf7fff 7f00ff 3f00bf 1f007f
	ffbfff ff7fff ff00ff bf00bf 7f007f
	ffbfdf ff7fbf ff007f bf003f 7f001f
    } {
	set col col$i
	set size 16
	image create photo $col -width $size -height $size
	$col put #$c -to 0 0 $size $size
	$m add checkbutton -image $col -hidemargin 1 \
		-command "$w itemconfigure $id -fill #$c" \
		-columnbreak [expr (fmod($i-1, $clmn)==0)]
	incr i
    }
    tk_popup $m $bx $by
}

proc toggleGrid {} {
    global chkgri

    if {"$chkgri"=="nogrid"} {
	set chkgri grid
    } else {
	set chkgri nogrid
    }
    updateCanvas [subst {{set $chkgri; rep}}]
}
	
############################################################
# makeFloatMenuBase    
proc makeFloatMenuBase {{w} {x} {y}} {
    global gp_canvas

    destroy .helptmp;
    set m [menu .helptmp -tearoff 0 -cursor hand2];
    set clmn 3
    set n 1

    foreach f [list \
	    [list lupe_plus [subst {setWindowSize $w [expr [$w cget -width]*2] [expr [$w cget -height]*2]}]]\
	    [list lupe_minus [subst {setWindowSize $w [expr [$w cget -width]/2] [expr [$w cget -height]/2]}]]\
	    [list popup [list popupCanvasSnapshot $gp_canvas]]\
	    [list grid toggleGrid]\
	    [list print [list snapshotFileDialog canvasPrint $w {PostScript {.ps .eps .epsi}} "Postscript Out" "Save"]]\
	    [list replot {updateCanvas {rep}}]\
	    [list quit exit]\
	    ] {
    
	set i [lindex $f 0]
	set com  [lindex $f 1]
	$m add command -image ${i}_icon \
		-command $com \
		-hidemargin 1 \
		-columnbreak [expr (fmod($n-1, $clmn)==0)]
	incr n
    }
    tk_popup $m $x $y
}

############################################################
#
proc snapshotMakeFloatMenuBase {{w} {x} {y}} {
    global snapshot_cur_mode
    foreach i {arrow box circle fline line oval pixel pline poly rect select text colSpoit print lupe_plus lupe_minus} {
	global ${i}_icon
    }
    
    destroy .helptmp;
    set m [menu .helptmp -tearoff 0 -cursor hand2];
    set clmn 3
    set n 1

    # ignore: pixel box colSpoit oval poly
    foreach i {
	select
	text
	arrow
	line
	rect
	circle
	fline
	pline
    } {
	$m add radiobutton -variable snapshot_cur_mode \
		-indicatoron false \
		-value $i \
		-image ${i}_icon \
		-hidemargin 1 \
		-columnbreak [expr (fmod($n-1, $clmn)==0)]
	incr n
    }
    foreach f [list \
	    [list print [list snapshotFileDialog canvasPrint $w {PostScript {.ps .eps .epsi}} "Postscript Out" "Save"]]\
	    [list lupe_plus "updateSnapshot $w \[expr \[$w cget -width\]*2\] \[expr \[$w cget -height\]*2\]"]\
	    [list lupe_minus "updateSnapshot $w \[expr \[$w cget -width\]/2.0\] \[expr \[$w cget -height\]/2.0\]"]\
	    ] {
    
	set i [lindex $f 0]
	set com  [lindex $f 1]
	$m add command -image ${i}_icon \
		-command $com \
		-hidemargin 1 \
		-columnbreak [expr (fmod($n-1, $clmn)==0)]
	incr n
    }
    tk_popup $m $x $y
}

############################################################
# view point selector
proc makeViewPointSelector {} {
    global gp_plotform gp_term
    global gp_spawnid gp_subspawnid
    global zroll xroll
    global lastDrag
    global width height
    global vps_zroll vps_xroll

    set vps_zroll $zroll
    set vps_xroll $xroll
    
    toplevel .vps
    wm title .vps "tkgnuplot: View Point Selector"
    frame .vps.idc
    canvas .vps.idc.c -width 100 -height 100 -background white
    scale .vps.idc.scl_z -variable vps_zroll -from 360 -to 0 -orient horizontal -showvalue false
    scale .vps.idc.scl_x -variable vps_xroll -from 180 -to 0 -showvalue false
    frame .vps.valz
    frame .vps.valx
    entry .vps.valz.z -width 5
    entry .vps.valx.x -width 5
    label .vps.valz.lab_z -text Z
    label .vps.valx.lab_x -text X
    button .vps.ok     -text OK -command {set zroll $vps_zroll; set xroll $vps_xroll; updateCanvas [list "set view $xroll,$zroll" rep]}
    button .vps.close -text Close -command {destroy .vps}
if {0} {
    pack .vps.idc -side left
    pack .vps.idc.scl_z -side bottom -fill x
    pack .vps.idc.c .vps.idc.scl_x -side left -fill both
    pack .vps.valz.lab_z .vps.valz.z -side left
    pack .vps.valx.lab_x .vps.valx.x -side left
    pack .vps.ok .vps.close .vps.valx .vps.valz -fill x
} else {
    grid .vps.valz.lab_z .vps.valz.z
    grid .vps.valx.lab_x .vps.valx.x
    grid .vps.idc.c .vps.idc.scl_x -sticky news -sticky news
    grid .vps.idc.scl_z -sticky news
    grid .vps.idc -column 1 -row 0 -rowspan 5 -sticky news
    grid .vps.valx -column 0 -row 0 -sticky new
    grid .vps.valz -column 0 -row 1 -sticky new
    grid .vps.ok -column 0 -row 2 -sticky new
    grid .vps.close -column 0 -row 3 -sticky new
    grid rowconfigure .vps 4 -weight 1
    grid columnconfigure .vps 1 -weight 1
    grid rowconfigure .vps.idc 0 -weight 1
    grid columnconfigure .vps.idc 0 -weight 1
}

    bind .vps <q> {exit}
    bind .vps.valz.z <Key-Return> {set vps_zroll [.vps.valz.z get]; set zroll $vps_zroll; updateCanvas [list "set view $xroll,$zroll" rep]}
    bind .vps.valx.x <Key-Return> {set vps_xroll [.vps.valx.x get]; set xroll $vps_xroll; updateCanvas [list "set view $xroll,$zroll" rep]}
    bind .vps.idc.c <Button-1> {updateViewPointSelector %x %y 0; updateViewPointSelectorStart}
    bind .vps.idc.c <Button1-Motion> {updateViewPointSelector %x %y 1}
    bind .vps.idc.c <ButtonRelease-1> {updateViewPointSelectorEnd}
    
    bind .vps.idc.scl_z <Button-1> {updateViewPointSelectorStart}
    bind .vps.idc.scl_x <Button-1> {updateViewPointSelectorStart}
    bind .vps.idc.scl_z <ButtonRelease-1> {set zroll $vps_zroll; updateViewPointSelectorEnd}
    bind .vps.idc.scl_x <ButtonRelease-1> {set xroll $vps_xroll; updateViewPointSelectorEnd}
    .vps.valz.z delete 0 end; .vps.valz.z insert 0 $vps_zroll
    .vps.valx.x delete 0 end; .vps.valx.x insert 0 $vps_xroll
    update
    .vps.idc.scl_z configure -command {updateViewPointSelectorZ}
    .vps.idc.scl_x configure -command {updateViewPointSelectorX}
}

proc updateViewPointSelectorZ {val} {
    global xroll zroll
    set zroll $val
    .vps.valz.z delete 0 end; .vps.valz.z insert 0 $val
    updateCanvas [list "set view $xroll,$zroll" rep]
}

proc updateViewPointSelectorX {val} {
    global xroll zroll
    set xroll $val
    .vps.valx.x delete 0 end; .vps.valx.x insert 0 $val
    updateCanvas [list "set view $xroll,$zroll" rep]
}

proc updateViewPointSelector_tmp {} {
    global gp_plotform gp_term
    global gp_spawnid gp_subspawnid
    global zroll xroll
    global lastDrag
    global width height
    global vps_zroll vps_xroll
}

############################################################
# change view
proc updateViewPointSelector {x y set} {
    global gp_plotform
    global lastDrag
    global zroll xroll
    global vps_zroll vps_xroll

    if {$gp_plotform!="splot"} {return}
    if {$set!=0} {
	set vps_zroll [expr ($vps_zroll+($lastDrag(x)-$x))%360]
	set vps_xroll [expr ($vps_xroll+($lastDrag(y)-$y))]
	if {$vps_xroll<0} {
	    set vps_xroll 0
	} elseif {$vps_xroll>180} {
	    set vps_xroll 180
	}
    }
    .vps.valz.z delete 0 end; .vps.valz.z insert 0 $vps_zroll
    .vps.valx.x delete 0 end; .vps.valx.x insert 0 $vps_xroll
    set zroll $vps_zroll
    set xroll $vps_xroll
    set lastDrag(x) $x
    set lastDrag(y) $y
    
    if {$set!=0} {updateCanvas [list "set view $xroll,$zroll" rep]}
}

proc updateViewPointSelectorStart {} {
    global gp_curgraph
    global gp_plotform gp_term
    global gp_viewrolling
    global gp_spawnid gp_subspawnid
    global spawn_id

    if {$gp_viewrolling} {return}
    set gp_viewrolling 1
    if {$gp_plotform!="splot"} {return}
    if {1 || $gp_term!="x11"} {set spawn_id $gp_subspawnid}
    foreach str [list \
	{set noztic; set noxtic; set noytic} \
	{set xrange [0:10]; set yrange [0:10]; set zrange [0:10]} \
	{set label "X" at -1.5,7,0; set label "Y" at 7,-1.5,0; set label "Z" at -.7,-.7,10} \
	{set isosamples 2} \
	{set border 4095} \
	{set nohidden3d} \
	{set nokey} ] {
        exp_send "$str;"
    }
    updateCanvas {"splot x-30"}
}

proc updateViewPointSelectorEnd {} {
    global gp_curgraph
    global gp_plotform gp_term
    global zroll xroll
    global gp_viewrolling
    global gp_spawnid gp_subspawnid
    global spawn_id

    if {!$gp_viewrolling} {return}

    if {$gp_plotform!="splot"} {return}
    set gp_viewrolling 0
    if {1 || $gp_term!="x11"} {set spawn_id $gp_spawnid}
    updateCanvas [list "set view $xroll,$zroll" rep]
}

############################################################
# change view scale
proc changeViewScale {{s_scale} {s_scalez} {update 0}} {
    global gp_plotform
    global splot_scale splot_scale_z

    if {$gp_plotform!="splot"} {return}
    set splot_scale [expr $splot_scale+$s_scale]
    set splot_scale_z [expr $splot_scale_z+$s_scalez]
    if {$splot_scale<=0} {set splot_scale .1}
    if {$splot_scale_z<=0} {set splot_scale_z .1}
    if {$update} {
	updateCanvas [list "set view ,,$splot_scale,$splot_scale_z" rep]
    }
}

proc updateViewScale {x y set {only_z 0}} {
    global width height
    global gp_plotform
    global lastDrag
    global splot_scale splot_scale_z

    if {$gp_plotform!="splot"} {return}
    if {$set!=0} {
	set sx [expr 5.0*($lastDrag(x)-$x)/$width]
	set sy [expr 5.0*($lastDrag(y)-$y)/$width]
	set scale $sx
	if {[expr abs($sx)]<[expr abs($sy)]} {set scale $sy}
    }
    set lastDrag(x) $x
    set lastDrag(y) $y
    if {$set!=0} {
	set coms ""
	if {$only_z} {
	    set scale [expr $splot_scale_z-$scale]
	    if {$scale>0} {
		set splot_scale_z $scale
		set coms ",,$splot_scale_z"
	    }
	} else {
	    set scale [expr $splot_scale-$scale]
	    if {$scale>0} {
		set splot_scale $scale
		set coms ",$splot_scale"
	    }
	}
	if {$coms!=""} {updateCanvas [list "set view ,$coms" rep]}
    }
}

proc updateViewScaleStart {} {
    global gp_curgraph
    global gp_plotform gp_term
    global gp_viewscaling
    global gp_viewbox_update
    global gp_spawnid gp_subspawnid
    global spawn_id

    if {$gp_viewscaling} {return}
    set gp_viewscaling 1
    if {$gp_plotform!="splot"} {return}
    if {$gp_viewbox_update} {
    if {1 || $gp_term!="x11"} {set spawn_id $gp_subspawnid}
    foreach str [list \
	{set noztic; set noxtic; set noytic} \
	{set xrange [0:10]; set yrange [0:10]; set zrange [0:10]} \
	{set label "X" at -1.5,7,0; set label "Y" at 7,-1.5,0; set label "Z" at -.7,-.7,10} \
	{set isosamples 2} \
	{set border 4095} \
	{set nohidden3d} \
	{set nokey} ] {
        exp_send "$str;"
    }
    updateCanvas {"splot x-30"}
    }
}

proc updateViewScaleEnd {} {
    global gp_curgraph
    global gp_plotform
    global splot_scale splot_scale_z
    global gp_viewscaling
    global gp_spawnid gp_subspawnid
    global spawn_id

    if {!$gp_viewscaling} {return}

    if {$gp_plotform!="splot"} {return}
    set gp_viewscaling 0
    set spawn_id $gp_spawnid
    updateCanvas [list "set view ,,$splot_scale,$splot_scale_z" rep]
}

############################################################
# change view
proc changeView {{sx} {sz} {update 0}} {
    global gp_plotform
    global xroll zroll
    
    if {$gp_plotform!="splot"} {return}
    incr xroll $sx
    incr zroll $sz
    if {$xroll<0} {
	set xroll 0
    } elseif {$xroll>180} {
	set xroll 180
    }
    if {$zroll<0} {
	set zroll 360
    } elseif {$zroll>360} {
	set zroll 0
    }
    if {$update} {
	updateCanvas [list "set view $xroll,$zroll" rep]
    }
}

proc updateView {x y set} {
    global gp_plotform
    global lastDrag
    global zroll xroll

    if {$gp_plotform!="splot"} {return}
    if {$set!=0} {
	set zroll [expr ($zroll+($lastDrag(x)-$x))%360]
	set xroll [expr ($xroll+($lastDrag(y)-$y))]
	if {$xroll<0} {
	    set xroll 0
	} elseif {$xroll>180} {
	    set xroll 180
	}
    }
    set lastDrag(x) $x
    set lastDrag(y) $y
    if {$set!=0} {updateCanvas [list "set view $xroll,$zroll" rep]}
}

proc updateViewStart {} {
    global gp_curgraph
    global gp_plotform gp_term
    global gp_viewrolling
    global gp_spawnid gp_subspawnid
    global gp_viewbox_update
    global spawn_id

    if {$gp_viewrolling} {return}
    set gp_viewrolling 1
    if {$gp_plotform!="splot"} {return}
    if {$gp_viewbox_update} {
    if {1 || $gp_term!="x11"} {set spawn_id $gp_subspawnid}
    foreach str [list \
	{set noztic; set noxtic; set noytic} \
	{set xrange [0:10]; set yrange [0:10]; set zrange [0:10]} \
	{set label "X" at -1.5,7,0; set label "Y" at 7,-1.5,0; set label "Z" at -.7,-.7,10} \
	{set isosamples 2} \
	{set border 4095} \
	{set nohidden3d} \
	{set nokey} ] {
        exp_send "$str;"
    }
    updateCanvas {"splot x-30"}
    }
}

proc updateViewEnd {} {
    global gp_curgraph
    global gp_plotform gp_term
    global zroll xroll
    global gp_viewrolling gp_viewbox_update
    global gp_spawnid gp_subspawnid
    global spawn_id

    if {!$gp_viewrolling} {return}

    if {$gp_plotform!="splot"} {return}
    set gp_viewrolling 0
    if {$gp_viewbox_update && $gp_term=="x11"} {exp_send "set term x11 reset\r"; expect "gnuplot>"}
    if {1 || $gp_term!="x11"} {set spawn_id $gp_spawnid}
    updateCanvas [list "set view $xroll,$zroll" rep]
}

############################################################
proc addHistory {com} {
    global gp_comhist gp_comhist_n

    if {[indexHistory end]==$com} {return}
    lappend gp_comhist $com
    set gp_comhist_n [expr [llength $gp_comhist]-1]
}

proc indexHistory {n} {
    global gp_comhist

    return [lindex $gp_comhist $n]
}

proc backHistory {} {
    global gp_comhist_n

    if {$gp_comhist_n<=0} {return [indexHistory 0]}
    incr gp_comhist_n -1
    return [indexHistory $gp_comhist_n]
}

proc forwardHistory {} {
    global gp_comhist gp_comhist_n

    if {$gp_comhist_n>=[expr [llength $gp_comhist]-1]} {return ""}
    incr gp_comhist_n
    return [indexHistory $gp_comhist_n]
}

############################################################
proc sendCommand {com} {
    global gp_term gp_platform gp_curgraph
    global gp_canvas

    exp_send "set term $gp_term\r"
    expect "gnuplot>"
    exp_send "$com\r"
    expect {
	"$com" {}                  # ignore $com echo
	"gnuplot>" {exp_send "\r"}
	"^Warning:" {}
    }
}

proc gp_dialog {{w} {title} {text} {bitmap} {default} {button}} {
    destroy $w
    toplevel $w
    wm title $w $title
    text $w.t -width 40 -height 8 -yscrollcommand "$w.s set"
    button $w.b -text $button -command "grab release $w; destroy $w; focus -force ."
    scrollbar $w.s -orient vertical -command "$w.t yview"
    pack $w.b -side bottom
    pack $w.s -side right -fill y
    pack $w.t -side left -expand yes -fill both
    $w.t insert 0.0 $text
    $w.t configure -relief flat -state disabled
    bind $w <Key-Return> "destroy $w; focus -force ."
    bind $w <Key-q> "destroy $w; focus -force ."
    focus $w
    grab $w
}

proc updateCanvas {coms args} {
    global gp_term gp_com gp_plotform gp_curgraph
    global gp_canvas
    global updating
    global gp_viewrolling gp_viewscaling
    global gp_use_tmpfile
    global zroll xroll

    set c $gp_canvas
    if {$updating==1} {return}
    set updating 1
    set t_cursor [lindex [. configure -cursor] 3]
    set t_c_cursor [lindex [$gp_canvas configure -cursor] 3]
    set t_e_cursor [lindex [.com.e configure -cursor] 3]
    if {!$gp_viewrolling && !$gp_viewscaling} {
	. configure -cursor watch
	$gp_canvas configure -cursor watch
	.com.e configure -cursor watch
    }
    foreach com $coms {
	set gp_com $com
	if {[regexp "^help( .+)?" $gp_com null topic]} {
	    after 0 displayHelp [list [list $topic] 0]
	    break
	} elseif {$gp_com!="rep"} {
	    .com.e delete 0 end
	    .com.e insert 0 $gp_com
	}
	set gp_out ""
	foreach com [split $gp_com ";"] {
	    regsub "^ *" $com "" com
	    if {$gp_use_tmpfile && [regexp "^rep(lot)?|^s?plot" $com"]} {
		set tmp_fname "/tmp/tkgnuplot[pid]"
                exp_send "set output '$tmp_fname'\r"
		expect "gnuplot>"
	    }
	    sendCommand $com
	    if {[regexp "^rep(lot)?|^s?plot" $com"]} {
		regexp "^(s?plot) (.+)" $com null gp_plotform gp_curgraph
		expect {
		    "gnuplot>" {append gp_out "$expect_out(buffer)"}
		    full_buffer {
			append gp_out "$expect_out(buffer)"; exp_continue
		    }
		}
		regsub "^parametric function not fully specified" \
			$gp_out "" gp_out
		if {[regexp "^\[ \n\r\t\]*\\\$can" $gp_out]} {
		    set gp_out "proc gnuplot can \{\n \
			    \$can delete all\n \
			    set cmx \[lindex \[\$can configure -width] 4]\n \
			    set cmy \[lindex \[\$can configure -height] 4]\n \
			    $gp_out"
	        }
		regsub "\ngnuplot>\$" $gp_out "" gp_out
		set tmp $gp_out
		if {$gp_use_tmpfile} {
		    exec cat $tmp_fname
		    source $tmp_fname
		    file delete -force $tmp_fname
		    exp_send "set output\r"
		    expect "gnuplot>"
	        } elseif {[regexp "^\[ \n\r\t\]*proc" $gp_out]} {
		    catch [eval $gp_out] tmp
		}
		if {$tmp!=""} {
		    gp_dialog .tkgd "Tkgnuplot Message: $gp_com" \
			    "$gp_com:$tmp" {} 0 OK
		}
		gnuplot $gp_canvas
	    } elseif {[regexp "^load" $com]} {
		expect {
		    "gnuplot>" {append gp_out "$expect_out(buffer)"}
		    full_buffer {
			append gp_out "$expect_out(buffer)"; exp_continue
		    }
		}
	    } else {
		expect "gnuplot>"
		regsub -all "\[\r\n ]" "$expect_out(buffer)" "" tmp
		if {[regexp "^gnuplot>" $tmp]!=1} {
		    gp_dialog .tkgd "Tkgnuplot Message: $gp_com" "$gp_com:$expect_out(buffer)" {} 0 OK
		}
	    }
	}
    }
    if {!$gp_viewrolling && !$gp_viewscaling} {
	. config -cursor $t_cursor
	$gp_canvas config -cursor $t_c_cursor
	.com.e config -cursor $t_e_cursor
    }
    if {"$gp_plotform"=="splot"} {
	if {$gp_viewscaling} {
	    $gp_canvas configure -cursor sizing
	} else {
	    $gp_canvas configure -cursor fleur
	}
    } else {
	$gp_canvas configure -cursor left_ptr
    }
    set updating 0
    update
}

############################################################
# Help
proc setupHelpWindow {t} {
    global gp_helpwindow gp_helptopic gp_helphist

    toplevel $t

    wm title $t "Tkgnuplot Help"
    text $t.text -width 70 -height 40 -background white \
	-state disabled -yscrollcommand "$t.scroll set" \
	-font {Helvetica 14}
    scrollbar $t.scroll -orient vertical -command "$t.text yview"
    entry $t.entry
    button $t.ok -text "OK"
    button $t.back -text "Back"
    button $t.clear -text "Clear"
    button $t.close -text "Close"
    
    pack $t.scroll -side right -expand no -fill y
    pack $t.text -fill both -expand true -side bottom
    pack $t.entry -fill x -side left
    pack $t.ok $t.back $t.clear $t.close \
	    -side left -anchor nw
    update
    bind $t <Control-q> "destroyHelpWindow $t"
    bind $t <Control-w> "destroyHelpWindow $t"
    bind $t.entry <Key-Return> "set gp_helptopic \[list \[$t.entry get\] 0\]"
    bind $t.entry <Enter> {focus -force %W}
    bind $t <Button-3> {set hashist active; if {[llength $gp_helphist]<=1} {set hashist disabled}; catch {destroy .helptmp}; set m [menu .helptmp -tearoff 0]; $m add command -label "Back" -command {set gp_helphist [lreplace $gp_helphist end end]; set gp_helptopic [lindex $gp_helphist end]; destroy .helptmp} -state $hashist; $m add command -label "Close" -command {destroyHelpWindow [winfo parent %W]; focus -force .}; tk_popup $m %X %Y}
    bind $t.text <Enter> {focus -force %W}
    bind $t.text <Key-space> "$t.text yview scroll 1 pages"
    bind $t.text <n> "$t.text yview scroll 1 pages"
    bind $t.text <b> "$t.text yview scroll -1 pages"
    bind $t.text <Key-Down> "$t.text yview scroll 1 units; break"
    bind $t.text <Key-Up> "$t.text yview scroll -1 units; break"
    bind $t.text <Shift-Key-Down> "$t.text yview scroll 1 pages; break"
    bind $t.text <Shift-Key-Up> "$t.text yview scroll -1 pages; break"
    
    # bind for wheel mouse
    bind $t <Button-4> [list $t.text yview scroll -5 units]
    bind $t <Button-5> [list $t.text yview scroll 5 units]
    bind $t <Shift-Button-4> [list $t.text yview scroll -1 units]
    bind $t <Shift-Button-5> [list $t.text yview scroll 1 units]
    bind $t <Control-Button-4> [list $t.text yview scroll -1 page]
    bind $t <Control-Button-5> [list $t.text yview scroll 1 page]

    $t.ok   configure -command "set gp_helptopic \[list \[$t.entry get\] 0\]"
    $t.back configure -command "set gp_helphist \[lreplace \$gp_helphist end end\]; set gp_helptopic \[lindex \$gp_helphist end\]"
    $t.clear configure -command "$t.entry delete 0 end"
    $t.close configure -command "destroyHelpWindow $t; focus -force ."
    focus $t.entry

    #.m.about.menu entryconfigure 3 -state disabled

    set gp_helpwindow 1

    if {[llength $gp_helphist]>0} {
	set gp_helptopic [lindex $gp_helphist end]
    }
}

proc destroyHelpWindow {t} {
    global gp_helpwindow
    
    destroy $t
    set gp_helpwindow 0
    #.m.about.menu entryconfigure 3 -state normal
}

proc displayHelp {topic} {
    global gp_helphist gp_helpwindow
    global gp_helptopic gp_helptopichist
    global gp_helptopic_ignore

    set cur_yview [lindex $topic 1]
    set topic [lindex $topic 0]
    regsub -all "\n" $topic "" topic
    set gp_helptopic [list $topic $cur_yview]
    set t .help
    if {!$gp_helpwindow} {
	setupHelpWindow $t
    } else {
	return
    }
    update
    set gp_helptopic [list $topic $cur_yview]
    set t_cursor [lindex [$t configure -cursor] 3]
    set t_t_cursor [lindex [$t.text configure -cursor] 3]
    set t_e_cursor [lindex [$t.entry configure -cursor] 3]
    while {1} {
	set topic [lindex $gp_helptopic 0]
	set cur_yview [lindex $gp_helptopic 1]
	if {$topic!=""} {
	    wm title $t "tkgnuplot Help: $topic"
	} else {
	    wm title $t "tkgnuplot Help"
	}
	if {[lindex $gp_helptopic 0]!=[lindex [lindex $gp_helphist end] 0]} {
	    set pre_yview [lindex [$t.text yview] 0]
	    if {[llength $gp_helphist]>0} {
		set pre_topic [lindex $gp_helphist end]
		set gp_helphist [lreplace $gp_helphist end end [list [lindex $pre_topic 0] $pre_yview]]
	    }
	    lappend gp_helphist $gp_helptopic
	}
	if {[llength $gp_helphist]<=1} {
	    $t.back configure -state disabled
	} else {
	    $t.back configure -state normal
	}
	$t.entry delete 0 end
	$t.entry insert 0 $topic
	$t configure -cursor watch
	$t.text configure -cursor watch
	$t.entry configure -cursor watch
	exp_send "help $topic\r"
	expect -re "help.*"
	set gp_out ""
	expect {
	    "\ngnuplot>" {
		append gp_out "$expect_out(buffer)"
		regsub "gnuplot>$" $gp_out "" gp_out
	    }
	    "Press return for more:" {
		append gp_out "$expect_out(buffer)"
		regsub "\nPress return for more:" $gp_out "" gp_out
		exp_send "\r"
		exp_continue
	    }
	    "Help topic:" {
		append gp_out "$expect_out(buffer)"
		regsub "\nHelp topic:" $gp_out "" gp_out
		exp_send "\r"
		exp_continue
	    }
	    -re "Subtopic of (.+):" {
		append gp_out "$expect_out(buffer)"
		regsub "\nSubtopic of .+:" $gp_out "" gp_out
		exp_send "\r"
		exp_continue
	    }
	    full_buffer {
		append gp_out "$expect_out(buffer)"
		exp_continue
	    }
	}
	regsub -all "\r" $gp_out "" gp_out
	$t.text configure -state normal
	$t.text delete 0.0 end;
	$t.text insert 0.0 $gp_out;
	$t.text yview moveto $cur_yview
	$t.text configure -state disabled
	set i 0
	set a 0.0
	while {1} {
	    set a [$t.text search "`" $a end]
	    if {$a==""} {break}
	    append a "+1chars"
	    set b [$t.text search "`" $a end]
	    if {$b==""} {break}
	    set tmp [$t.text get $a $b]
	    regsub -all "\n" $tmp " " tmp
	    regsub -all "  " $tmp " " tmp
	    if {[lsearch $gp_helptopic_ignore $tmp]!=-1} {
                set a "$b+1chars"
		continue
	    }
	    set tag "htag$i"
	    $t.text tag add $tag $a $b
	    if {[lsearch [array names gp_helptopichist] $tmp]<0 \
		|| $gp_helptopichist($tmp)<0} {
		set col blue
	        set gp_helptopichist($tmp) -1
	    } else {
		set col navy
	    }
	    $t.text tag configure $tag -underline 1 -foreground $col
	    $t.text tag bind $tag <Enter> \
		    "$t.text configure -cursor hand2"
	    $t.text tag bind $tag <Button-1> \
		    "set tmp \[$t.text get [$t.text tag ranges $tag]\]; regsub \"\n\" \$tmp \"\" tmp; incr gp_helptopichist(\$tmp); set gp_helptopic \[list \$tmp 0\]"
	    $t.text tag bind $tag <Leave> "$t.text configure -cursor left_ptr"
	    set a "$b+1chars"
	    incr i
	}
	set a 0.0
	set a [$t.text search -count cnt -regexp \
		"^(Help |Sub)?\[Tt\]opics? \[Aa\]vailable( for .+)?:" \
		$a end]
	if {$a!=""} {
	    append a "+${cnt}chars"
	    while {1} {
		set a [$t.text search -count cnt -regexp "\[^ \]+" $a end]
		if {$a=="" || $cnt==0} {break}
		set tag "htag$i"
		$t.text tag add $tag $a "$a+${cnt}chars"
		set tmp [$t.text get $a "$a+${cnt}chars"]
		if {[lsearch [array names gp_helptopichist] $tmp]<0 \
			|| $gp_helptopichist($tmp)<0} {
		    set col blue
		    set gp_helptopichist($tmp) -1
		} else {
		    set col navy
		}
		$t.text tag configure $tag -underline 1 -foreground $col
		$t.text tag bind $tag <Enter> "$t.text configure -cursor hand2"
		$t.text tag bind $tag <Button-1> \
			"set tmp \[$t.text get [$t.text tag ranges $tag]\]; incr gp_helptopichist(\$tmp); set gp_helptopic \[list \$tmp 0\]"
		$t.text tag bind $tag <Leave> \
			"$t.text configure -cursor left_ptr"
		append a "+${cnt}chars"
		incr i
	    }
	}
	set a 0.0
	while {1} {
	    set a [$t.text search -count cnt -regexp "(http|ftp):\[^ ]+" $a end]
	    if {$a==""} {break}
	    set tag "htag$i"
	    $t.text tag add $tag "$a" "$a+${cnt}chars"
	    $t.text tag configure $tag -underline 1 -foreground LightSeaGreen
	    $t.text tag bind $tag <Enter> \
		    "$t.text configure -cursor hand2"
	    $t.text tag bind $tag <Button-1> \
		    "sendURL \[$t.text get [$t.text tag ranges $tag]\]"
	    $t.text tag bind $tag <Leave> "$t.text configure -cursor left_ptr"
	    append a "+${cnt}chars"
	    incr i
	}
	$t config -cursor $t_cursor
	$t.text config -cursor $t_cursor
	$t.entry config -cursor $t_e_cursor
	update
	tkwait variable gp_helptopic
    }
}

############################################################
# Window size
proc calcToplevelSize {{w} {width} {height}} {
    set t_width  [winfo width .]
    set t_height [winfo height .]
    set c_width  [winfo width $w]
    set c_height [winfo height $w]
    set pad_x [expr $t_width-$c_width]
    set pad_y [expr $t_height-$c_height]

    return [list [expr $width+$pad_x] [expr $height+$pad_y]]
}

proc setWindowSize {{w} {width} {height}} {
  set geom [calcToplevelSize $w $width $height]
  wm geometry . [lindex $geom 0]x[lindex $geom 1]
  updateCanvas ""
}

############################################################
# proc for command of menu.
proc openPlotFile {} {
    global gp_plotform
    
    set tmp [tk_getOpenFile \
	    -title {tkgnuplot: Open File} \
	    -filetypes {{DAT {.dat}} {ALL {*}}}]
    if {$tmp != ""} {updateCanvas [list "$gp_plotform '$tmp'"]}
}

proc loadScriptFile {} {
    global gp_plotform
    
    set ftmp [tk_getOpenFile \
	    -title {tkgnuplot: Open File} \
	    -filetypes {{GPT {.gpt .gpl .gp}} {DEM {.dem}} {ALL {*}}}]
    if {$ftmp!=""} {
	updateCanvas [list [list load '$ftmp'] rep]
	foreach str [lreverse [list [gp_getCurrentState]]] {
	    if {[regexp "^s?plot" $str gp_plotform]} {break}
	}
    }
}

proc changePlotForm {} {
    global gp_plotform gp_curgraph
    updateCanvas  [list [list $gp_plotform $gp_curgraph]]
}

############################################################
# data file manager for multiple file plotting

proc setupDatafileManager {} {
    global gp_datafilemgr_window
    set t .datafile_manager
    toplevel $t
    label $t.l0 -text "Filename"
    label $t.l1 -text "Column"
    label $t.l2 -text "Title"
    label $t.l3 -text "Style"
    label $t.l4 -text "pt type"
    label $t.l5 -text "pt size"
    label $t.l6 -text "ln type"
    label $t.l7 -text "ln size"
    for {set i 0} {$i <= 7} {incr i} {
        grid $t.l$i -row 0 -column $i
    }
    for {set j 1} {$j <= 6} {incr j} {
       frame $t.f$j
       entry $t.f$j.e
       button $t.f$j.b -text "select" -command "datafileMgrSelect $j"
       entry $t.using$j
       entry $t.title$j
       tk_optionMenu $t.style$j cur_style$j points lines linespoints dots steps impulses errorbars boxes boxerrorbars
       entry $t.ptype$j -width 2
       entry $t.psize$j -width 2
       entry $t.ltype$j -width 2
       entry $t.lsize$j -width 2
       grid $t.f$j -row $j -column 0
       pack $t.f$j.e -side left
       pack $t.f$j.b -side left
       grid $t.using$j -row $j -column 1
       grid $t.title$j -row $j -column 2
       grid $t.style$j -row $j -column 3
       grid $t.ptype$j -row $j -column 4
       grid $t.psize$j -row $j -column 5
       grid $t.ltype$j -row $j -column 6
       grid $t.lsize$j -row $j -column 7
    }
    frame $t.ff
    grid $t.ff -row $j -column 0 -columnspan 5
    button $t.ff.plot -text plot -command datafileMgrPlot
    checkbutton $t.ff.threeD -text "3D plot" -variable dfmgr_3D
    button $t.ff.close -text close -command {set gp_datafilemgr_window 0; destroy .datafile_manager}
    pack $t.ff.plot -side left 
    pack $t.ff.threeD -side left
    pack $t.ff.close -side left
    set gp_datafilemgr_window 1
}

proc openDatafileManager {} {
    global gp_datafilemgr_window
    if {$gp_datafilemgr_window} {
        focus .datafile_manager
    } else {
        setupDatafileManager
    }
}

proc datafileMgrSelect {n} {
    set tmp [tk_getOpenFile \
	    -title {tkgnuplot: Open File} \
	    -filetypes {{DAT {.dat}} {ALL {*}}}]
    if {$tmp != ""} {
        .datafile_manager.f$n.e insert end $tmp
        .datafile_manager.f$n.e xview end
    }
    focus .datafile_manager
}     

proc datafileMgrPlot {} {
    global dfmgr_3D
    for {set i 1} {$i <= 6} {incr i} {
        global cur_style$i
    }
    set plotfilespec ""
    set t .datafile_manager
    for {set j 1} {$j <= 6} {incr j} {
        set file [$t.f$j.e get]
        if {$file == ""} { continue }
        if {$plotfilespec != ""} { 
            set plotfilespec "$plotfilespec,"
        }
        set plotfilespec [concat $plotfilespec "\"$file\""]
        set using [$t.using$j get]
        if {$using != ""} {
            set plotfilespec [concat $plotfilespec "using $using"]
        }
        set title [$t.title$j get]
        if {$title != ""} {
            set plotfilespec [concat $plotfilespec "title \"$title\""]
        }
        set plotfilespec [concat $plotfilespec with [eval set cur_style$j]]
        set p [$t.ltype$j get]
        if {$p != ""} {
            set plotfilespec [concat $plotfilespec lt $p]
        }
        set p [$t.lsize$j get]
        if {$p != ""} {
            set plotfilespec [concat $plotfilespec lw $p]
        }
        set p [$t.ptype$j get]
        if {$p != ""} {
            set plotfilespec [concat $plotfilespec pt $p]
        }
        set p [$t.psize$j get]
        if {$p != ""} {
            set plotfilespec [concat $plotfilespec ps $p]
        }
    }
    if {$dfmgr_3D} {
       set plotcmd splot
    } else {
       set plotcmd plot
    }
    updateCanvas [list "$plotcmd $plotfilespec"]
}
   
    

############################################################
#
set gp_canvas .fc.c
$gp_canvas create text [expr $width/2] [expr $height/2] -font {Helvetica 14} -text "Tkgnuplot: GNUPLOT graphical user interface" -justify center

after 100 {bind . <Configure> {if {"%W"==".fc.c"} {.fc.c configure -width [expr %w-2] -height [expr %h-2]; updateCanvas [list $gp_com]}}}

############################################################
# binding
bind . <Control-q> {exit}
bind .com.e <Enter> {focus %W}
bind .com.e <Key-Return> {updateCanvas [list [.com.e get]]; addHistory [.com.e get]}
bind .com.e <Control-p> {.com.e delete 0 end; .com.e insert 0 [backHistory]}
bind .com.e <Control-n> {.com.e delete 0 end; .com.e insert 0 [forwardHistory]}
bind .com.e <Key-Up> {.com.e delete 0 end; .com.e insert 0 [backHistory]}
bind .com.e <Key-Down> {.com.e delete 0 end; .com.e insert 0 [forwardHistory]}
bind .fc.c <Button-1>        {updateView %x %y 0; updateViewStart}
bind .fc.c <Button1-Motion>  {updateView %x %y 1}
bind .fc.c <ButtonRelease-1> {updateViewEnd}
bind .fc.c <Button-2>        {updateViewScale %x %y 0; updateViewScaleStart}
bind .fc.c <Button2-Motion>  {updateViewScale %x %y 1}
bind .fc.c <ButtonRelease-2> {updateViewScaleEnd}
bind .fc.c <Control-Button-2>        {updateViewScale %x %y 0 1; updateViewScaleStart}
bind .fc.c <Control-Button2-Motion>  {updateViewScale %x %y 1 1}
bind .fc.c <Control-ButtonRelease-2> {updateViewScaleEnd}
bind .fc.c <Button-3> {makeFloatMenuBase .fc.c %X %Y}
bind .fc.c <Enter> {focus .fc.c}
bind .fc.c <Key-less> {setWindowSize .fc.c [expr [.fc.c cget -width]/2] [expr [.fc.c cget -height]/2]}
bind .fc.c <Key-greater> {setWindowSize .fc.c [expr [.fc.c cget -width]*2] [expr [.fc.c cget -height]*2]}

bind . <Alt-v> {makeViewPointSelector}

bind . <Control-Alt-s> {popupCanvasSnapshot $gp_canvas}
bind . <Control-r> {updateCanvas [list rep]}

bind .fc.c <Enter> {focus %W}
bind .fc.c <Key-Left> {changeView 0 1 1}
bind .fc.c <Key-Right> {changeView 0 -1 1}
bind .fc.c <Key-Up> {changeView 1 0 1}
bind .fc.c <Key-Down> {changeView -1 0 1}
bind .fc.c <Shift-Left> {changeView 0 10 1}
bind .fc.c <Shift-Right> {changeView 0 -10 1}
bind .fc.c <Shift-Up> {changeView 10 0 1}
bind .fc.c <Shift-Down> {changeView -10 0 1}
bind .fc.c <Alt-Left> {changeViewScale .1 0 1; break}
bind .fc.c <Alt-Right> {changeViewScale -.1 0 1}
bind .fc.c <Alt-Up> {changeViewScale 0 .1 1}
bind .fc.c <Alt-Down> {changeViewScale 0 -.1 1}
bind .fc.c <Alt-Shift-Left> {changeViewScale .5 0 1}
bind .fc.c <Alt-Shift-Right> {changeViewScale -.5 0 1}
bind .fc.c <Alt-Shift-Up> {changeViewScale 0 .5 1}
bind .fc.c <Alt-Shift-Down> {changeViewScale 0 -.5 1}

############################################################
# plot shell argument
if {$argc>0} {
    set fname [lindex $argv 0]
    if {[regexp "\.(gpt|gpl|gp|gnu)$" $fname]} {
	addHistory "load '$fname'; rep"
	updateCanvas [list "load '$fname'" "rep"]
    } else {
	addHistory "plot '$fname'"
	updateCanvas [list "plot '$fname'"]
    }
}
