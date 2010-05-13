#!/bin/sh

script=$@

echo ${EN} "include${EC}" >&5
eval "${script} -C ${_MKCONFIG_RUNTESTDIR}/include.dat"
echo "## diff include.ctmp include.ctest"
sed -e '/^#define _key_/d' -e '/^#define _proto_/d' include.ctest > t
mv t include.ctest
diff -b include.ctmp include.ctest
rc=$?
exit $rc
