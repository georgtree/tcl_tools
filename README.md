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
sudo make install
```
If you have different versions of Tcl on the same machine, you can set the path to this version with `-with-tcl=path`
flag to configure script.

After installation you can run `make test` to test installed packages.

On Windows you can use [MSYS64 UCRT64 environment](https://www.msys2.org/), the above
steps are identical if you run it from UCRT64 shell. After installing the package, you can move tcl_tools package
folder (usually located in `C:\msys64\ucrt64\lib\`) to path listed in `auto_path` variable of your local Tcl
installation.

On the other hands, because the package is Tcl only, you can just download zip package in release section. And then 
put this folder to path listed in `auto_path` variable of your local Tcl installation.

# Supported platforms

Any OS that has tcl8.6/tcl9.0 (Linux, Windows, FreeBSD).

# Documentation

You can find some documentation [here](https://georgtree.github.io/tcl_tools)
Also on Linux you can open manpages installed after run of `make install`.
