#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 1994-2010 Brad Lanam, Walnut Creek, CA
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - $TSTRUNLOG
#    8 - $MAINLOG
#    3 - stdout (as 1 is directed to the log)
#

DOPERL=T
TESTORDER=test_order

_MKCONFIG_RUNTOPDIR=`pwd`
export _MKCONFIG_RUNTOPDIR
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
cd $mypath
_MKCONFIG_DIR=`pwd`
export _MKCONFIG_DIR
cd $_MKCONFIG_RUNTOPDIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

doshelltest $0 $@
setechovars
mkconfigversion

unset GREP_OPTIONS
unset DI_ARGS
unset DI_FMT
unset ENV
unalias sed > /dev/null 2>&1
unalias grep > /dev/null 2>&1
unalias ls > /dev/null 2>&1
unalias rm > /dev/null 2>&1
LC_ALL=C
export LC_ALL

testdir=$1
if [ ! -d $testdir ]; then
  echo "## Unable to locate $testdir"
  exit 1
fi

shift
teststorun=$*

CC=${CC:-cc}
export CC

cd $testdir
if [ $? != 0 ]; then
  echo "## Unable to cd to $testdir"
  exit 1
fi

_MKCONFIG_RUNTESTDIR=`pwd`
export _MKCONFIG_RUNTESTDIR
_MKCONFIG_RUNTMPDIR=$_MKCONFIG_RUNTOPDIR/_mkconfig_runtests
export _MKCONFIG_RUNTMPDIR

if [ "$teststorun" = "" ]; then
  if [ ! -f "$TESTORDER" ]; then
    teststorun=`ls -1d *.d *.sh 2>/dev/null | sed 's/\.sh$//'`
  else
    teststorun=`sort $TESTORDER | sed 's/.* //'`
  fi
fi

test -d "$_MKCONFIG_RUNTMPDIR" && rm -rf "$_MKCONFIG_RUNTMPDIR"
mkdir -p $_MKCONFIG_RUNTMPDIR

MAINLOG=${_MKCONFIG_RUNTMPDIR}/main.log
> $MAINLOG
exec 8>>$MAINLOG
getlistofshells >&8
export shelllist
count=0
fcount=0
for tbase in $teststorun; do
  if [ -d "$tbase" ]; then
    $0 $tbase
    continue
  fi

  tf="${tbase}.sh"
  tmkconfig="${tbase}.mkconfig"
  tconfig="${tbase}.config"
  tconfh="${tbase}.ctmp"

  ok=T
  if [ ! -f ./$tf ]; then
    echo "$tf ... missing ... failed"
    echo "$tf ... missing ... failed" >&8
    ok=F
  elif [ ! -x ./$tf ]; then
    echo "$tf ... permission denied ... failed"
    echo "$tf ... permission denied ... failed" >&8
    ok=F
  fi
  if [ $ok = F ]; then
    domath fcount "$fcount + 1"
    domath count "$count + 1"
    continue
  fi

  dt=`date`
  arg=""
  suffix=""
  if [ -f $tmkconfig ]; then
    arg="mkconfig.sh"
    suffix="_sh"
  fi

  _MKCONFIG_TSTRUNTMPDIR=$_MKCONFIG_RUNTMPDIR/${tbase}${suffix}
  export _MKCONFIG_TSTRUNTMPDIR
  mkdir -p ${_MKCONFIG_TSTRUNTMPDIR}

  TSTRUNLOG=${_MKCONFIG_TSTRUNTMPDIR}/${tbase}.log
  > $TSTRUNLOG
  exec 9>>$TSTRUNLOG

  echo "####" >&9
  echo "# Test: $tf $arg" >&9
  echo "# $dt" >&9
  echo "####" >&9
  grc=0
  echo ${EN} "$tf ... ${arg} ${EC}"
  echo ${EN} "$tf ... ${arg} ${EC}" >&8
  if [ -f $tconfig ]; then
    cp $tconfig $_MKCONFIG_TSTRUNTMPDIR/$tconfh
  fi
  if [ "$arg" != "" ]; then
    arg="$_MKCONFIG_DIR/$arg"
  fi

  cd $_MKCONFIG_TSTRUNTMPDIR
  $_MKCONFIG_RUNTESTDIR/$tf $arg 3>&1 >&9 2>&1
  rc=$?
  cd $_MKCONFIG_RUNTESTDIR

  dt=`date`
  echo "####" >&9
  echo "# $dt" >&9
  echo "# exit $rc" >&9
  echo "####" >&9
  exec 9>&-
  if [ $rc -ne 0 ]; then
    echo " ... failed"
    echo " failed" >&8
    domath fcount "$fcount + 1"
    grc=1
  else
    echo " ... success"
    echo " success" >&8
  fi
  domath count "$count + 1"

  if [ "$DOPERL" = "T" -a -f $tmkconfig ]; then
    _MKCONFIG_TSTRUNTMPDIR=$_MKCONFIG_RUNTMPDIR/${tbase}_pl
    export _MKCONFIG_TSTRUNTMPDIR
    mkdir -p ${_MKCONFIG_TSTRUNTMPDIR}
    TSTRUNLOG=$_MKCONFIG_TSTRUNTMPDIR/${tbase}.log
    > $TSTRUNLOG
    exec 9>>$TSTRUNLOG
    dt=`date`
    echo "####" >&9
    echo "# Test: $tf mkconfig.pl" >&9
    echo "# $dt" >&9
    echo "####" >&9
    echo ${EN} "$tf ... mkconfig.pl ${EC}"
    echo ${EN} "$tf ... mkconfig.pl ${EC}" >&8
    echo "## Using mkconfig.pl " >&9
    if [ -f $tconfig ]; then
      cp $tconfig $_MKCONFIG_TSTRUNTMPDIR/$tconfh
    fi

    cd $_MKCONFIG_TSTRUNTMPDIR
    $_MKCONFIG_RUNTESTDIR/$tf perl $_MKCONFIG_DIR/mkconfig.pl 3>&1 >&9 2>&1
    rc=$?
    cd $_MKCONFIG_RUNTESTDIR

    dt=`date`
    echo "####" >&9
    echo "# $dt" >&9
    echo "# exit $rc" >&9
    echo "####" >&9
    exec 9>&-
    if [ $rc -ne 0 ]; then
      echo " ... failed"
      echo " failed" >&8
      domath fcount "$fcount + 1"
    else
      echo " ... success"
      echo " success" >&8
    fi
    domath count "$count + 1"
  fi
done

exec 8>&-

if [ $count -eq 0 ]; then  # this can't be right...
  $fcount = -1
fi

echo "$count tests $fcount failures"
if [ $fcount -eq 0 ]; then
  if [ "$DI_KEEP_RUN_TMP" = "" ]; then
    test -d "$_MKCONFIG_RUNTMPDIR" && rm -rf "$_MKCONFIG_RUNTMPDIR"
  fi
fi
exit $fcount
