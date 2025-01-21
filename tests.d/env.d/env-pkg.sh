#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 pkg
maindoquery $1 $_MKC_SH

getsname $0
dosetup $@
cp ${_MKCONFIG_RUNTESTDIR}/testlib.pc ${_MKCONFIG_TSTRUNTMPDIR}
dorunmkc

chkenv "^CFLAGS_APPLICATION=\".*-I/.*libpng" wc 1
chkenv "^LDFLAGS_LIBS_APPLICATION=\".*-lz" wc 1
chkenv "^CFLAGS_APPLICATION=\".*-I\.\." wc 1

testcleanup
exit $grc
