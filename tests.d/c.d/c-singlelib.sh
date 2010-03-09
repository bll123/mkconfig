#!/bin/sh

script=$@
echo ${EN} "w/single lib${EC}" >&3

grc=0

TMP=_tmp_test_07
test -d $TMP && rm -rf $TMP
mkdir $TMP

CFLAGS="-I../$TMP ${CFLAGS}"
LDFLAGS="-L../$TMP ${LDFLAGS}"
export CFLAGS LDFLAGS

cd $TMP

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
  cd ..
  test -d $TMP && rm -rf $TMP
  exit 1
fi
ar cq libtst1lib.a tst1lib.o

cd ..

eval "${script} -C test_07.dat"
cat test_07.ctest | sed -e '/^#define _key_/d' -e '/^#define _proto_/d' > t
mv t test_07.ctest
echo "## diff 1"
diff -b test_07.ctmp test_07.ctest
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## diff 2"
diff -b test_07.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## config.h"
cat test_07.ctest
echo "## reqlibs.txt"
cat reqlibs.txt

exit $grc

