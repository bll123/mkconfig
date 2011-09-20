#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'C compiler works'
maindoquery $1 $_MKC_ONCE

chkccompiler
getsname $0
dosetup $@
dorunmkc

cat > c_compiler.c << _HERE_
main () { exit (0); }
_HERE_

${CC} -o c_compiler.exe c_compiler.c > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi
if [ ! -x c_compiler.exe ]; then grc=1; fi
./c_compiler.exe
rc=$?
if [ $rc -ne 0 ]; then grc=$rc; fi

testcleanup

exit $grc
