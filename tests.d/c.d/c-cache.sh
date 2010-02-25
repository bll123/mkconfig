#!/bin/sh

script=$@

echo ${EN} "cache${EC}" >&3
rm -f test_07.a test_07.b test_07.a.vars test_07.b.vars test_07.ctest
eval "${script} -C test_07.dat"
mv -f test_07.ctest test_07.a
mv -f mkconfig.vars test_07.a.vars
eval "${script} test_07.dat"
mv -f test_07.ctest test_07.b
mv -f mkconfig.vars test_07.b.vars
grc=0
echo "## diff config.h"
diff -b test_07.a test_07.b
if [ $? -ne 0 ]; then grc=$rc; fi
echo "## diff vars"
diff -b test_07.a.vars test_07.b.vars
if [ $? -ne 0 ]; then grc=$rc; fi
rm -f test_07.a test_07.b test_07.a.vars test_07.b.vars test_07.ctest
exit $grc

