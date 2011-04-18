#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-define ${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no D compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d-cdefine.env.dat
. ./cdefine.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > cdefine.h << _HERE_
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
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cdefine.dat
grc=0

egrep -l "^enum (: )?bool ({ )?_cdefine_a = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: a"
fi

egrep -l "^enum (: )?int ({ )?a = 1( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: a enum"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_b = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: b"
fi

egrep -l "^enum (: )?int ({ )?b = 2( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: b enum"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_c = false( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: c"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_d = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: d"
fi

if [ "$DVERSION" = 1 ]; then
  egrep -l "^string d = \"d\"( })?;$" dcdefine.d > /dev/null 2>&1
  rc=$?
else
  egrep -l "^enum string d = \"d\";$" dcdefine.d > /dev/null 2>&1
  rc=$?
fi
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: d enum"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_e = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: e"
fi

if [ "$DVERSION" = 1 ]; then
  egrep -l "^string e = \"abc\"( })?;$" dcdefine.d > /dev/null 2>&1
  rc=$?
else
  egrep -l "^enum string e = \"abc\";$" dcdefine.d > /dev/null 2>&1
  rc=$?
fi
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: e enum"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_g = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: g"
fi

egrep -l "^enum (: )?int ({ )?g = 0xff( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: g enum"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_h = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: h"
fi

egrep -l "^enum (: )?int ({ )?h = 0x400( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: h enum"
fi

egrep -l "^enum (: )?bool ({ )?_cdefine_pi = true( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: pi"
fi

egrep -l "^enum (: )?double ({ )?pi = 3.14159( })?;$" dcdefine.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
  echo "## failed: pi enum"
fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dcdefine.d
  if [ $? -ne 0 ]; then
    echo "## compile dcdefine.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dcdefine.d dcdefine.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
