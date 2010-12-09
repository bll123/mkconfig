#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " ifoption - no options file${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/env-nooptfile.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/env-nooptfile.dat
    ;;
esac
for t in \
    _test_a _test_b; do
  echo "chk: $t (1)"
  grep "^${t}=\"0\"$" env-nooptfile.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=1; fi
  grep "^${t}=\"1\"$" env-nooptfile.ctest
  rc=$?
  if [ $rc -eq 0 ]; then grc=1; fi
done

if [ "$stag" != "" ]; then
  mv env-nooptfile.ctest env-nooptfile.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
