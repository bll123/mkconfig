#!/bin/sh

script=$@
echo ${EN} "w/multiple lib${EC}" >&3

grc=0

TMP=_tmp_test_06
test -d $TMP && rm -rf $TMP
mkdir $TMP

CFLAGS="-I../$TMP ${CFLAGS}"
LDFLAGS="-L../$TMP ${LDFLAGS}"
export CFLAGS LDFLAGS

cd $TMP

cat > test06b.h <<_HERE_
int test06b ();
_HERE_
cat > test06c.h <<_HERE_
int test06c ();
_HERE_

cat > test06b.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <test06b.h>
#include <test06c.h>
int test06b () { test06c(); return 0; }
_HERE_
${CC} -c ${CFLAGS} test06b.c
if [ $? -ne 0 ]; then 
  echo "compile test06b.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtest06b.a test06b.o

cat > test06c.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <test06c.h>
int test06c () { printf ("hello world\n"); return 0; }
_HERE_
${CC} -c ${CFLAGS} test06c.c
if [ $? -ne 0 ]; then 
  echo "compile test06b.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtest06c.a test06c.o

cd ..

eval "${script} -C test_06.dat"
echo "## diff 1"
ed test_06.ctest << _HERE_ > /dev/null 2>&1
g/^#define _key_/d
g/^#define _proto_/d
w
q
_HERE_
diff -b test_06.ctmp test_06.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b test_06.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

test -d $TMP && rm -rf $TMP 

echo "## config.h"
cat test_06.ctest
echo "## reqlibs.txt"
cat reqlibs.txt
exit $grc
