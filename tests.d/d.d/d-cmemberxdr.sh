#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'c-memberxdr'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> h.h echo '
#ifndef _INC_H_H_
#define _INC_H_H_

typedef unsigned int uu_int;

struct a {
  uu_int a;
  int b;
};

#endif
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

chkoutd '^alias xdr_uu_int xdr_a;$'
chkoutd '^alias xdr_int xdr_b;$'

for x in a b; do
  chkoutd "^enum (: )?bool ({ )?_cmemberxdr_a_${x} = true( })?;$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
