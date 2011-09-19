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

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

grc=0

TMP=d-option.opts
cat > $TMP << _HERE_
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-option.dat
if [ "$DVERSION" = 1 ]; then
  egrep "^string TEST_OPT_DEF = \"default\";$" doption.d
  rc=$?
else
  egrep "^enum string TEST_OPT_DEF = \"default\";$" doption.d
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$DVERSION" = 1 ]; then
  egrep "^string TEST_OPT_SET = \"abc123\";$" doption.d
  rc=$?
else
  egrep "^enum string TEST_OPT_SET = \"abc123\";$" doption.d
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$DVERSION" = 1 ]; then
  egrep "^string TEST_OPT_SET_SPACE = \"abc 123\";$" doption.d
  rc=$?
else
  egrep "^enum string TEST_OPT_SET_SPACE = \"abc 123\";$" doption.d
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} doption.d
  if [ $? -ne 0 ]; then
    echo "## compile doption.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv doption.d doption.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
