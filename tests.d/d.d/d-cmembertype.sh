#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'c-membertype'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> memtypehdr.h echo '
#ifndef _INC_MEMTYPEHDR_H_
#define _INC_MEMTYPEHDR_H_

struct getquota_args {
  char *gqa_pathp;
  int gqa_uid;
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

chkoutd '^alias char \* C_TYP_gqa_pathp;$'
chkoutd '^alias int C_TYP_gqa_uid;$'

for x in gqa_pathp gqa_uid; do
  chkoutd "^enum (: )?bool ({ )?_cmembertype_getquota_args_${x} = true( })?;$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
