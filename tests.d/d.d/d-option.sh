#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " option${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no D compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

grc=0

TMP=d-option.opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-option.dat
if [ "$DVERSION" = 1 ]; then
  egrep "^string TEST_OPT_DEF = \"default\";$" d-option.dtest
  rc=$?
else
  egrep "^enum string TEST_OPT_DEF = \"default\";$" d-option.dtest
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$DVERSION" = 1 ]; then
  egrep "^string TEST_OPT_SET = \"abc123\";$" d-option.dtest
  rc=$?
else
  egrep "^enum string TEST_OPT_SET = \"abc123\";$" d-option.dtest
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$DVERSION" = 1 ]; then
  egrep "^string TEST_OPT_SET_SPACE = \"abc 123\";$" d-option.dtest
  rc=$?
else
  egrep "^enum string TEST_OPT_SET_SPACE = \"abc 123\";$" d-option.dtest
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv d-option.dtest d-option.dtest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
