#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " header${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-header.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-header.dat
    ;;
esac
grep "^#define _sys_types 1$" header.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _hdr_ctype 1$" header.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv header.ctest header.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
