#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 command
maindoquery $1 $_MKC_SH_PL

getsname $0
dosetup $@
dorunmkc
chkouth '^#define _command_sed 1$'
chkouth '^#define _command_grep 1$'
testcleanup
exit $grc
