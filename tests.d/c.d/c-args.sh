#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " arguments${EC}"
  exit 0
fi

if [ "${CC}" = "" ]; then
  echo ${EN} " no C compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS LDFLAGS

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/c.env.dat
. ./c.env
grc=0

cat > cargshdr.h << _HERE_
#ifndef _INC_cargshdr_H_
#define _INC_cargshdr_H_

/* modified from linux sys/statvfs.h */
# if __GNUC__
#  define __THROW
extern int a (__const char *__restrict __file,
      long *__restrict __buf)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1, 2)));
# endif
int b (int);
extern int c (long);
extern int d (int, int, char *);
extern int e (char **, int *);
extern int f (int, char * const [], const char *);
extern char *g (const char *);
# if __GNUC__
extern int h (__const char *__restrict __file,
  long *__restrict __buf) __attribute__ ((__nothrow__))
  __attribute__ ((__nonnull__ (1, 2)));
extern char *i (__const char *__domainname,
  __const char *__dirname) __THROW;
extern char *j (__const char *__domainname,
  __const char *__dirname) __THROW;
# endif
extern int k (int, int, char *);
extern int l (int, int);
extern int m (int);
extern int n (int, int, char *, int);
# if __GNUC__
extern int o (int, int, char *, int) __asm__ ("" "o");
# endif

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

case ${script} in
  *mkconfig.sh)
    ${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/c-args.dat
    ;;
  *)
    perl ${script} -C ${_MKCONFIG_RUNTESTDIR}/c-args.dat
    ;;
esac

grc=0

if [ "${_MKCONFIG_USING_GCC}" = "Y" ]; then
  set 2 2 2 2 4
  for x in a h i j o; do
    val=$1
    shift
    egrep -l "^#define _args_${x} ${val}$" cargs.h > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for _args_${x} failed (gcc)"
      grc=1
    fi
  done

  # int check
  set 1 2 4
  for x in o o o; do
    val=$1
    shift
    egrep -l "^#define _c_arg_${val}_${x} int$" cargs.h > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for _c_arg_${val}_${x} int failed (gcc)"
      grc=1
    fi
  done

  # char * check
  set 1 1 1 2 1 2 3
  for x in a h i i j j o; do
    val=$1
    shift
    set -f
    egrep -l "^#define _c_arg_${val}_${x} char \*$" cargs.h > /dev/null 2>&1
    rc=$?
    set +f
    if [ $rc -ne 0 ]; then
      set -f
      echo "## check for _c_arg_${val}_${x} char * failed (gcc)"
      set +f
      grc=1
    fi
  done

  # long * check
  set 2 2
  for x in a h; do
    val=$1
    shift
    set -f
    egrep -l "^#define _c_arg_${val}_${x} long \*$" cargs.h > /dev/null 2>&1
    rc=$?
    set +f
    if [ $rc -ne 0 ]; then
      set -f
      echo "## check for _c_arg_${val}_${x} long * failed (gcc)"
      set +f
      grc=1
    fi
  done

  # int type check
  for x in a h o; do
    egrep -l "^#define _c_type_${x} int$" cargs.h > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## check for _c_type_${x} int failed (gcc)"
      grc=1
    fi
  done

  # char * type check
  for x in i j; do
    set -f
    egrep -l "^#define _c_type_${x} char \*$" cargs.h > /dev/null 2>&1
    rc=$?
    set +f
    if [ $rc -ne 0 ]; then
      set -f
      echo "## check for _c_type_${x} char * failed (gcc)"
      set +f
      grc=1
    fi
  done
fi

# arguments
set 1 1 3 2 3 1 3 2 1 4 4 4 4 4
for x in b c d e f g k l m n p q r s; do
  val=$1
  shift
  egrep -l "^#define _args_${x} ${val}$" cargs.h > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _args_${x} failed"
    grc=1
  fi
done

# int check
set 1 1 2 1 1 2 1 2 1 1 2 4 1 2 4 1 2 4 1 2 4 4
for x in b d d f k k l l m n n n p p p q q q r r r s; do
  val=$1
  shift
  egrep -l "^#define _c_arg_${val}_${x} int$" cargs.h > /dev/null 2>&1
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
  egrep -l "^#define _c_arg_${val}_${x} long$" cargs.h > /dev/null 2>&1
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
  egrep -l "^#define _c_arg_${val}_${x} char \*$" cargs.h > /dev/null 2>&1
  rc=$?
  set +f
  if [ $rc -ne 0 ]; then
    set -f
    echo "## check for _c_arg_${val}_${x} char * failed"
    set +f
    grc=1
  fi
done

# 'char **' check
set 1
for x in e; do
  val=$1
  shift
  set -f
  egrep -l "^#define _c_arg_${val}_${x} char \*\*$" cargs.h > /dev/null 2>&1
  rc=$?
  set +f
  if [ $rc -ne 0 ]; then
    set -f
    echo "## check for _c_arg_${val}_${x} char ** failed"
    set +f
    grc=1
  fi
done

# 'char * []' check
set 2
for x in f; do
  val=$1
  shift
  set -f
  egrep -l "^#define _c_arg_${val}_${x} char \* \[\]$" cargs.h > /dev/null 2>&1
  rc=$?
  set +f
  if [ $rc -ne 0 ]; then
    set -f
    echo "## check for _c_arg_${val}_${x} char * [] failed"
    set +f
    grc=1
  fi
done

# 'struct x_t' check
set 1
for x in s; do
  val=$1
  shift
  egrep -l "^#define _c_arg_${val}_${x} struct x_t$" cargs.h > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} struct x_t failed"
    grc=1
  fi
done

# 'union y_t' check
set 2
for x in s; do
  val=$1
  shift
  egrep -l "^#define _c_arg_${val}_${x} union y_t$" cargs.h > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_arg_${val}_${x} union y_t failed"
    grc=1
  fi
done

# int type check
for x in b c d e k l m n q r s; do
  egrep -l "^#define _c_type_${x} int$" cargs.h > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## check for _c_type_${x} int failed"
    grc=1
  fi
done

# char * type check
for x in g p; do
  set -f
  egrep -l "^#define _c_type_${x} char \*$" cargs.h > /dev/null 2>&1
  rc=$?
  set +f
  if [ $rc -ne 0 ]; then
    echo "## check for _c_type_${x} char * failed"
    grc=1
  fi
done

if [ $grc -eq 0 ]; then
  cat > cargs.c << _HERE_
#include <stdio.h>
#include <cargs.h>
int main (int argc, char *argv []) { return 0; }
_HERE_
  ${CC} -c ${CFLAGS} cargs.c
  if [ $? -ne 0 ]; then
    echo "## compile cargs.h failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv cargs.c cargs.c${stag}
  mv cargs.h cargs.h${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_c.vars mkconfig_c.vars${stag}
fi

exit $grc
