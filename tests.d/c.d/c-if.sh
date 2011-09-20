#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 if
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@
dorunmkc
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
  chkouth "^#define ${t} 1$"
done

testcleanup

exit $grc
