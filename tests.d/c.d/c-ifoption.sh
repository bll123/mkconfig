#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " ifoption${EC}"
  exit 0
fi

stag=$1
shift
script=$@

grc=0

TMP=ifoption_env.opts
cat > $TMP << _HERE_
TEST_ENABLE=enable
TEST_DISABLE=disable
TEST_ASSIGN_T=t
TEST_ASSIGN_F=f
_HERE_

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/ifoption_env.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/ifoption_env.dat
    ;;
esac
for t in \
    _test_enable _test_disable \
    _test_assign_t _test_assign_f \
    _test_else_enable _test_else_disable \
    _test_else_assign_t _test_else_assign_f \
    _test_neg_enable _test_neg_disable \
    _test_neg_assign_t _test_neg_assign_f \
    _test_else_neg_enable _test_else_neg_disable \
    _test_else_neg_assign_t _test_else_neg_assign_f \
    _test_a _test_b _test_c _test_d _test_e _test_f _test_g \
    _test_h _test_i _test_j _test_k _test_l _test_m _test_n; do
  echo "chk: $t (1)"
  grep "^${t}=\"1\"$" ifoption_env.ctest
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi
done
if [ "$stag" != "" ]; then
  mv ifoption_env.ctest ifoption_env.ctest${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_env.vars mkconfig_env.vars${stag}
fi

exit $grc
