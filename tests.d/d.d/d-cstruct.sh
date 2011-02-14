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

cat > cstructhdr.h << _HERE_
#ifndef _INC_cstructhdr_H_
#define _INC_cstructhdr_H_
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

struct b
{
  long double  b;
  float b1;
  double  b2;
  long double  b3;
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

struct j { int j; };

typedef struct k { int k; } k_t;

typedef struct { int l; } l_t;

struct m {
 int m;
 union {
   int a;
   long b;
 };
} m_t;

struct { int n; union { int a; long b; }; int n2; } n_t;

/* forward dcl */
struct o;

struct o {
  int o;
};

/* forward dcl */
struct p;

/* forward dcl */
struct q;

struct q {
  int q;
  struct q *qq;
};

/* named union */
struct r {
 int r;
 union {
   int a;
   long b;
 } r_named ;
} r_t;

/* named struct */
struct s {
 int s;
 struct {
   int a;
   long b;
 } s_named ;
} s_t;

/* doesn't work...(extraction fails)
typedef struct
{
  double  c;
} t;
*/

typedef struct u
{
  double  c;
} u;

union ua
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

union ub
{
  long double  b;
  float b1;
  double  b2;
  long double  b3;
};

typedef union
{
  double  c;
} uc_t;

typedef union ud
{
  float  d;
} ud_t;

union ue
  {
  long long e;
  } ;

union uf {
  long f;
};

union ug {
// stuff
  int g;
};

union uh {
/* stuff */
  short h;
};

union ui {
  char i;
};

union uj { int j; };

typedef union uk { int k; } uk_t;

typedef union { int l; } ul_t;

union um {
 int m;
 union {
   int a;
   long b;
 };
} um_t;

union { int n; union { int a; long b; }; int n2; } un_t;

/* forward dcl */
union uo;

union uo {
  int o;
};

/* forward dcl */
union up;

/* forward dcl */
union uq;

union uq {
  int q;
  union uq *qq;
};

/* named union */
union ur {
 int r;
 union {
   int a;
   long b;
 } ur_named ;
} ur_t;

/* named struct */
union us {
 int s;
 struct {
   int a;
   long b;
 } us_named ;
} us_t;

/* doesn't work...(extraction fails)
typedef union
{
  double  c;
} ut;
*/

typedef union uu
{
  double  c;
} uu;

#endif

_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cstruct.dat
grc=0

for x in a b c d e f g h i j k l m n o q r s u; do
  egrep -l "^enum (: )?bool ({ )?_cstruct_${x} = true( })?;$" cstruct.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in p; do
  egrep -l "^enum (: )?bool ({ )?_cstruct_${x} = false( })?;$" cstruct.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in ua ub uc ud ue uf ug uh ui uj uk ul um un uo uq ur us uu; do
  egrep -l "^enum (: )?bool ({ )?_cunion_${x} = true( })?;$" cstruct.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

for x in up; do
  egrep -l "^enum (: )?bool ({ )?_cunion_${x} = false( })?;$" cstruct.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

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
