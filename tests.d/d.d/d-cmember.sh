#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-member check${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-cmember.env.dat
. ./cmember.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > cmemhdr.h << _HERE_
#ifndef _INC_cmemhdr_H_
#define _INC_cmemhdr_H_
struct a
{
  long double ld;
  double d;
  long long  ll;
  signed long long  sgll;
  long long int  lli;
  signed long long int  sglli;
  unsigned long long  ull;
  unsigned long long int ulli;
  float f;
  long  l;
  signed long  sgl;
  unsigned long  ul;
  long int li;
  signed long int sgli;
  unsigned long int uli;
  int   i;
  signed int   sgi;
  unsigned int   ui;
  short s;
  signed short sgs;
  short int si;
  signed short int sgsi;
  unsigned short us;
  unsigned short int usi;
  char  c;
  signed char  sgc;
  unsigned char  uc;
  char  carr [20];
};

#endif

_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cmember.dat
grc=0

for x in d ld lli carr; do
  grep -l "^enum bool _cmem_a_${x} = true;$" cmember.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in xyzzy; do
  grep -l "^enum bool _cmem_a_${x} = false;$" cmember.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

if [ "$stag" != "" ]; then
  mv cmember.d cmember.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
