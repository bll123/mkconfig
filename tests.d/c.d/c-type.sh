#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " type defined${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
export CFLAGS

> typtst.h echo '
typedef int my_type_t;
'

grc=0
${script} -C ${_MKCONFIG_RUNTESTDIR}/type.dat
grep "^#define _typ_my_type_t 1$" type.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv type.ctest type.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
