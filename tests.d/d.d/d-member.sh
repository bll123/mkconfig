#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " member${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-member.env.dat
. ./member.env

grc=0

DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export DFLAGS LDFLAGS

> memtst.d echo '
struct xyzzy {
  int       a;
}

struct my_struct {
  int          a;
  char *       b;
  void *       c;
  long         d;
  long *       e;
  xyzzy        f;
}
'

grc=0
${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-member.dat

for n in a b c d e f; do
  egrep "^enum (: )?bool ({ )?_mem_my_struct_${n} = true( })?;$" dmember.d
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dmember.d
  if [ $? -ne 0 ]; then
    echo "compile dmember.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv member.d member.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
