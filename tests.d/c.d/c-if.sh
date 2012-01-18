#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 if
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc
for t in \
    _var_a _var_b \
    _test_b1_ok _test_b2_ok _test_b3_ok _test_b4_ok _test_b5_ok \
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
for t in _var_c _var_d _test_b6_ok; do
  echo "chk: $t (0)"
  chkouth "^#define ${t} 0$"
done

t=_var_e
echo "chk: $t (abc)"
chkouth "^#define ${t} \"abc\"$"
t=_var_f
echo "chk: $t (abc def)"
chkouth "^#define ${t} \"abc def\"$"
t=_var_g
echo "chk: $t (abc def ghi)"
chkouth "^#define ${t} \"abc def ghi\"$"

chkouthcompile

testcleanup

exit $grc
