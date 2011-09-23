#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 c-memberxdr
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> mxdr.h echo '
#ifndef _INC_mxdr_H
#define _INC_mxdr_H

typedef unsigned int uu_int;

struct aa {
  uu_int bb;
  int cc;
};

#endif
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

chkouth '^#define xdr_bb xdr_uu_int$'
chkouth '^#define xdr_cc xdr_int$'
for x in bb cc; do
  chkouth "^#define _memberxdr_aa_${x} 1$"
done
chkouthcompile

testcleanup mxdr.c

exit $grc
