#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&3
eval "${script} -C test_04.dat"
echo "## diff"
ed test_04.ctest << _HERE_ > /dev/null 2>&1
g/^#define _key_/d
g/^#define _proto_/d
w
q
_HERE_
diff -b test_04.ctmp test_04.ctest
rc=$?
echo "## config.h"
cat test_04.ctest
exit $rc

