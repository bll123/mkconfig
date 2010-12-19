#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-type extraction${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-ctype.env.dat
. ./ctype.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > tst4hdr.h << _HERE_
#ifndef _INC_TST4HDR_H_
#define _INC_TST4HDR_H_

typedef unsigned char a;
typedef unsigned short int b;
typedef unsigned int c;
typedef unsigned long int d;
typedef signed char e;
typedef unsigned char f;
typedef signed short int g;
typedef unsigned short int h;
typedef signed int i;
__extension__ typedef signed long long int j;
__extension__ typedef unsigned long long int k;
/* __extension__ typedef struct { int __val[2]; } l; */
__extension__ typedef void * m;
/* typedef struct { int n; } n_t; */
typedef void *o;
/* typedef int (*p)(); */

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-ctype.dat
grc=0

for x in a b c d e f g h i j k m o; do
  grep -l "^enum bool _ctype_${x} = true;$" ctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} ctype.d
  if [ $? -ne 0 ]; then
    echo "compile ctype.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv ctype.d ctype.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
