#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 size
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

v=`egrep "^enum (: )?int ({ )?_siz_long = 8( })?;$" out.d | sed -e 's/.*= //' -e 's/[ }]*;$//'`
grc=1
if [ "$v" = "8" ]; then
  grc=0
fi

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
