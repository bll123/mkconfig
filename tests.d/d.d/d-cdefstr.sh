#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-define string${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-cdefstr.env.dat
. ./cdefstr.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > cdefstr.h << _HERE_
#ifndef _INC_cdefstr_H_
#define _INC_cdefstr_H_

#define a "a"
#define b "abc"

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cdefstr.dat
grc=0

egrep -l "^enum (: )?bool ({ )?_cdefstr_a = true( })?;$" dcdefstr.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

if [ "$DVERSION" = 1 ]; then
  egrep -l "^string a = \"a\"( })?;$" dcdefstr.d > /dev/null 2>&1
  rc=$?
else
  egrep -l "^enum string a = \"a\";$" dcdefstr.d > /dev/null 2>&1
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=1; fi

egrep -l "^enum (: )?bool ({ )?_cdefstr_b = true( })?;$" dcdefstr.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

if [ "$DVERSION" = 1 ]; then
  egrep -l "^string b = \"abc\"( })?;$" dcdefstr.d > /dev/null 2>&1
  rc=$?
else
  egrep -l "^enum string b = \"abc\";$" dcdefstr.d > /dev/null 2>&1
  rc=$?
fi
if [ $rc -ne 0 ]; then grc=1; fi

egrep -l "^enum (: )?bool ({ )?_cdefstr_c = false( })?;$" dcdefstr.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dcdefstr.d
  if [ $? -ne 0 ]; then
    echo "compile dcdefstr.d failed" >&9
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dcdefstr.d dcdefstr.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
