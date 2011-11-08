#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'c-define'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> cdefine.h echo '
#ifndef _INC_CDEFINE_H_
#define _INC_CDEFINE_H_

#define a 1
#define b 2

#define d "d"
#define e "abc"

#define g 255
#define h 1024

#define pi 3.14159

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

chkoutd "^enum (: )?bool ({ )?_cdefine_a = true( })?;$"
chkoutd "^enum (: )?int ({ )?a = 1( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_b = true( })?;$"
chkoutd "^enum (: )?int ({ )?b = 2( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_c = false( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_d = true( })?;$"
chkoutd "^(enum )?string d = \"d\"( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_e = true( })?;$"
chkoutd "^(enum )?string e = \"abc\"( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_g = true( })?;$"
chkoutd "^enum (: )?int ({ )?g = 0xff( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_h = true( })?;$"
chkoutd "^enum (: )?int ({ )?h = 0x400( })?;$"
chkoutd "^enum (: )?bool ({ )?_cdefine_pi = true( })?;$"
if [ "$DVERSION" = 1 ]; then
  chkoutd "^double pi = 3.14159;$"
else
  chkoutd "^enum (: )?double ({ )?pi = 3.14159( })?;$"
fi

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
