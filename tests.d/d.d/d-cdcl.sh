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
extern int a (__const char *__restrict __file,
      long *__restrict __buf)
     __attribute__ ((__nothrow__)) __attribute__ ((__nonnull__ (1, 2)));
int b (int);
extern int c (long);
extern int d (int, int, char *);
extern int e (char **, int *);
extern int f (int, char * const [], const char *);
extern char *g (const char *);
extern int h (__const char *__restrict __file,
  long *__restrict __buf) __asm__ ((__nothrow__)) __attribute__ ((__nonnull__ (1, 2)));
extern char *i (__const char *__domainname,
  __const char *__dirname) __THROW;
extern char *j (__const char *__domainname,
  __const char *__dirname) __THROW;
extern int k (int, int, char *);
extern int l (int, int);
extern int m (int);
extern int n (int, int, char *, int);

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-cdcl.dat
grc=0

for x in a b c d e f g h i j k l m n; do
  grep -l "^enum bool _cdcl_${x} = true;$" cdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

set 2 3 2 1 4
for x in j k l m n; do
  val=$1
  shift
  grep -l "^enum int _c_args_${x} = ${val};$" cdcl.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=1
  fi
done

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} cdcl.d
  if [ $? -ne 0 ]; then
    echo "compile cdcl.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv cdcl.d cdcl.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
