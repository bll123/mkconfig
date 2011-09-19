#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-typedef ${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

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

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-ctypedef.dat
grc=0

if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
  for x in j k l; do
    egrep -l "^enum (: )?bool ({ )?_ctypedef_${x} = true( })?;$" dctypedef.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for enum ${x} failed"
      grc=1
    fi
    grep -l "alias.*[ \*]${x};$" dctypedef.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for alias ${x} failed (gcc)"
      grc=1
    fi
  done
fi

for x in a b c d e f g h i m n o p; do
  egrep -l "^enum (: )?bool ({ )?_ctypedef_${x} = true( })?;$" dctypedef.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for enum ${x} failed"
    grc=1
  fi
  grep -l "alias.*[ \*]${x};$" dctypedef.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for alias ${x} failed"
    grc=1
  fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dctypedef.d
  if [ $? -ne 0 ]; then
    echo "## compile dctypedef.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dctypedef.d dctypedef.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
