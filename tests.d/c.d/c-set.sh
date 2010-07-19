#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " set${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

${script} -C ${_MKCONFIG_RUNTESTDIR}/set_c.dat
grep "^#define _define_EOF 0$" set_c.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _lib_something" set_c.ctest
rc=$?
if [ $rc -eq 0 ]; then grc=1; fi
l=`grep "^#define _test1 1$" set_c.ctest | wc -l`
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ $l -ne 1 ]; then grc=1; fi
grep "^#define _test2 \"a b c\"$" set_c.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv set_c.ctest set_c.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
