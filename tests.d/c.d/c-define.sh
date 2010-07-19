#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " define${EC}"
  exit 0
fi

stag=$1
shift
script=$@
grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
export CFLAGS

> deftst.h echo '
#define MYDEFINE 20
'

${script} -C ${_MKCONFIG_RUNTESTDIR}/define.dat
grep "^#define _define_MYDEFINE 1$" define.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv define.ctest define.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
