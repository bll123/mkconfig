#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'include conflict'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

> incconf1.h echo '

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif
extern int incconf1 ();
'
> incconf2.h echo '

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif
extern char *incconf1 ();
'
> incconf3.h echo '

#if defined(__STDC__) || defined(__cplusplus) || defined(c_plusplus)
# define _(x) x
#else
# define _(x) ()
# define void char
#endif
extern int incconf1 ();
'

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env

dorunmkc

chkouth "^#define _inc_conflict__hdr_incconf1__hdr_incconf2 0$"
chkouth "^#define _inc_conflict__hdr_incconf1__hdr_incconf3 1$"
chkouthcompile

testcleanup

exit $grc
