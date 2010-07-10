#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " command${EC}"
  exit 0
fi

script=$@

grc=0

${script} -C ${_MKCONFIG_RUNTESTDIR}/command.dat
grep "^#define _command_sed 1$" command.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _command_grep 1$" command.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv command.ctest command.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
