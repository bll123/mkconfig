#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&3
eval "${script} -C test_06.dat"
echo "## diff"
ed test_06.ctest << _HERE_ > /dev/null 2>&1
g/^#define _key_/d
g/^#define _proto_/d
w
q
_HERE_
diff -b test_06.ctmp test_06.ctest
rc=$?
echo "## config.h"
cat test_06.ctest
exit $rc
