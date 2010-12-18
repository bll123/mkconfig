#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " import${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no dc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-import.dat
grep "^enum bool _import_std_conv = true;$" header.dtest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv header.dtest header.dtest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
