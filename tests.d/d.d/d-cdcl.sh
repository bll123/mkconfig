#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-dcl extraction${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-cdcl.env.dat
. ./cdcl.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > cdclhdr.h << _HERE_
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
  __const char *__dirname) __THROW;
extern char *j (__const char *__domainname,
  __const char *__dirname) __THROW;
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
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cdcl.dat
grc=0

if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
  for x in a h i j o; do
    egrep -l "^enum (: )?bool ({ )?_cdcl_${x} = true( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for enum _cdcl_${x} failed (gcc)"
      grc=1
    fi
  done

  set 2 2 2 2 4
  for x in a h i j o; do
    val=$1
    shift
    egrep -l "^enum (: )?int ({ )?_c_args_${x} = ${val}( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for enum _c_args_${x} failed"
      grc=1
    fi
  done

  for x in o64; do
    xx=`echo $x | sed 's/64$//'`
    egrep -l "^alias ${x} ${xx};$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for alias ${x} ${xx} failed (gcc)"
      grc=1
    fi
  done

  set 1 2 4
  for x in o o o; do
    val=$1
    shift
    egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"int\"( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for enum _c_args_${x} failed"
      grc=1
    fi
  done

  # char * check
  set 1 1 1 2 1 2 3
  for x in a h i i j j o; do
    val=$1
    shift
    set -f
    egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"char \*\"( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    set +f
    if [ $rc -ne 0 ]; then
      echo "## check for _c_arg_${val}_${x} char * failed (gcc)"
      grc=1
    fi
  done

  # long * check
  set 2 2
  for x in a h; do
    val=$1
    shift
    set -f
    egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"long \*\"( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for _c_arg_${val}_${x} long * failed (gcc)"
      grc=1
    fi
    set +f
  done

  # int type check
  for x in a h o; do
    set -f
    egrep -l "^enum (: )?string ({ )?_c_type_${x} = \"int\"( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for _c_type_${x} int failed (gcc)"
      grc=1
    fi
    set +f
  done

  # char * type check
  for x in i j; do
    set -f
    egrep -l "^enum (: )?string ({ )?_c_type_${x} = \"char \*\"( })?;$" dcdcl.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for _c_type_${x} char * failed (gcc)"
      grc=1
    fi
    set +f
  done
fi

for x in b c d e f g k l m n p q r s; do
  egrep -l "^enum (: )?bool ({ )?_cdcl_${x} = true( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for enum _cdcl_${x} failed"
    grc=1
  fi
done


# arguments
set 1 1 3 2 3 1 3 2 1 4 4 4 4 4
for x in b c d e f g k l m n p q r s; do
  val=$1
  shift
  egrep -l "^enum (: )?int ({ )?_c_args_${x} = ${val}( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for enum _c_args_${x} failed"
    grc=1
  fi
done

# int check
set 1 1 2 1 1 2 1 2 1 1 2 4 1 2 4 1 2 4 1 2 4 4
for x in b d d f k k l l m n n n p p p q q q r r r s; do
  val=$1
  shift
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"int\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} int failed"
    grc=1
  fi
done

# long check
set 1
for x in c; do
  val=$1
  shift
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"long\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} long failed"
    grc=1
  fi
done

# 'char *' check
set 3 3 1 3 3 3 3 3 3
for x in d f g k n p q r s; do
  val=$1
  shift
  set -f
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"char \*\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} char * failed"
    grc=1
  fi
  set +f
done

# 'char **' check
set 1
for x in e; do
  val=$1
  shift
  set -f
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"char \*\*\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} char ** failed"
    grc=1
  fi
  set +f
done

# 'char * []' check
set 2
for x in f; do
  val=$1
  shift
  set -f
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"char \* \[\]\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} char * [] failed"
    grc=1
  fi
  set +f
done

# 'C_ST_x_t' check
set 1
for x in s; do
  val=$1
  shift
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"C_ST_x_t\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} C_ST_x_t failed"
    grc=1
  fi
done

# 'C_UN_y_t' check
set 2
for x in s; do
  val=$1
  shift
  egrep -l "^enum (: )?string ({ )?_c_arg_${val}_${x} = \"C_UN_y_t\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} C_UN_y_t failed"
    grc=1
  fi
done

# int type check
for x in b c d e k l m n q r s; do
  egrep -l "^enum (: )?string ({ )?_c_type_${x} = \"int\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_type_${x} int failed"
    grc=1
  fi
done

# char * type check
for x in g p; do
  set -f
  egrep -l "^enum (: )?string ({ )?_c_type_${x} = \"char \*\"( })?;$" dcdcl.d > /dev/null 2>&1
  rc=$?
  set +f
  if [ $rc -ne 0 ]; then
    echo "## check for _c_type_${x} char * failed"
    grc=1
  fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dcdcl.d
  if [ $? -ne 0 ]; then
    echo "## compile dcdcl.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dcdcl.d dcdcl.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
