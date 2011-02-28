#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " class${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-class.env.dat
. ./class.env

grc=0

DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export DFLAGS LDFLAGS

> classtst.d echo '

module classtst;

class a {
  int       a;
}
'

${DC} ${DFLAGS} -c classtst.d
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

grc=0
${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-class.dat

egrep "^enum (: )?bool ({ )?_class_a = true( })?;$" dclass.d
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dclass.d
  if [ $? -ne 0 ]; then
    echo "## compile dclass.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dclass.d dclass.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
