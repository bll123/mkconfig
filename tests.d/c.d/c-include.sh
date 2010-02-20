#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&3
eval "${script} -C test_04.dat"
echo "## diff"
diff -b test_04.ctmp test_04.ctest
rc=$?
echo "## config.h"
cat test_04.ctest
exit $rc

