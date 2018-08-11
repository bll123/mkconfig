#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 option
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

TOPTFILE=opts
> $TOPTFILE echo '
TEST_OPT_SET=abc123
TEST_OPT_SET_SPACE=abc 123
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

chkoutd "^(enum )?string TEST_OPT_DEF = \"default\";$"
chkoutd "^(enum )?string TEST_OPT_SET = \"abc123\";$"
chkoutd "^(enum )?string TEST_OPT_SET_SPACE = \"abc 123\";$"

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
