global env
set nagelfarPath "/home/$env(USER)/tcl/nagelfar/"
set currentDir [file dirname [file normalize [info script]]]
#cd $nagelfarPath
set srcList [list mathutil.tcl rfutil.tcl touchstoneutil.tcl]
# instrument all files in src folder
foreach file $srcList {
    exec [file join ${nagelfarPath} nagelfar.tcl] -instrument [file join ${currentDir} .. src {*}$file]
}
# rename initial source files, then rename instrument files to the original name of the source file
foreach file $srcList {
    file rename [file join ${currentDir} .. src "[lindex $file 0]"]\
            [file join ${currentDir} .. src "[lindex $file 0]_orig"]
    file rename [file join ${currentDir} .. src "[lindex $file 0]_i"]\
            [file join ${currentDir} .. src "[lindex $file 0]"]
}

# tests run
exec tclsh [file join ${currentDir} mathutil.test]
exec tclsh [file join ${currentDir} rfutil.test]
exec tclsh [file join ${currentDir} touchstoneutil.test]
# revert renaming
foreach file $srcList {
    file rename [file join ${currentDir} .. src "[lindex $file 0]"]\
            [file join ${currentDir} .. src "[lindex $file 0]_i"]
    file rename [file join ${currentDir} .. src "[lindex $file 0]_orig"]\
            [file join ${currentDir} .. src "[lindex $file 0]"]
}
# create markup files
foreach file $srcList {
    lappend results [exec [file join ${nagelfarPath} nagelfar.tcl] -markup [file join ${currentDir} .. src {*}$file]]
}
# view results
foreach file $srcList {
    exec eskil -noparse [file join ${currentDir} .. src [lindex $file 0]]\
            [file join ${currentDir} .. src "[lindex $file 0]_m"]
}
puts [join $results "\n"]
# remove tests files
foreach file $srcList {
    file delete [file join ${currentDir} .. src "[lindex $file 0]_i"]
    file delete [file join ${currentDir} .. src "[lindex $file 0]_log"]
    file delete [file join ${currentDir} .. src "[lindex $file 0]_m"]
}
