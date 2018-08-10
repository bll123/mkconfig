#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'C compiler works'
maindoquery $1 $_MKC_ONCE

chkccompiler
getsname $0
dosetup $@

> c_compiler.c echo '
main () { exit (0); }
'

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkc.sh -d `pwd` -compile \
    -log mkc_compile.log${stag} \
    -e -o c_compiler.exe c_compiler.c
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ ! -x c_compiler.exe ]; then grc=1; fi
./c_compiler.exe
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

testcleanup

exit $grc
