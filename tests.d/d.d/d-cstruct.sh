#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-struct extraction${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-cstruct.env.dat
. ./cstruct.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > tst3hdr.h << _HERE_
#ifndef _INC_TST3HDR_H_
#define _INC_TST3HDR_H_
struct a
{
  long double ld;
  double d;
  long long  ll;
  long long int  lli;
  unsigned long long  ull;
  unsigned long long int ulli;
  float f;
  long  l;
  unsigned long  ul;
  long int li;
  unsigned long int uli;
  int   i;
  unsigned int   ui;
  short s;
  short int si;
  unsigned short us;
  unsigned short int usi;
  char  c;
  unsigned char  uc;
  char  carr [20];
};

struct b
{
  long double  b;
};

typedef struct
{
  double  c;
} c_t;

typedef struct d
{
  float  d;
} d_t;

struct e
  {
  long long e;
  } ;

struct f {
  long f;
};

struct g {
// stuff
  int g;
};

struct h {
/* stuff */
  short h;
};

struct i {
  char i;
};

#endif

_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cstruct.dat
grc=0

grep -l "^enum bool _cstruct_a = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_b = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_c = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_d = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_e = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_f = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_g = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_h = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

grep -l "^enum bool _cstruct_i = true;$" cstruct.d > /dev/null 2>&1
rc=$?
if [ $rc -ne 0 ]; then
  grc=1
fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} cstruct.d
  if [ $? -ne 0 ]; then
    echo "compile cstruct.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv cstruct.d cstruct.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
