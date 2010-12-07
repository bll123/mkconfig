#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " ifoption - no options file${EC}"
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
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-nooptfile.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-nooptfile.dat
    ;;
esac
for t in \
    _test_a _test_b; do
  echo "chk: $t (1)"
  grep "^#define ${t} 1$" c-nooptfile.ctest
  rc=$?
  if [ $rc -eq 0 ]; then grc=1; fi
done

if [ "$stag" != "" ]; then
  mv c-nooptfile.ctest c-nooptfile.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
