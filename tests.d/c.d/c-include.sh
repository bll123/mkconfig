#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&3
eval "${script} -C test_01.dat"
echo "## diff"
diff -b test_01.ctmp test_01.ctest
rc=$?
echo "## config.h"
cat test_01.ctest
exit $rc

