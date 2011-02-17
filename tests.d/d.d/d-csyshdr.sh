#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " C sys/ header${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-csyshdr.env.dat
. ./csyshdr.env

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-csyshdr.dat

egrep "^enum (: )?bool ({ )?_sys_types = true( })?;$" dcsyshdr.d
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dcsyshdr.d
  if [ $? -ne 0 ]; then
    echo "compile dcsyshdr.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dcsyshdr.d dcsyshdr.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
