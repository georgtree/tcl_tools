package provide extexpr 0.1

interp alias {} @ {} lindex
interp alias {} = {} expr

proc tcl::mathfunc::maxl {values} {
    return [::tcl::mathfunc::max {*}$values]
}

proc tcl::mathfunc::minl {values} {
    return [::tcl::mathfunc::min {*}$values]
}

### List-scalar operations
proc tcl::mathfunc::multscl {scalar values} {
    set result [list]
    foreach value $values {
        lappend result [= {double($scalar*$value)}]
    }
    return $result
}

proc tcl::mathfunc::divlsc {values scalar} {
    set result [list]
    foreach value $values {
        lappend result [= {double($value)/double($scalar)}]
    }
    return $result
}

proc tcl::mathfunc::powlsc {values scalar} {
    set result [list]
    foreach value $values {
        lappend result [= {pow($value,$scalar)}]
    }
    return $result
}

### List-list operations
proc tcl::mathfunc::mulls {list1 list2} {
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1*$value2)}]
    }
    return $result
}

proc tcl::mathfunc::divls {list1 list2} {
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1)/double($value2)}]
    }
    return $result
}

proc tcl::mathfunc::sumls {list1 list2} {
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1+$value2)}]
    }
    return $result
}

proc tcl::mathfunc::subls {list1 list2} {
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1-$value2)}]
    }
    return $result
}

proc tcl::mathfunc::powls {list1 list2} {
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {pow($value1,$value2)}]
    }
    return $result
}

### List commands
namespace eval tcl::mathfunc {
    proc llength {list} {
        ::llength $list
    }
    proc lindex {list index args} {
        ::lindex $list $index {*}$args
    }
    proc lrange {list first last} {
        ::lrange $list $first $last
    }
}

