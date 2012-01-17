#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 include
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

dorunmkc

sed -e '/^#define _key_/d' \
    -e '/^#define _proto_/d' \
    -e '/^#define _param_/d' \
    -e '/Created on: /,/Using: mkc/ d' \
    out.h > out.h.n
chkdiff c-include.ctmp out.h.n

testcleanup out.h.n

exit $grc
