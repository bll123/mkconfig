#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " declare${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> dcltst.h echo '
int a;
int *b;
int *c;
int d;
'

grc=0
${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/declare.dat
grep "^#define _dcl_a 1$" declare.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _dcl_b 1$" declare.ctest
rc=$?
# these two may or may not work
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _dcl_c [01]$" declare.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _dcl_d [01]$" declare.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv declare.ctest declare.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
