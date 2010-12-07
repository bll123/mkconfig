#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " set${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-set.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-set.dat
    ;;
esac
grep "^#define _define_EOF 0$" c-set.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define _lib_something" c-set.ctest
rc=$?
if [ $rc -eq 0 ]; then grc=1; fi
l=`grep "^#define _test1 1$" c-set.ctest | wc -l`
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ $l -ne 1 ]; then grc=1; fi
grep "^#define _test2 \"a b c\"$" c-set.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv c-set.ctest c-set.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
