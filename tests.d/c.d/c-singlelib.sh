#!/bin/sh

script=$@
echo ${EN} "lib w/req${EC}" >&3

grc=0

TMP=_tmp_test_02
test -d $TMP && rm -rf $TMP
mkdir $TMP

CFLAGS="-I../$TMP ${CFLAGS}"
LDFLAGS="-L../$TMP ${LDFLAGS}"
export CFLAGS LDFLAGS

cd $TMP

cat > test02b.h <<_HERE_
int test02b ();
_HERE_

cat > test02b.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
#include <test02b.h>
int test02b () { printf ("hello world\n"); return 0; }
_HERE_
${CC} -c ${CFLAGS} test02b.c
if [ $? -ne 0 ]; then
  echo "compile test02b.c failed"
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtest02b.a test02b.o

cd ..

eval "${script} -C test_02.dat"
echo "## diff 1"
diff -b test_02.ctmp test_02.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b test_02.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## config.h"
cat test_02.ctest
echo "## reqlibs.txt"
cat reqlibs.txt
exit $grc

