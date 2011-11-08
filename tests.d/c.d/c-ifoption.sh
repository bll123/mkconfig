#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 c-ifoption
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

TMP=opts
> $TMP echo '
TEST_ENABLE=enable
TEST_DISABLE=disable
TEST_ASSIGN_T=t
TEST_ASSIGN_F=f
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

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
  chkouth "^#define ${t} 1$"
done
chkouthcompile

testcleanup

exit $grc
