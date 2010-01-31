#!/bin/sh

script=$1
echo ${EN} "lib w/multiple req${EC}" >&3

grc=0

export CFLAGS="-I.."
export LDFLAGS="-L.."

rm -f libtest03?.* test03?.* > /dev/null 2>&1

cat > test03b.h <<_HERE_
int test03b ();
int test03c ();
_HERE_

cat > test03b.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
extern int test03c();
int test03b () { test03c(); }
_HERE_
${CC} -shared -fPIC -c ${CFLAGS} test03b.c
${CC} -shared -fPIC -o libtest03b.so test03b.o

cat > test03c.c <<_HERE_
#include <stdio.h>
#include <stdlib.h>
int test03c () { printf ("hello world\n"); }
_HERE_
${CC} -shared -fPIC -c ${CFLAGS} test03c.c
${CC} -shared -fPIC -o libtest03c.so test03c.o

../${script} test_03.dat
diff -b test_03.configh config.h
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

diff -b test_03.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

rm -f libtest03?.* test03?.* > /dev/null 2>&1

echo "## config.h"
cat config.h
echo "## reqlibs.txt"
cat reqlibs.txt
exit $grc
