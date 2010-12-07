#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " D compiler works${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no d compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

set -x
cat > d_compiler.d << _HERE_
import std.stdio;
void main (char[][] args) { writeln ("hello world"); }
_HERE_

${DC} d_compiler.d > /dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then grc=$rc; fi

exit $grc
