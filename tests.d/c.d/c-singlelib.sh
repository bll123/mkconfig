#!/bin/sh

script=$1
echo ${EN} "lib w/req${EC}" >&3

grc=0

../${script} test_02.dat
diff -b test_02.configh config.h
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

diff -b test_02.reqlibs reqlibs.txt
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

echo "## config.h"
cat config.h
echo "## reqlibs.txt"
cat reqlibs.txt
exit $grc

