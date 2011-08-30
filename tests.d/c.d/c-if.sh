#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " if${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-if.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-if.dat
    ;;
esac
for t in \
    _var_a _var_b \
    _test_b1_ok _test_b2_ok _test_b3_ok _test_b4_ok \
    _test_a1_ok _test_a2_ok _test_a3_ok _test_a4_ok _test_a5_ok \
    _test_o1_ok _test_o2_ok _test_o3_ok _test_o4_ok \
        _test_o5_ok _test_o6_ok \
    _test_m1_ok _test_m2_ok _test_m3_ok _test_m4_ok \
    _test_n1_ok _test_n2_ok _test_n3_ok _test_n4_ok \
        _test_n5_ok _test_n6_ok \
    _test_p1_ok _test_p2_ok _test_p3_ok _test_p4_ok \
        _test_p5_ok _test_p6_ok _test_p7_ok \
    ; do
  echo "chk: $t (1)"
  grep "^#define ${t} 1$" c-if.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done

if [ "$stag" != "" ]; then
  mv c-if.ctest c-if.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
