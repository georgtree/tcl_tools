# Content

This package provides different Tcl tools:
- [Simple wrapper to some 2D plots of Gnuplot](./index-gnuplotutil.html) - "src/gnuplotutil.tcl"
- [Some math function](./index-mathutil.html) - "src/mathutil.tcl"
- [Basic procedure to read touchstone .s2p files](./index-touchstoneutil.html) - "src/touchstoneutil.tcl"
- [Collection of functions to work with 2-port network parameters](./index-rfutil.html) - "src/rfutil.tcl"

# Installation and dependencies

To install this package just unzip code to folder and append `auto_path` variable with location.

Packages are written in pure Tcl and relies on Tcllib. The only necessary external dependency is 
the `argparse` package.

- [Tcllib](https://www.tcl.tk/software/tcllib/)
- [argparse](https://wiki.tcl-lang.org/page/argparse)

# Supported platforms

Any OS that has tcl8.6 (Linux, Windows, FreeBSD).