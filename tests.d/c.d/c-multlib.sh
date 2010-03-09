#!/bin/sh

script=$@
echo ${EN} "w/multiple lib${EC}" >&3

grc=0

TMP=_tmp_test_08
test -d $TMP && rm -rf $TMP
mkdir $TMP

CFLAGS="-I../$TMP ${CFLAGS}"
LDFLAGS="-L../$TMP ${LDFLAGS}"
export CFLAGS LDFLAGS

cd $TMP

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
${CC} -c ${CFLAGS} tst2libb.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtst2libb.a tst2libb.o

cat > tst2libc.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <tst2libc.h>
int tst2libc () { printf ("hello world\n"); return 0; }
_HERE_
${CC} -c ${CFLAGS} tst2libc.c
if [ $? -ne 0 ]; then
  echo "compile tst2libb.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtst2libc.a tst2libc.o

cd ..

eval "${script} -C test_08.dat"
cat test_08.ctest | sed -e '/^#define _key_/d' -e '/^#define _proto_/d' > t
mv t test_08.ctest
echo "## diff 1"
diff -b test_08.ctmp test_08.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b test_08.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

test -d $TMP && rm -rf $TMP

echo "## config.h"
cat test_08.ctest
echo "## reqlibs.txt"
cat reqlibs.txt

exit $grc
