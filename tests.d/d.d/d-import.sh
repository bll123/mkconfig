#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 import
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

# check which library
tangolib=`egrep "^enum (: )?bool ({ )?_d_tango_lib = " out.d |
  sed 's/.*= \([^ ;]*\).*/\1/'`
if [ "$tangolib" = "false" ]; then
  chkoutd "^enum (: )?bool ({ )?_import_std_conv = true( })?;$"
else
  chkoutd "^enum (: )?bool ({ )?_import_io_Stdout = true( })?;$"
fi

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
