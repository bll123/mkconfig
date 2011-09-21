#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'C sys/ header'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

chkoutd "^enum (: )?bool ({ )?_sys_types = true( })?;$"

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
