#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-define int${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-cdefint.env.dat
. ./cdefint.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > cdefint.h << _HERE_
#ifndef _INC_cdefint_H_
#define _INC_cdefint_H_

#define a 1
#define b 2

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cdefint.dat
grc=0

grep -l "^enum bool _cdefint_a = true;$" cdefint.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

grep -l "^enum int a = 1;$" cdefint.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

grep -l "^enum bool _cdefint_b = true;$" cdefint.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

grep -l "^enum int b = 2;$" cdefint.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

grep -l "^enum bool _cdefint_c = false;$" cdefint.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=1; fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} cdefint.d
  if [ $? -ne 0 ]; then
    echo "compile cdefint.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv cdefint.d cdefint.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
