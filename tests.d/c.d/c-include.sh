#!/bin/sh

script=$1

echo ${EN} "include${EC}" >&3
../${script} test_01.dat
diff -b test_01.configh config.h
rc=$?
echo "## config.h"
cat config.h
exit $rc

