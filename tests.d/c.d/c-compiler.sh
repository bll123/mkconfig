#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " C compiler works${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

cat > c_compiler.c << _HERE_
main () { exit (0); }
_HERE_

${CC} -o c_compiler.exe c_compiler.c > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ ! -x c_compiler.exe ]; then grc=1; fi
./c_compiler.exe
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

exit $grc
