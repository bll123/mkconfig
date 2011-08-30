#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " set${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/env-set.dat

l=`grep "^_test1=\"1\"$" env-set.ctest | wc -l`
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ $l -ne 1 ]; then grc=1; fi
grep "^_test2=\"a b c\"$" env-set.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv env-set.ctest env-set.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
