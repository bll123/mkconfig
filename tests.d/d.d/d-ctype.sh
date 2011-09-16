#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " c-type size${EC}"
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
    -C $_MKCONFIG_RUNTESTDIR/d-ctype.env.dat
. ./ctype.env

grc=0

CFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${CFLAGS}"
DFLAGS="-I${_MKCONFIG_TSTRUNTMPDIR} ${DFLAGS}"
LDFLAGS="-L${_MKCONFIG_TSTRUNTMPDIR} ${LDFLAGS}"
export CFLAGS DFLAGS LDFLAGS

cat > typehdr.h << _HERE_
#ifndef _INC_TYPEHDR_H_
#define _INC_TYPEHDR_H_

typedef unsigned char a;
typedef unsigned short int b;
typedef unsigned int c;
typedef unsigned long int d;
typedef signed char e;
typedef unsigned char f;
typedef signed short int g;
typedef unsigned short int h;
typedef signed int i;
typedef long int o;
typedef float q;
typedef double r;
typedef unsigned int _t;
typedef _t t;

#endif
_HERE_

cat > typehdr_ll.h << _HERE_
#ifndef _INC_TYPEHDR_LL_H_
#define _INC_TYPEHDR_LL_H_

/* long long may not be supported */
__extension__ typedef signed long long int j;
__extension__ typedef unsigned long long int k;

#endif
_HERE_

cat > typehdr_ld.h << _HERE_
#ifndef _INC_TYPEHDR_LD_H_
#define _INC_TYPEHDR_LD_H_

/* long double may not be supported */
typedef long double s;

#endif
_HERE_

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-ctype.dat
grc=0

csiz=`egrep "^enum (: )?int ({ )?_csiz_char = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
ssiz=`egrep "^enum (: )?int ({ )?_csiz_short = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
isiz=`egrep "^enum (: )?int ({ )?_csiz_int = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
lsiz=`egrep "^enum (: )?int ({ )?_csiz_long = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
llsiz=`egrep "^enum (: )?int ({ )?_csiz_long_long = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
fsiz=`egrep "^enum (: )?int ({ )?_csiz_float = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
dsiz=`egrep "^enum (: )?int ({ )?_csiz_double = " dctype.d | sed 's/.*= //;s/[ }]*;//'`
ldsiz=`egrep "^enum (: )?int ({ )?_csiz_long_double = " dctype.d | sed 's/.*= //;s/[ }]*;//'`

for x in a e f; do
  egrep -l ?"^enum (: )?int ({ )?_ctype_${x} = ${csiz}( })?;$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed enum chk"
    grc=1
  fi
done

for x in e; do
  egrep -l ?"^alias byte C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in a f; do
  egrep -l ?"^alias ubyte C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in b g h; do
  egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${ssiz}( })?;$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed enum chk"
    grc=1
  fi
done

for x in g; do
  egrep -l ?"^alias short C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in b h; do
  egrep -l ?"^alias ushort C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in c i t; do
  egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${isiz}( })?;$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed enum chk"
    grc=1
  fi
done

for x in i; do
  egrep -l ?"^alias int C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in c t; do
  egrep -l ?"^alias uint C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in d o; do
  egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${lsiz}( })?;$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed enum chk"
    grc=1
  fi
done

tt=int
if [ $lsiz -eq 8 ]; then
 tt=long
fi

for x in d; do
  egrep -l ?"^alias u${tt} C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in o; do
  egrep -l ?"^alias ${tt} C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

if [ $llsiz -gt 0 ]; then
  for x in j k; do
    egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${llsiz}( })?;$" dctype.d \
        > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## test $x failed enum chk"
      grc=1
    fi
  done

  for x in j; do
    egrep -l ?"^alias long C_TYP_${x};$" dctype.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## test $x failed alias chk"
      grc=1
    fi
  done

  for x in k; do
    egrep -l ?"^alias ulong C_TYP_${x};$" dctype.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## test $x failed alias chk"
      grc=1
    fi
  done
fi

for x in q; do
  egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${fsiz}( })?;$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed enum chk"
    grc=1
  fi
  egrep -l ?"^alias float C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

for x in r; do
  egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${dsiz}( })?;$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed enum chk"
    grc=1
  fi
  egrep -l ?"^alias double C_TYP_${x};$" dctype.d > /dev/null 2>&1
  rc=$?
  if [ $rc -ne 0 ]; then
    echo "## test $x failed alias chk"
    grc=1
  fi
done

if [ $ldsiz -gt 0 ]; then
  for x in s; do
    egrep -l "^enum (: )?int ({ )?_ctype_${x} = ${ldsiz}( })?;$" dctype.d \
        > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## test $x failed enum chk"
      grc=1
    fi
    egrep -l ?"^alias real C_TYP_${x};$" dctype.d > /dev/null 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
      echo "## test $x failed alias chk"
      grc=1
    fi
  done
fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dctype.d
  if [ $? -ne 0 ]; then
    echo "## compile dctype.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dctype.d dctype.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
