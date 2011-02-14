#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-typeconv size${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-ctypeconv.env.dat
. ./ctypeconv.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > typeconvhdr.h << _HERE_
#ifndef _INC_TYPECONVHDR_H_
#define _INC_TYPECONVHDR_H_

typedef unsigned char a;
typedef unsigned short int b;
typedef unsigned int c;
typedef unsigned long int d;
typedef signed char e;
typedef unsigned char f;
typedef signed short int g;
typedef unsigned short int h;
typedef signed int i;
/* __extension__ typedef struct { int __val[2]; } l; */
__extension__ typedef void * m;
/* typedef struct { int n; } n_t; */
typedef void *o;
/* typedef int (*p)(); */
typedef float q;
typedef double r;

#endif
_HERE_

cat > typeconvhdr_ll.h << _HERE_
#ifndef _INC_TYPECONVHDR_LL_H_
#define _INC_TYPECONVHDR_LL_H_

/* long long may not be supported */
__extension__ typedef signed long long int j;
__extension__ typedef unsigned long long int k;

#endif
_HERE_

cat > typeconvhdr_ld.h << _HERE_
#ifndef _INC_TYPECONVHDR_LD_H_
#define _INC_TYPECONVHDR_LD_H_

/* long double may not be supported */
typedef long double s;

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-ctypeconv.dat
grc=0

csiz=`grep "^enum int _csiz_char = " ctypeconv.d | sed 's/.*= //;s/;//'`
ssiz=`grep "^enum int _csiz_short = " ctypeconv.d | sed 's/.*= //;s/;//'`
isiz=`grep "^enum int _csiz_int = " ctypeconv.d | sed 's/.*= //;s/;//'`
lsiz=`grep "^enum int _csiz_long = " ctypeconv.d | sed 's/.*= //;s/;//'`
llsiz=`grep "^enum int _csiz_long_long = " ctypeconv.d | sed 's/.*= //;s/;//'`
fsiz=`grep "^enum int _csiz_float = " ctypeconv.d | sed 's/.*= //;s/;//'`
dsiz=`grep "^enum int _csiz_double = " ctypeconv.d | sed 's/.*= //;s/;//'`
ldsiz=`grep "^enum int _csiz_long_double = " ctypeconv.d | sed 's/.*= //;s/;//'`

for x in a e f; do
  grep -l "^enum int _ctypeconv_${x} = ${csiz};$" ctypeconv.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in b g h; do
  grep -l "^enum int _ctypeconv_${x} = ${ssiz};$" ctypeconv.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in c i m o; do
  grep -l "^enum int _ctypeconv_${x} = ${isiz};$" ctypeconv.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in d; do
  grep -l "^enum int _ctypeconv_${x} = ${lsiz};$" ctypeconv.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

if [ $llsiz -gt 0 ]; then
  for x in j k; do
    grep -l "^enum int _ctypeconv_${x} = ${llsiz};$" ctypeconv.d \
        > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      grc=1
    fi
  done
fi

for x in q; do
  grep -l "^enum int _ctypeconv_${x} = ${fsiz};$" ctypeconv.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in r; do
  grep -l "^enum int _ctypeconv_${x} = ${dsiz};$" ctypeconv.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

if [ $ldsiz -gt 0 ]; then
  for x in s; do
    grep -l "^enum int _ctypeconv_${x} = ${ldsiz};$" ctypeconv.d \
        > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      grc=1
    fi
  done
fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} ctypeconv.d
  if [ $? -ne 0 ]; then
    echo "compile ctypeconv.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv ctypeconv.d ctypeconv.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
