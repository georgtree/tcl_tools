#RUNF: doc_gen.tcl

lappend auto_path "../"
lappend auto_path "/home/georgtree/tcl/"
package require ruff
package require fileutil
set dir [file dirname [file normalize [info script]]]
set sourceDir "${dir}/../src"
source startPage.ruff
#source tutorials.ruff
#source faq.ruff
#source tips.ruff
source [file join $sourceDir gnuplotutil.tcl]
source [file join $sourceDir mathutil.tcl]
source [file join $sourceDir rfutil.tcl]
source [file join $sourceDir touchstoneutil.tcl]

set packageVersion [package versions SpiceGenTcl]

set title "Collection of Tcl tools"

set common [list \
                -title $title \
                -sortnamespaces false \
                -preamble $startPage \
                -pagesplit namespace \
                -recurse false \
                -includesource true \
                -pagesplit namespace \
                -autopunctuate true \
                -compact false \
                -includeprivate true \
                -product tcl_tools \
                -diagrammer "ditaa --border-width 1" \
                -version $packageVersion \
                -copyright "George Yashin" {*}$::argv
               ]
set namespaces [list ::gnuplotutil ::mathutil ::rfutil ::touchstoneutil]

if {[llength $argv] == 0 || "html" in $argv} {
    ruff::document $namespaces \
        -format html \
        -outfile index.html \
        {*}$common
}


exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-gnuplotutil.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-mathutil.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-rfutil.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-touchstoneutil.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-docindex.html" 

proc processContents {fileContents} {
    # Search: AA, replace: aa
    return [string map {max-width:60rem max-width:100rem} $fileContents]
}

fileutil::updateInPlace ./assets/ruff-min.css processContents