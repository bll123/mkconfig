#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&3
eval "${script} -C ${_MKCONFIG_RUNTESTDIR}/include.dat"
echo "## diff include.ctmp include.ctest"
cat include.ctest |
    sed -e '/^#define _key_/d' -e '/^#define _proto_/d' > t
mv t include.ctest
diff -b include.ctmp include.ctest
rc=$?
exit $rc
