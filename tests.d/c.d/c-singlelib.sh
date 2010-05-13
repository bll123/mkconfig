#!/bin/sh

script=$@
echo ${EN} "w/single lib${EC}" >&5

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

> tst1lib.h echo '
int tst1lib ();
'

cat > tst1lib.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst1lib.h>
int tst1lib () { printf ("hello world\n"); return 0; }
_HERE_

${CC} -c ${CFLAGS} ${CPPFLAGS} tst1lib.c
if [ $? -ne 0 ]; then
  echo "compile tst1lib.c failed"
  exit 1
fi
ar cq libtst1lib.a tst1lib.o

eval "${script} -C ${_MKCONFIG_RUNTESTDIR}/singlelib.dat"
case $script in
  *mkconfig.sh)
    ${_MKCONFIG_RUNTOPDIR}/mkreqlib.sh singlelib.ctest
    ;;
esac

sed -e '/^#define _key_/d' -e '/^#define _proto_/d' singlelib.ctest > t
mv t singlelib.ctest

echo "## diff 1"
diff -b singlelib.ctmp singlelib.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b ${_MKCONFIG_RUNTESTDIR}/singlelib.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

exit $grc
