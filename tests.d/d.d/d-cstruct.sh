#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'c-struct extraction'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> cstructhdr.h echo '
#ifndef _INC_cstructhdr_H_
#define _INC_cstructhdr_H_
struct sa
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

struct sb
{
  long double  b;
  float b1;
  double  b2;
  long double  b3;
};

typedef struct
{
  double  c;
} sc_t;

typedef struct sd
{
  float  d;
} sd_t;

struct se
  {
  long long e;
  } ;

struct sf {
  long f;
};

/* this is here to confuse the extractor */
enum xdr_op {
   A = 1,
   B = 2,
   C = 3
};
extern void xdrmem_create(int *, const int, const int, const enum
xdr_op);

struct sg {
// stuff
  int g;
};

struct sh {
/* stuff */
  short h;
};

struct si {
  char i;
};

struct sj { int j; };

typedef struct sk { int k; } sk_t;

typedef struct { int l; } sl_t;

struct sm {
 int m;
 union {
   int a;
   long b;
 };
} m_t;

struct { int n; union { int a; long b; }; int n2; } sn_t;

/* forward dcl */
struct so;

struct so {
  int o;
};

/* forward dcl */
struct sp;

/* forward dcl */
struct sq;

struct sq {
  int q;
  struct sq *qq;
};

/* named union */
struct sr {
 int r;
 union {
   int a;
   long b;
 } sr_named ;
} sr_t;

/* named struct */
struct ss {
 int s;
 struct {
   int a;
   long b;
 } ss_named ;
} ss_t;

typedef struct st
{
  double  t;
} st_t;

typedef struct
{
  double  u;
} su_t;

typedef struct sv
{
  double  c;
} sv;

/* anonymous struct */
struct sw
{
  double  c;
  struct sww {
    double d;
  } sw2;
};

/* named struct */
struct sx
{
  double  c;
  struct sxx {
    double d;
  } _sxx;
};

/* pointer to struct */
struct sy
{
  double  c;
  struct syy {
    double d;
  } * _syy;
};

/* pointer to struct B */
struct sz
{
  double  c;
  struct szz {
    double d;
  }
  * _szz;
};

/* named struct B  */
struct saa
{
  double  c;
  struct saaa {
    double d;
  }
  _saaa;
};

/* typedef named struct - from freebsd rpc/xdr.h (XDR) */
typedef struct sbb {
  int     op;
  const struct __rpc_xdr {
    int (*x_getlong)(struct __rpc_xdr *, long *);
    int (*x_putlong)(struct __rpc_xdr *, const long *);
    void (*x_destroy)(struct __rpc_xdr *);
  } *x_ops;
  void *x_private;
  char *x_base;
  int   x_handy;
} tXDR;

/* typedef named struct - from freebsd rpc/xdr.h (XDR) */
typedef struct _tscc {
  int     op;
  const struct tscc {
    int (*x_getlong)(struct tscc *, long *);
    int *(*x_inline)(struct tscc *, int);
    void (*x_destroy)(struct tscc *);
  } *x_ops;
  void *x_private;
  char *x_base;
  int   x_handy;
} scc;

/* modified from rpc/clnt.h: CLIENT */
struct sdd {
  long      *cl_auth;
  struct clnt_ops {
    enum xdr_op (*cl_call) (struct sdd *, long, int, char *, int, char *, int);
    void (*cl_abort) (void);
    void (*cl_geterr) (struct sdd *, int *);
    int (*cl_freeres) (struct sdd *, long, char *);
  } *cl_ops;
  char *cl_private;
};

/* uses struct name in functions */
typedef struct see {
  int     op;
  struct see *next;
  struct seestuff {
    int (*x_getlong)(struct see *, long *);
    int (*x_putlong)(struct see *, const long *);
    void (*x_destroy)(struct see *);
  } *see_stuff;
  void *morestuff;
} SEE;

/* uses struct name in functions */
typedef struct __sff {
  int     op;
  struct __sff *next;
  struct sffstuff {
    int (*x_getlong)(struct __sff *, long *);
    int (*x_putlong)(struct __sff *, const long *);
    void (*x_destroy)(struct __sff *);
  } *sff_stuff;
  void *moreffstuff;
} SFF;

/* typedef of struct; same name */
typedef struct sgg
{
  double  c;
  struct sgg1 {
    double d;
  } _sgg1;
} sgg;

/* typedef of struct; diff name; use struct name */
typedef struct shh
{
  double  c;
  struct shh1 {
    double d;
  } _shh1;
} shh_t;

/* typedef of struct; diff name; use typedef name */
typedef struct sii_s
{
  double  c;
  struct sii1 {
    double d;
  } _sii1;
} sii;

/* non-typedef same name */
struct sjj
{
  double  c;
  struct sjj1 {
    double d;
  } _sjj1;
} sjj;

struct skk { struct SKKB { int skka; } *skkb; };

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

typedef union
{
  double  c;
} ut;

typedef union uu
{
  double  c;
} uu;

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

for x in sa sb sc sd se sf sg sh si sj sk sl sm sn so sq sr \
    ss st su sv sw sx sy sz saa sbb scc sdd see SFF sgg \
    shh sii sjj ; do
  chkoutd "^enum (: )?bool ({ )?_cstruct_${x} = true( })?;$"
done

for x in sp; do
  chkoutd "^enum (: )?bool ({ )?_cstruct_${x} = false( })?;$"
done

for x in ua ub uc ud ue uf ug uh ui uj uk ul um un uo uq ur us ut uu; do
  chkoutd "^enum (: )?bool ({ )?_cunion_${x} = true( })?;$"
done

for x in up; do
  chkoutd "^enum (: )?bool ({ )?_cunion_${x} = false( })?;$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
