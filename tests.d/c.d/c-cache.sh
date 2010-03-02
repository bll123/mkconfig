#!/bin/sh

script=$@

echo ${EN} "cache${EC}" >&3
rm -f test_09.a test_09.b test_09.a.vars test_09.b.vars test_09.ctest
eval "${script} -C test_09.dat"
mv -f test_09.ctest test_09.a
mv -f mkconfig.vars test_09.a.vars
eval "${script} test_09.dat"
mv -f test_09.ctest test_09.b
mv -f mkconfig.vars test_09.b.vars
grc=0
echo "## diff config.h"
diff -b test_09.a test_09.b
if [ $? -ne 0 ]; then grc=$rc; fi
echo "## diff vars"
diff -b test_09.a.vars test_09.b.vars
if [ $? -ne 0 ]; then grc=$rc; fi
rm -f test_09.a test_09.b test_09.a.vars test_09.b.vars test_09.ctest
exit $grc

