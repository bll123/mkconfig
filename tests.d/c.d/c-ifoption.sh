#!/bin/sh

set -x
script=$@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

echo ${EN} "ifoption${EC}" >&5
grc=0
count=1

dosh=T
case $script in
  *.pl)
    echo ${EN} " skipped${EC}" >&5
    exit 0
    ;;
esac

OPTIONS="WITH_TEST_WITH WITHOUT_TEST_WITHOUT
    ENABLE_TEST_ENABLE DISABLE_TEST_DISABLE
    TEST_ASSIGN_T=T TEST_ASSIGN_F=F"
export OPTIONS

if [ "$dosh" = "T" ]; then
  echo ${EN} " ${EC}" >&5
  for s in $shelllist; do
    unset _shell
    unset shell
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
    ss=`eval $cmd`
    if [ "$ss" = "sh" ]; then
      ss=`echo $s | sed 's,.*/,,'`
    fi
    echo ${EN} "${ss} ${EC}" >&5
    echo "## testing with ${s} "
    _MKCONFIG_SHELL=$s
    export _MKCONFIG_SHELL
    shell=$ss

    eval "${s} ${script} -C ${_MKCONFIG_RUNTESTDIR}/ifoption_env.dat"
    for t in \
        _test_with _test_without \
        _test_enable _test_disable \
        _test_assign_t _test_assign_f \
        _test_else_with _test_else_without \
        _test_else_enable _test_else_disable \
        _test_else_assign_t _test_else_assign_f \
        _test_neg_with _test_neg_without \
        _test_neg_enable _test_neg_disable \
        _test_neg_assign_t _test_neg_assign_f \
        _test_else_neg_with _test_else_neg_without \
        _test_else_neg_enable _test_else_neg_disable \
        _test_else_neg_assign_t _test_else_neg_assign_f \
        _test_a _test_b _test_c _test_d _test_e _test_f _test_g \
        _test_h _test_i _test_j _test_k _test_l _test_m _test_n; do
      echo "chk: $t (1)"
      grep "^${t}=\"1\"$" ifoption_env.ctest
      rc=$?
      if [ $rc -ne 0 ]; then grc=$rc; fi
    done
    mv ifoption_env.ctest ifoption_env.ctest.${count}
    mv mkconfig.log mkconfig.log.${count}
    mv mkconfig.cache mkconfig.cache.${count}
    mv mkconfig_env.vars mkconfig_env.vars.${count}
    domath count "$count + 1"
  done
fi

exit $grc
