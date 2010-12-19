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
main () { printf ("hello world\n"); }
_HERE_

${CC} c_compiler.c > /dev/null 2>&1
rc=$?

if [ $rc -ne 0 ]; then grc=$rc; fi

exit $grc
