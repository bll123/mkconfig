#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 size
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

v=`grep "^#define _siz_long [0-9]*$" out.h | sed 's/.* //'`
grc=1
if [ "$v" != "" ]; then
  if [ $v -ge 4 ]; then
    grc=0
  fi
fi
chkouthcompile

testcleanup

exit $grc
