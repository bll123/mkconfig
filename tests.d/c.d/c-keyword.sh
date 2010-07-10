#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " keyword${EC}"
  exit 0
fi

script=$@

grc=0

${script} -C ${_MKCONFIG_RUNTESTDIR}/keyword.dat
grep "^#define _key_long 1$" keyword.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _key_xyzzy 0$" keyword.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv keyword.ctest keyword.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
