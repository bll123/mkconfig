#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " set${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no D compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-set.dat

grep "^enum bool _lib_something" d-set.dtest
rc=$?
if [ $rc -eq 0 ]; then grc=1; fi

l=`grep "^enum int _test1 = 1;$" d-set.dtest | wc -l`
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ $l -ne 1 ]; then grc=1; fi

grep "^enum string _test2 = \"a b c\";$" d-set.dtest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv d-set.dtest d-set.dtest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
