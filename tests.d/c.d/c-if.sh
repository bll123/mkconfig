#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " if${EC}"
  exit 0
fi

script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

grc=0

dosh=T
case $script in
  *.pl)
    echo ${EN} " skipped${EC}" >&5
    exit 0
    ;;
esac

${_MKCONFIG_SHELL} ${script} -C ${_MKCONFIG_RUNTESTDIR}/if_env.dat
for t in \
    _var_a _var_b \
    _test_b1_ok _test_b2_ok _test_b3_ok _test_b4_ok \
    _test_a1_ok _test_a2_ok _test_a3_ok _test_a4_ok _test_a5_ok \
    _test_o1_ok _test_o2_ok _test_o3_ok _test_o4_ok \
        _test_o5_ok _test_o6_ok \
    _test_m1_ok _test_m2_ok \
    _test_n1_ok _test_n2_ok _test_n3_ok _test_n4_ok \
        _test_n5_ok _test_n6_ok \
    ; do
  echo "chk: $t (1)"
  grep "^${t}=\"1\"$" if_env.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done

if [ "$stag" != "" ]; then
  mv if_env.ctest if_env.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
