#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " need prototype${EC}"
  exit 0
fi

script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> nptlib.h echo '
/* int npt1lib (); */
int npt2lib ();
'

cat > nptlib.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <nptlib.h>
int npt1lib () { printf ("hello world\n"); return 0; }
int npt2lib () { printf ("hello world\n"); return 0; }
_HERE_

${CC} -c ${CFLAGS} ${CPPFLAGS} nptlib.c
if [ $? -ne 0 ]; then
  echo "compile nptlib.c failed"
  exit 1
fi
ar cq libnptlib.a nptlib.o

${script} -C ${_MKCONFIG_RUNTESTDIR}/npt.dat
grep "^#define _npt_npt1lib 1$" npt.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _npt_npt2lib 0$" npt.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv npt.ctest npt.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
