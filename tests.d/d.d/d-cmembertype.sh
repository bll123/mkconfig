#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-membertype${EC}"
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

cat > memtypehdr.h << _HERE_
#ifndef _INC_MEMTYPEHDR_H_
#define _INC_MEMTYPEHDR_H_

struct getquota_args {
  char *gqa_pathp;
  int gqa_uid;
};

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cmembertype.dat
grc=0

grep -l '^alias char \* C_TYP_gqa_pathp;$' dcmemtype.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
grep -l '^alias int C_TYP_gqa_uid;$' dcmemtype.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

for x in gqa_pathp gqa_uid; do
  grep -l "^enum bool _cmembertype_getquota_args_${x} = true;$" dcmemtype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dcmemtype.d
  if [ $? -ne 0 ]; then
    echo "## compile dcmemtype.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dcmemtype.d dcmemtype.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
