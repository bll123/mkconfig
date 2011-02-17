#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " set${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-set.env.dat
. ./set.env

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-set.dat

egrep "^enum (: )?bool ({ )?_lib_something" dset.d
rc=$?
if [ $rc -eq 0 ]; then grc=1; fi

l=`egrep "^enum (: )?int ({ )?_test1 = 1( })?;$" dset.d | wc -l`
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ $l -ne 1 ]; then grc=1; fi

if [ "$DVERSION" = 1 ]; then
  egrep "^string _test2 = \"a b c\";$" dset.d
  rc=$?
else
  egrep "^enum string _test2 = \"a b c\";$" dset.d
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dset.d
  if [ $? -ne 0 ]; then
    echo "compile dset.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dset.d dset.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
