#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'c-type size'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> typehdr.h echo '
#ifndef _INC_TYPEHDR_H_
#define _INC_TYPEHDR_H_

typedef unsigned char a;
typedef unsigned short int b;
typedef unsigned int c;
typedef unsigned long int d;
typedef signed char e;
typedef unsigned char f;
typedef signed short int g;
typedef unsigned short int h;
typedef signed int i;
typedef long int o;
typedef float q;
typedef double r;
typedef unsigned int _t;
typedef _t t;

#endif
'

> typehdr_ll.h echo '
#ifndef _INC_TYPEHDR_LL_H_
#define _INC_TYPEHDR_LL_H_

/* long long may not be supported */
__extension__ typedef signed long long int j;
__extension__ typedef unsigned long long int k;

#endif
'

> typehdr_ld.h echo '
#ifndef _INC_TYPEHDR_LD_H_
#define _INC_TYPEHDR_LD_H_

/* long double may not be supported */
typedef long double s;

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

csiz=`egrep "^enum (: )?int ({ )?_csiz_char = " out.d | sed 's/.*= //;s/[ }]*;//'`
ssiz=`egrep "^enum (: )?int ({ )?_csiz_short = " out.d | sed 's/.*= //;s/[ }]*;//'`
isiz=`egrep "^enum (: )?int ({ )?_csiz_int = " out.d | sed 's/.*= //;s/[ }]*;//'`
lsiz=`egrep "^enum (: )?int ({ )?_csiz_long = " out.d | sed 's/.*= //;s/[ }]*;//'`
llsiz=`egrep "^enum (: )?int ({ )?_csiz_long_long = " out.d | sed 's/.*= //;s/[ }]*;//'`
fsiz=`egrep "^enum (: )?int ({ )?_csiz_float = " out.d | sed 's/.*= //;s/[ }]*;//'`
dsiz=`egrep "^enum (: )?int ({ )?_csiz_double = " out.d | sed 's/.*= //;s/[ }]*;//'`
ldsiz=`egrep "^enum (: )?int ({ )?_csiz_long_double = " out.d | sed 's/.*= //;s/[ }]*;//'`

for x in a e f; do
  chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${csiz}( })?;$"
done

for x in e; do
  chkoutd "^alias byte C_TYP_${x};$"
done

for x in a f; do
  chkoutd "^alias ubyte C_TYP_${x};$"
done

for x in b g h; do
  chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${ssiz}( })?;$"
done

for x in g; do
  chkoutd "^alias short C_TYP_${x};$"
done

for x in b h; do
  chkoutd "^alias ushort C_TYP_${x};$"
done

for x in c i t; do
  chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${isiz}( })?;$"
done

for x in i; do
  chkoutd "^alias int C_TYP_${x};$"
done

for x in c t; do
  chkoutd "^alias uint C_TYP_${x};$"
done

for x in d o; do
  chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${lsiz}( })?;$"
done

tt=int
if [ $lsiz -eq 8 ]; then
 tt=long
fi

for x in d; do
  chkoutd "^alias u${tt} C_TYP_${x};$"
done

for x in o; do
  chkoutd "^alias ${tt} C_TYP_${x};$"
done

if [ $llsiz -gt 0 ]; then
  for x in j k; do
    chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${llsiz}( })?;$"
  done

  for x in j; do
    chkoutd "^alias long C_TYP_${x};$"
  done

  for x in k; do
    chkoutd "^alias ulong C_TYP_${x};$"
  done
fi

for x in q; do
  chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${fsiz}( })?;$"
  chkoutd "^alias float C_TYP_${x};$"
done

for x in r; do
  chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${dsiz}( })?;$"
  chkoutd "^alias double C_TYP_${x};$"
done

if [ $ldsiz -gt 0 ]; then
  for x in s; do
    chkoutd "^enum (: )?int ({ )?_ctype_${x} = ${ldsiz}( })?;$"
    chkoutd "^alias real C_TYP_${x};$"
  done
fi

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
