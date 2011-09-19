#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " w/multiple libs${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no cc; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> tst2libb.h echo '
extern int tst2libb ();
'
> tst2libc.h echo '
extern int tst2libc ();
'

> tst2libb.c echo '
#include <stdio.h>
#include <stdlib.h>
#include <tst2libb.h>
#include <tst2libc.h>
int tst2libb () { tst2libc(); return 0; }
'

${CC} -c ${CFLAGS} ${CPPFLAGS} tst2libb.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  exit 1
fi
ar cq libtst2libb.a tst2libb${OBJ_EXT}

cat > tst2libc.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst2libc.h>
int tst2libc () { printf ("hello world\n"); return 0; }
_HERE_

${CC} -c ${CFLAGS} ${CPPFLAGS} tst2libc.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  exit 1
fi
ar cq libtst2libc.a tst2libc${OBJ_EXT}

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-multlib.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-multlib.dat
    ;;
esac
case $script in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh multlib.ctest
    ;;
esac

sed -e '/^#define _key_/d' -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' multlib.ctest > t
mv t multlib.ctest

echo "## diff 1"
diff -b c-multlib.ctmp multlib.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/c-multlib.reqlibs mkconfig.reqlibs
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

if [ "$stag" != "" ]; then
  mv multlib.ctest multlib.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
