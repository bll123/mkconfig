#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " ifoption - no option${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

TMP=c-nooption.opts
cat > $TMP << _HERE_
TEST_ENABLE=enable
TEST_DISABLE=disable
TEST_ASSIGN_T=t
TEST_ASSIGN_F=f
_HERE_

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-nooption.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-nooption.dat
    ;;
esac
for t in \
    _test_a _test_b; do
  echo "chk: $t (1)"
  grep "^#define ${t} 0$" c-nooption.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=1; fi
  grep "^#define ${t} 1$" c-nooption.ctest
  rc=$?
  if [ $rc -eq 0 ]; then grc=1; fi
done

if [ "$stag" != "" ]; then
  mv c-nooption.ctest c-nooption.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
