#!/bin/sh

script=$@
echo ${EN} "lib w/multiple req${EC}" >&3

grc=0

TMP=_tmp_test_03
test -d $TMP && rm -rf $TMP
mkdir $TMP

CFLAGS="-I../$TMP ${CFLAGS}"
LDFLAGS="-L../$TMP ${LDFLAGS}"
export CFLAGS LDFLAGS

cd $TMP

cat > test03b.h <<_HERE_
int test03b ();
_HERE_
cat > test03c.h <<_HERE_
int test03c ();
_HERE_

cat > test03b.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <test03b.h>
#include <test03c.h>
int test03b () { test03c(); return 0; }
_HERE_
${CC} -c ${CFLAGS} test03b.c
if [ $? -ne 0 ]; then 
  echo "compile test03b.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtest03b.a test03b.o

cat > test03c.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <test03c.h>
int test03c () { printf ("hello world\n"); return 0; }
_HERE_
${CC} -c ${CFLAGS} test03c.c
if [ $? -ne 0 ]; then 
  echo "compile test03b.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtest03c.a test03c.o

cd ..

eval "${script} -C test_03.dat"
echo "## diff 1"
diff -b test_03.ctmp test_03.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b test_03.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

test -d $TMP && rm -rf $TMP 

echo "## config.h"
cat test_03.ctest
echo "## reqlibs.txt"
cat reqlibs.txt
exit $grc
