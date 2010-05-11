#!/bin/sh

script=$@
echo ${EN} "w/multiple lib${EC}" >&3

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

cat > tst2libb.h <<_HERE_
int tst2libb ();
_HERE_
cat > tst2libc.h <<_HERE_
int tst2libc ();
_HERE_

cat > tst2libb.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst2libb.h>
#include <tst2libc.h>
int tst2libb () { tst2libc(); return 0; }
_HERE_
${CC} -c ${CFLAGS} ${CPPFLAGS} tst2libb.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  exit 1
fi
ar cq libtst2libb.a tst2libb.o

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
ar cq libtst2libc.a tst2libc.o

eval "${script} -C ${_MKCONFIG_RUNTESTDIR}/multlib.dat"
case $script in
  *mkconfig.sh)
    ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh multlib.ctest
    ;;
esac

cat multlib.ctest |
    sed -e '/^#define _key_/d' -e '/^#define _proto_/d' > t
mv t multlib.ctest

echo "## diff 1"
diff -b multlib.ctmp multlib.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/multlib.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

exit $grc
