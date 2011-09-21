#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'c-member'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> cmemhdr.h echo '
#ifndef _INC_cmemhdr_H_
#define _INC_cmemhdr_H_
struct a
{
  long double ld;
  double d;
  long long  ll;
  signed long long  sgll;
  long long int  lli;
  signed long long int  sglli;
  unsigned long long  ull;
  unsigned long long int ulli;
  float f;
  long  l;
  signed long  sgl;
  unsigned long  ul;
  long int li;
  signed long int sgli;
  unsigned long int uli;
  int   i;
  signed int   sgi;
  unsigned int   ui;
  short s;
  signed short sgs;
  short int si;
  signed short int sgsi;
  unsigned short us;
  unsigned short int usi;
  char  c;
  signed char  sgc;
  unsigned char  uc;
  char  carr [20];
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

for x in d ld lli carr; do
  chkoutd "^enum (: )?bool ({ )?_cmem_a_${x} = true( })?;$"
done

for x in xyzzy; do
  chkoutd "^enum (: )?bool ({ )?_cmem_a_${x} = false( })?;$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
