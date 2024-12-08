package require tcltest
namespace import ::tcltest::*
set dir [file normalize [file dirname [info script]]]

package require mathutil
package require gnuplotutil
package require rfutil
package require touchstoneutil
configure {*}$argv -testdir $dir
runAllTests
