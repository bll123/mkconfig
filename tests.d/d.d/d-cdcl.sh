#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'c-dcl extraction'
maindoquery $1 $_MKC_SH

chkdcompiler
getsname $0
dosetup $@

> cdclhdr.h echo '
#ifndef _INC_cdclhdr_H_
#define _INC_cdclhdr_H_

/* modified from linux sys/statvfs.h */
#if __GNUC__
extern int a (__const char *__restrict __file,
      long *__restrict __buf)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1, 2)));
#endif
int b (int);
extern int c (long);
extern int d (int, int, char *);
extern int e (char **, int *);
extern int f (int, char * const [], const char *);
extern char *g (const char *);
#if __GNUC__
extern int h (__const char *__restrict __file,
  long *__restrict __buf) __attribute__ ((__nothrow__))
  __attribute__ ((__nonnull__ (1, 2)));
extern char *i (__const char *__domainname,
  __const char *__dirname);
extern char *j (__const char *__domainname,
  __const char *__dirname);
#endif
extern int k (int, int, char *);
extern int l (int, int);
extern int m (int);
extern int n (int, int, char *, int);
#if __GNUC__
extern int o (int, int, char *, int) __asm__ ("" "o64");
#endif

/* w/var names */
extern char *p (int a, int b, char *c, int d);
/* w/var names and lots of spaces */
extern int q ( int a , int b , char  * c , int d );
/* w/no var names and lots of spaces */
extern  int  r ( int ,  int , char  * , int );
/* struct names */
struct x_t { int a; };
union y_t { int a; int b; };
extern  int  s ( struct x_t x , union  y_t  y , char  * , int );

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

lsiz=`egrep "^enum (: )?int ({ )?_csiz_long = " out.d |
    sed 's/.*= //;s/[ }]*;//'`

if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
  for x in a h i j o; do
    chkoutd "^enum (: )?bool ({ )?_cdcl_${x} = true( })?;$"
  done

  set 2 2 2 2 4
  for x in a h i j o; do
    val=$1
    shift
    chkoutd "^enum (: )?int ({ )?_c_args_${x} = ${val}( })?;$"
  done

  for x in o64; do
    xx=`echo $x | sed 's/64$//'`
    chkoutd "^alias ${x} ${xx};$"
  done

  set 1 2 4
  for x in o o o; do
    val=$1
    shift
    chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"int\";$"
  done

  # char * check
  set 1 1 1 2 1 2 3
  for x in a h i i j j o; do
    val=$1
    shift
    set -f
    chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"char \*\";$"
  done

  tt=int
  if [ $lsiz -eq 8 ]; then
    tt=long
  fi

  # long * check
  set 2 2
  for x in a h; do
    val=$1
    shift
    chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"${tt} \*\";$"
  done

  # int type check
  for x in a h o; do
    chkoutd "^(enum (: )?)?string _c_type_${x} = \"int\";$"
  done

  # char * type check
  for x in i j; do
    chkoutd "^(enum (: )?)?string _c_type_${x} = \"char \*\";$"
  done
fi

for x in b c d e f g k l m n p q r s; do
  chkoutd "^enum (: )?bool ({ )?_cdcl_${x} = true( })?;$"
done


# arguments
set 1 1 3 2 3 1 3 2 1 4 4 4 4 4
for x in b c d e f g k l m n p q r s; do
  val=$1
  shift
  chkoutd "^enum (: )?int ({ )?_c_args_${x} = ${val}( })?;$"
done

# int check
set 1 1 2 1 1 2 1 2 1 1 2 4 1 2 4 1 2 4 1 2 4 4
for x in b d d f k k l l m n n n p p p q q q r r r s; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"int\";$"
done

# long check
set 1
for x in c; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"long\";$"
done

# 'char *' check
set 3 3 1 3 3 3 3 3 3
for x in d f g k n p q r s; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"char \*\";$"
done

# 'char **' check
set 1
for x in e; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"char \*\*\";$"
done

# 'char * []' check
set 2
for x in f; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"char \* \[\]\";$"
done

# 'C_ST_x_t' check
set 1
for x in s; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"C_ST_x_t\";$"
done

# 'C_UN_y_t' check
set 2
for x in s; do
  val=$1
  shift
  chkoutd "^(enum (: )?)?string _c_arg_${val}_${x} = \"C_UN_y_t\";$"
done

# int type check
for x in b c d e k l m n q r s; do
  chkoutd "^(enum (: )?)?string _c_type_${x} = \"int\";$"
done

# char * type check
for x in g p; do
  chkoutd "^(enum (: )?)?string _c_type_${x} = \"char \*\";$"
done

if [ $grc -eq 0 ]; then
  chkdcompile out.d
fi

testcleanup

exit $grc
