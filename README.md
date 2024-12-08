# Content

This package provides different Tcl tools:
- [Simple wrapper to some 2D plots of Gnuplot](https://georgtree.github.io/tcl_tools/index-gnuplotutil.html) - "src/gnuplotutil.tcl"
- [Some math function](https://georgtree.github.io/tcl_tools/index-mathutil.html) - "src/mathutil.tcl"
- [Basic procedure to read touchstone .s2p files](https://georgtree.github.io/tcl_tools/index-touchstoneutil.html) - "src/touchstoneutil.tcl"
- [Collection of functions to work with 2-port network parameters](https://georgtree.github.io/tcl_tools/index-rfutil.html) - "src/rfutil.tcl"

# Installation and dependencies

Packages are written in pure Tcl and relies on Tcllib. The only necessary external dependency is 
the `argparse` package.

- [Tcllib](https://www.tcl.tk/software/tcllib/)
- [argparse](https://wiki.tcl-lang.org/page/argparse)

To install, run 
```bash
./configure
make
sudo make install
```
If you have different versions of Tcl on the same machine, you can set the path to this version with `-with-tcl=path`
flag to configure script.

# Supported platforms

Any OS that has tcl8.6 (Linux, Windows, FreeBSD).

# Documentation

You can find some documentation [here](https://georgtree.github.io/tcl_tools)
