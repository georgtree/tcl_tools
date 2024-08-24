
package require math::complexnumbers
namespace import math::complexnumbers::*
package require csv
tcl::tm::path add /home/georgtree/tcl_tools/
package require rfutil
package require touchstoneutil
package require gnuplotutil
package require mathutil
#namespace import spconversions::*




set data [touchstoneutil::s2p_read {example_files/ds_top.s2p}]
set zxx [rfutil::s2z $data [complex 50 0]]
set yxx [rfutil::s2y $data [complex 50 0]]
set resultCxx [rfutil::cxxTEq [dict get $data freq] $zxx]
set c1Abs [lmap x [dict get $resultCxx c1] {expr {abs($x)}}]
set c2Abs [lmap x [dict get $resultCxx c2] {expr {abs($x)}}]
set c3Abs [lmap x [dict get $resultCxx c3] {expr {abs($x)}}]

set resultLxx [rfutil::lxxTEq [dict get $data freq] $zxx]
set l1Abs [lmap x [dict get $resultLxx l1] {expr {abs($x)}}]
set l2Abs [lmap x [dict get $resultLxx l2] {expr {abs($x)}}]
set l3Abs [lmap x [dict get $resultLxx l3] {expr {abs($x)}}]

set resultCyxx [rfutil::cxxPEq [dict get $data freq] $yxx]
set cy1Abs [lmap x [dict get $resultCyxx c1] {expr {abs($x)}}]
set cy2Abs [lmap x [dict get $resultCyxx c2] {expr {abs($x)}}]
set cy3Abs [lmap x [dict get $resultCyxx c3] {expr {abs($x)}}]

set resultLyxx [rfutil::lxxPEq [dict get $data freq] $yxx]
set ly1Abs [lmap x [dict get $resultLyxx l1] {expr {abs($x)}}]
set ly2Abs [lmap x [dict get $resultLyxx l2] {expr {abs($x)}}]
set ly3Abs [lmap x [dict get $resultLyxx l3] {expr {abs($x)}}]


#set result [mathutil::trapz [dict get $data freq] $ly1Abs]


#set x1 [list 0 1 2 3 4 5 6]
#set y1 [list 0 1 4 9 16 25 36]
#set x2 [list 0 1 2 3 4 5 6 7]
#set y2 [list 0 1 8 27 64 125 216 350]
#set x3 [list 0 1 2 3 4 5 6 7]
#set y3 [list 0 -1 -8 -27 -64 -125 -216 -350]
#set x4 [list 0 1 2 3 4 5 6 7]
#set y4 [list 0 -1 -8 -27 -64 -125 -216 -350]

#gnuplotutil::plotXNYN -xlabel "x label" -ylabel "y label" -grid -names [list y1 y2 y3 y4] -columns $x1 $y1 $x2 $y2 $x3 $y3 $x4 $y4
#gnuplotutil::plotXYN [dict get $data freq] -xlog -ylog -delete -grid -names [list l1 l2 l3] -columns $ly1Abs $ly2Abs $ly3Abs
#gnuplotutil::plotXNYN -xlog -ylog -grid -names [list "freq, Hz" l1 l2] -columns [dict get $data freq] $ly1Abs [dict get $data freq] $ly2Abs 

set x [list 0 1 2 3 4 5 6 7 8 9 10]
set y [list 0 1 4 9 16 25 36 49 64 81 100]
puts [mathutil::cumtrapz $x $y]



