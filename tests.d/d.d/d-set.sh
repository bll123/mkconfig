#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 set
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

chkoutd "^enum (: )?bool ({ )?_lib_something" neg
chkoutd "^enum (: )?int ({ )?_test1 = 1( })?;$" wc 1
if [ "$DVERSION" = 1 ]; then
  chkoutd "^string _test2 = \"a b c\";$"
else
  chkoutd "^enum string _test2 = \"a b c\";$"
fi
if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
