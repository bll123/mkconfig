#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " option${EC}"
  exit 0
fi

script=$@

grc=0

TMP=option_c.opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

${script} -C ${_MKCONFIG_RUNTESTDIR}/option_c.dat
grep "^#define TEST_OPT_DEF \"default\"$" option_c.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define TEST_OPT_SET \"abc123\"$" option_c.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^#define TEST_OPT_SET_SPACE \"abc 123\"$" option_c.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv option_c.ctest option_c.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
