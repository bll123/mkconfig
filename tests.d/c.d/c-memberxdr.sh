#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 c-memberxdr
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> h.h echo '
#ifndef _INC_H_H_
#define _INC_H_H_

typedef unsigned int uu_int;

struct aa {
  uu_int aa;
  int bb;
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

chkouth '^#define xdr_aa xdr_uu_int$'
chkouth '^#define xdr_bb xdr_int$'
for x in aa bb; do
  chkouth "^#define _memberxdr_aa_${x} 1$"
done

if [ $grc -eq 0 ]; then
  > mxdr.c echo '
#include <stdio.h>
#include <out.h>
int main (int argc, char *argv []) { return 0; }
'
  chkccompile mxdr.c
fi

testcleanup mxdr.c

exit $grc
