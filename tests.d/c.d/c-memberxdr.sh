#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-memberxdr${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no C compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

grc=0

cat > h.h << _HERE_
#ifndef _INC_H_H_
#define _INC_H_H_

typedef unsigned int uu_int;

struct aa {
  uu_int aa;
  int bb;
};

#endif
_HERE_

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-memberxdr.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-memberxdr.dat
    ;;
esac

grc=0

grep -l '^#define xdr_aa xdr_uu_int$' out.h > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep -l '^#define xdr_bb xdr_int$' out.h > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

for x in aa bb; do
  grep -l "^#define _memberxdr_aa_${x} 1$" out.h > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done

if [ $grc -eq 0 ]; then
  cat > c.c << _HERE_
#include <stdio.h>
#include <out.h>
int main (int argc, char *argv []) { return 0; }
_HERE_
  ${CC} -c ${CPPFLAGS} ${CFLAGS} c.c
  if [ $? -ne 0 ]; then
    echo "## compile c.c failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  for i in out.h mkconfig.log mkconfig.cache mkconfig_c.vars; do
    mv $i ${i}${stag}
  done
fi

exit $grc
