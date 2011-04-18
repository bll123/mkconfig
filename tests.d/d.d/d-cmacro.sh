#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-macro${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-cmacro.env.dat
. ./cmacro.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > macrohdr.h << _HERE_
#ifndef _INC_MACROHDR_H_
#define _INC_MACROHDR_H_

#define T0 2
#define T1(a) ((a)+1)
#define T2(a, b) ((a)+(b)+1)
#define T3(a,b,c) ((a)+(b)+(c))
# define T4(args) (args)
#define T5 (3)
#    define   T6(a , b , c) ((a)*(b)*(c))
#define T9(cmd, type)  (((cmd) << 8) | ((type) & 0x0f))

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cmacro.dat
grc=0

for x in T0 T1 T2 T3 T4 T5 T9 ; do
  egrep -l ?"^auto C_MACRO_${x}" dcmacro.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed macro chk"
    grc=1
  fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dcmacro.d
  if [ $? -ne 0 ]; then
    echo "## compile dcmacro.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dcmacro.d dcmacro.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
