#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c library${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-clib.env.dat
. ./clib.env

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-clib.dat

echo "## diff 1"
diff -b d-clib.ctmp clib.dtest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv clib.dtest clib.dtest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
