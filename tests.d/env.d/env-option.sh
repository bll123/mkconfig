#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " option${EC}"
  exit 0
fi

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

grc=0
count=1

dosh=T
case $script in
  *.pl)
    dosh=F
    ;;
esac

TMP=option_env.opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

${_MKCONFIG_SHELL} ${script} -C ${_MKCONFIG_RUNTESTDIR}/option_env.dat
grep "^TEST_OPT_DEF=\"default\"$" option_env.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^TEST_OPT_SET=\"abc123\"$" option_env.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep "^TEST_OPT_SET_SPACE=\"abc 123\"$" option_env.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv option_env.ctest option_env.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
