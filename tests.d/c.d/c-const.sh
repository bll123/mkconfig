#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " const${EC}"
  exit 0
fi

script=$@

grc=0

${script} -C ${_MKCONFIG_RUNTESTDIR}/const.dat
grep "^#define _const_O_RDONLY 1$" const.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv const.ctest const.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
