#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'c library'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

grep -v SYSTYPE out.d |
    grep -v 'D_VERSION' |
    grep -v '_d_tango_lib' |
    grep -v '_csiz_' |
    grep -v 'alias [a-z]* C_NATIVE_[a-z_]*;' |
    grep -v 'alias char.. string;' |
    grep -v '_type_string' |
    grep -v '^import std.*string' |
    grep -v '_import_std.*string' |
    grep -v '^$' |
    sed -e 's/: //' -e 's/{ //' -e 's/ }//' > out.d.n
chkdiff d-clib.ctmp out.d.n

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup out.d.n

exit $grc
