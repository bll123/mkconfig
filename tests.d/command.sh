#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 command
maindoquery $1 $_MKC_SH_PL

getsname $0
dosetup $@
dorunmkc

chkouth '^#define _command_xblah 0$'
chkouth '^#define _command_sed 1$'
chkouth '^#define _cmd_loc_sed "/.*/sed"$'
chkouth '^#define _command_grep 1$'
chkouth '^#define _cmd_loc_grep "/.*/grep"$'
chkouth '^#define _command_awk 1$'
chkouth '^#define _cmd_loc_awk "/.*/grep"$'

testcleanup

exit $grc
