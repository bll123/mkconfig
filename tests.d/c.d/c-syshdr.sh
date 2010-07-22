#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " syshdr${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/syshdr.dat
    ;;
  *)
    ${script} -C ${_MKCONFIG_RUNTESTDIR}/syshdr.dat
    ;;
esac
grep "^#define _sys_types 1$" syshdr.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv syshdr.ctest syshdr.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
