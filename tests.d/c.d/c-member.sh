#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " member${EC}"
  exit 0
fi

script=$@

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> memtst.h echo '
typedef struct xyzzy {
  int       a;
} xyzzy_t;

typedef struct my_struct {
  int       a;
  char      *b;
  void      *c;
  long      d;
  long      *e;
  xyzzy_t   f;
  struct xyzzy g;
} my_struct_t;
'

grc=0
${script} -C ${_MKCONFIG_RUNTESTDIR}/member.dat
for n in a b c d e f g; do
  grep "^#define _mem_my_struct_t_${n} 1$" member.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
  grep "^#define _mem_struct_my_struct_${n} 1$" member.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done
if [ "$stag" != "" ]; then
  mv member.ctest member.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
