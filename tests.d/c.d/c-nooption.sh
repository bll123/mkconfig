#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " ifoption - no option${EC}"
  exit 0
fi

script=$@

grc=0

TMP=nooption_c.opts
cat > $TMP << _HERE_
TEST_ENABLE=enable
TEST_DISABLE=disable
TEST_ASSIGN_T=t
TEST_ASSIGN_F=f
_HERE_

${script} -C ${_MKCONFIG_RUNTESTDIR}/nooption_c.dat
for t in \
    _test_a _test_b; do
  echo "chk: $t (1)"
  grep "^#define ${t} 1$" nooption_c.ctest
rc=$?
  if [ $rc -eq 0 ]; then grc=1; fi
done

if [ "$stag" != "" ]; then
  mv nooption_c.ctest nooption_c.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
