#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&3
eval "${script} -C test_06.dat"
echo "## diff"
cat test_06.ctest | sed -e '/^#define _key_/d' -e '/^#define _proto_/d' > t
mv t test_06.ctest
diff -b test_06.ctmp test_06.ctest
rc=$?
echo "## config.h"
cat test_06.ctest
exit $rc
