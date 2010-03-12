#!/bin/sh

script=$@
echo ${EN} "w/single lib${EC}" >&3

grc=0

set -x

CFLAGS="-I$RUNTMPDIR ${CFLAGS}"
LDFLAGS="-L$RUNTMPDIR ${LDFLAGS}"
export CFLAGS LDFLAGS

cat > tst1lib.h <<_HERE_
int tst1lib ();
_HERE_

cat > tst1lib.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst1lib.h>
int tst1lib () { printf ("hello world\n"); return 0; }
_HERE_
${CC} -c ${CFLAGS} tst1lib.c
if [ $? -ne 0 ]; then
  echo "compile tst1lib.c failed"
  exit 1
fi
ar cq libtst1lib.a tst1lib.o

eval "${script} -C $RUNTESTDIR/singlelib.dat"
cat singlelib.ctest | sed -e '/^#define _key_/d' -e '/^#define _proto_/d' > t
mv t singlelib.ctest
echo "## diff 1"
diff -b singlelib.ctmp singlelib.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b $RUNTESTDIR/singlelib.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## config.h"
cat singlelib.ctest
echo "## reqlibs.txt"
cat reqlibs.txt

exit $grc
