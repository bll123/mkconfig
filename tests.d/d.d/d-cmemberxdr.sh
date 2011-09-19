#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-memberxdr${EC}"
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

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > h.h << _HERE_
#ifndef _INC_H_H_
#define _INC_H_H_

typedef unsigned int uu_int;

struct a {
  uu_int a;
  int b;
};

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cmemberxdr.dat
grc=0

grep -l '^alias xdr_uu_int xdr_a;$' d.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep -l '^alias xdr_int xdr_b;$' d.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

for x in a b; do
  grep -l "^enum bool _cmemberxdr_a_${x} = true;$" d.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} d.d
  if [ $? -ne 0 ]; then
    echo "## compile d.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv d.d d.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
