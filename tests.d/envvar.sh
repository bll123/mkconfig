#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

TEST_E="data e"
export TEST_E
TEST_E_D="data e d"
export TEST_E_D
TEST_E2_D="data e2 d"
export TEST_E2_D

maindodisplay $1 command
maindoquery $1 $_MKC_SH_PL

getsname $0
dosetup $@
dorunmkc

chkouth '^#define TEST_E "data e"$'
chkouth '^#define TEST_NE$' neg
chkouth '^#define TEST_E_D data e d$'
chkouth '^#define TEST_E2_D "data e2 d"$'
chkouth '^#define TEST_NE_D def-ne$'
chkouth '^#define TEST_NE2_D "def ne"$'
chkcache "^mkc__env_TEST_E='data e'$"
chkcache "^mkc__envquote_TEST_E='1'$"
chkcache "^mkc__env_TEST_NE=''$" neg
chkcache "^mkc__envquote_TEST_NE='0'$" neg
chkcache "^mkc__env_TEST_E_D='data e d'$"
chkcache "^mkc__envquote_TEST_E_D='0'$"
chkcache "^mkc__env_TEST_E2_D='data e2 d'$"
chkcache "^mkc__envquote_TEST_E2_D='1'$"
chkcache "^mkc__env_TEST_NE_D='def-ne'$"
chkcache "^mkc__envquote_TEST_NE_D='0'$"
chkcache "^mkc__env_TEST_NE2_D='def ne'$"
chkcache "^mkc__envquote_TEST_NE2_D='1'$"

testcleanup

exit $grc
