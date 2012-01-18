#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 module
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

chkoutd "^module test.test;$"

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
