#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " option${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

TMP=g-option.opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/g-option.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/g-option.dat
    ;;
esac
grep "^#define TEST_OPT_DEF \"default\"$" g-option.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define TEST_OPT_SET \"abc123\"$" g-option.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define TEST_OPT_SET_SPACE \"abc 123\"$" g-option.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv g-option.ctest g-option.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
