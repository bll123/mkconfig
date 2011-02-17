#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " C header${EC}"
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

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-chdr.dat

egrep "^enum (: )?bool ({ )?_hdr_ctype = true( })?;$" dchdr.d
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dchdr.d
  if [ $? -ne 0 ]; then
    echo "compile dchdr.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dchdr.d dchdr.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
