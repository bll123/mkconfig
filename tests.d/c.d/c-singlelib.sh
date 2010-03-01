#!/bin/sh

script=$@
echo ${EN} "w/lib${EC}" >&3

grc=0

TMP=_tmp_test_05
test -d $TMP && rm -rf $TMP
mkdir $TMP

CFLAGS="-I../$TMP ${CFLAGS}"
LDFLAGS="-L../$TMP ${LDFLAGS}"
export CFLAGS LDFLAGS

cd $TMP

cat > test05b.h <<_HERE_
int test05b ();
_HERE_

cat > test05b.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <test05b.h>
int test05b () { printf ("hello world\n"); return 0; }
_HERE_
${CC} -c ${CFLAGS} test05b.c
if [ $? -ne 0 ]; then
  echo "compile test05b.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtest05b.a test05b.o

cd ..

eval "${script} -C test_05.dat"
echo "## diff 1"
ed test_05.ctest << _HERE_ > /dev/null 2>&1
g/^#define _key_/d
g/^#define _proto_/d
w
q
_HERE_
diff -b test_05.ctmp test_05.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b test_05.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## config.h"
cat test_05.ctest
echo "## reqlibs.txt"
cat reqlibs.txt
exit $grc

