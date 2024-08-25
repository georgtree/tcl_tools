#RUNF: doc_gen.tcl

lappend auto_path "../"
lappend auto_path "/home/georgtree/tcl/"
set path_to_hl_tcl "/home/georgtree/tcl/hl_tcl"
package require ruff
package require fileutil
set dir [file dirname [file normalize [info script]]]
set sourceDir "${dir}/../src"
source startPage.ruff
source [file join $sourceDir gnuplotutil.tcl]
source [file join $sourceDir mathutil.tcl]
source [file join $sourceDir rfutil.tcl]
source [file join $sourceDir touchstoneutil.tcl]

set packageVersion 0.1

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


foreach file [glob *.html] {
    exec tclsh "${path_to_hl_tcl}/tcl_html.tcl" "./$file"
}

proc processContents {fileContents} {
    # Search: AA, replace: aa
    return [string map {max-width:60rem max-width:100rem} $fileContents]
}

fileutil::updateInPlace ./assets/ruff-min.css processContents