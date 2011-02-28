#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " import${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no dc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d-import.env.dat
. ./import.env

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-import.dat
egrep "^enum (: )?bool ({ )?_import_std_conv = true( })?;$" dimport.d
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dimport.d
  if [ $? -ne 0 ]; then
    echo "## compile dimport.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dimport.d dimport.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
