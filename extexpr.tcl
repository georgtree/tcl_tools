package provide extexpr 0.1

interp alias {} @ {} lindex
interp alias {} = {} expr

proc tcl::mathfunc::maxl {list} {
    # Wraps ::tcl::mathfunc::max command to accept single list instead of expanded one
    return [::tcl::mathfunc::max {*}$list]
}

proc tcl::mathfunc::minl {list} {
    # Wraps ::tcl::mathfunc::min command to accept single list instead of expanded one
    return [::tcl::mathfunc::min {*}$list]
}

proc tcl::mathfunc::logb {value base} {
    # Implements logarithm function with arbitary base
    #  value - value to calculate the logarithm from
    #  base - logarithm base
    # Returns: value of logarithm
    return [= {log($value)/double(log($base))}]
}

### Boolean operations
proc tcl::mathfunc::exactone {args} {
    # Calculates boolean function that returns `true` if only exactly one element is `true`
    #  args - boolean values
    # Returns: boolean
    set first false
    foreach arg $args {
        if {$first && $arg} {
            return false
        }
        if {$arg} {
            set first true
        }
    }
    if {$first} {
        return true
    } else {
        return false
    }
}

### List-scalar operations
proc tcl::mathfunc::mullsc {list scalar} {
    # Multiplies each element of the list to scalar value
    #  list - list of values
    #  scalar - scalar multiplier
    # Returns: list
    set result [list]
    foreach value $list {
        lappend result [= {double($scalar*$value)}]
    }
    return $result
}

proc tcl::mathfunc::sumlsc {list scalar} {
    # Adds scalar value to each element of the list
    #  list - list of values
    #  scalar - scalar value to add
    # Returns: list
    set result [list]
    foreach value $list {
        lappend result [= {double($scalar+$value)}]
    }
    return $result
}

proc tcl::mathfunc::sublsc {list scalar} {
    # Subtracts scalar value from each element of the list
    #  list - list of values
    #  scalar - scalar value to subtract
    # Returns: list
    set result [list]
    foreach value $list {
        lappend result [= {double($value-$scalar)}]
    }
    return $result
}

proc tcl::mathfunc::divlsc {list scalar} {
    # Divides each element of the list to scalar value
    #  list - list of values
    #  scalar - scalar divider
    # Returns: list
    set result [list]
    foreach value $list {
        lappend result [= {double($value)/double($scalar)}]
    }
    return $result
}

proc tcl::mathfunc::powlsc {list scalar} {
    # Exponentiates each element of the list in scalar value
    #  list - list of values
    #  scalar - scalar power value
    # Returns: list
    set result [list]
    foreach value $list {
        lappend result [= {pow($value,$scalar)}]
    }
    return $result
}

### List-list operations
proc tcl::mathfunc::mulll {list1 list2} {
    # Multiplies each element of the list1 to each element of list2
    #  list1 - first list of values
    #  list2 - second list of values
    # Returns: list
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1*$value2)}]
    }
    return $result
}

proc tcl::mathfunc::divll {list1 list2} {
    # Divides each element of the list1 to each element of list2
    #  list1 - first list of values
    #  list2 - second list of values
    # Returns: list
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1)/double($value2)}]
    }
    return $result
}

proc tcl::mathfunc::sumll {list1 list2} {
    # Sums each element of the list1 with each element of list2
    #  list1 - first list of values
    #  list2 - second list of values
    # Returns: list
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1+$value2)}]
    }
    return $result
}

proc tcl::mathfunc::subll {list1 list2} {
    # Subtracts each element of the list2 from each element of list1
    #  list1 - first list of values
    #  list2 - second list of values
    # Returns: list
    set result [list]
    if {[llength $list1]!=[llength $list2]} {
        return -code error "Lengths of the input lists '[llength $list1]' and '[llength $list2]' are not equal"
    }
    foreach value1 $list1 value2 $list2 {
        lappend result [= {double($value1-$value2)}]
    }
    return $result
}

proc tcl::mathfunc::powll {list1 list2} {
    # Exponentiates each element of the list1 in each element of list2
    #  list1 - first list of values
    #  list2 - second list of values
    # Returns: list
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
        # Wraps `llength` command into expr function
        ::llength $list
    }
    proc lindex {list index args} {
        # Wraps `lindex` command into expr function
        ::lindex $list $index {*}$args
    }
    proc li {list index args} {
        # Wraps `lindex` command into expr function
        ::lindex $list $index {*}$args
    }
    proc lrange {list first last} {
        # Wraps `lrange` command into expr function
        ::lrange $list $first $last
    }
}

