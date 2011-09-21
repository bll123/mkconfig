#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 c-typedef
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

cat > typedefhdr.h << _HERE_
#ifndef _INC_TYPEDEFHDR_H_
#define _INC_TYPEDEFHDR_H_

typedef unsigned char a;
typedef unsigned short int b;
typedef unsigned int c;
typedef unsigned long int d;
typedef signed char e;
typedef unsigned char f;
typedef signed short int g;
typedef unsigned short int h;
typedef signed int i;
#if __GNUC__
__extension__ typedef signed long long int j;
__extension__ typedef unsigned long long int k;
__extension__ typedef void * l;
#endif
typedef void *m;
struct ns { int n; };
typedef struct ns n;
typedef struct { int o; } o_t;
typedef o_t o;
typedef o p; // typedef of typedef

#endif
_HERE_

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

dorunmkc

if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
  for x in j k l; do
    chkoutd "^enum (: )?bool ({ )?_ctypedef_${x} = true( })?;$"
    chkoutd "alias.*[ \*]${x};$"
  done
fi

for x in a b c d e f g h i m n o p; do
  chkoutd "^enum (: )?bool ({ )?_ctypedef_${x} = true( })?;$"
  chkoutd "alias.*[ \*]${x};$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
