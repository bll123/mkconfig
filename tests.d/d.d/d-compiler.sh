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
int main (char[][] args) { return 0; }
_HERE_

${DC} d_compiler.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ -x a.out ]; then
  ./a.out
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
elif [ -x d_compiler ]; then
  ./d_compiler
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
elif [ -x d_compiler.exe ]; then
  ./d_compiler.exe
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
else
  grc=1
fi

exit $grc
