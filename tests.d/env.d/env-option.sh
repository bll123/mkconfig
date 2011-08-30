#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " option${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

TMP=env-option.opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/env-option.dat

grep "^TEST_OPT_DEF=\"default\"$" env-option.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^TEST_OPT_SET=\"abc123\"$" env-option.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^TEST_OPT_SET_SPACE=\"abc 123\"$" env-option.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv env-option.ctest env-option.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
