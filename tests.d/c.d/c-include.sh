#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " include${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

${script} -C ${_MKCONFIG_RUNTESTDIR}/include.dat
echo "## $count: $s: diff include.ctmp include.ctest"
sed -e '/^#define _key_/d' -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' include.ctest > t
mv t include.ctest
diff -b include.ctmp include.ctest
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ "$stag" != "" ]; then
  mv include.ctest include.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
