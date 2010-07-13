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
#    7 - $TMPORDER
#    5 - stdout (as 1 is directed to the log)
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

runshelltest () {
  stag=""
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    stag=".${scount}_${shell}"
  fi
  TSTRUNLOG=${_MKCONFIG_TSTRUNTMPDIR}/${tbase}.log${stag}
  > $TSTRUNLOG
  exec 9>>$TSTRUNLOG

  echo "####" >&9
  echo "# Test: $tbase $arg" >&9
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    echo "## testing with ${_MKCONFIG_SHELL} " >&9
  fi
  echo "# $dt" >&9
  echo "####" >&9

  cd $_MKCONFIG_TSTRUNTMPDIR
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    echo ${EN} " ${ss}${EC}"
  fi
  targ=$arg
  if [ "$arg" != "" ]; then
    targ="$_MKCONFIG_DIR/$arg"
  fi
  # dup stdout to 5; redirect stdout to 9; redirect stderr to new 1.
  ${_MKCONFIG_SHELL} $_MKCONFIG_RUNTESTDIR/$tf $targ 5>&1 >&9 2>&1
  rc=$?
  cd $_MKCONFIG_RUNTESTDIR

  dt=`date`
  echo "####" >&9
  echo "# $dt" >&9
  echo "# exit $rc" >&9
  echo "####" >&9
  exec 9>&-
  if [ $rc -ne 0 -a "$_MKCONFIG_SHELL" != "" ]; then
    echo ${EN} "*${EC}"
  fi
  return $rc
}

_MKCONFIG_RUNTESTDIR=`pwd`
export _MKCONFIG_RUNTESTDIR
_MKCONFIG_RUNTMPDIR=$_MKCONFIG_RUNTOPDIR/_mkconfig_runtests
export _MKCONFIG_RUNTMPDIR

TMPORDER=test_order.tmp
if [ "$teststorun" = "" ]; then
  if [ ! -f "$TESTORDER" ]; then
    ls -1d *.d *.sh 2>/dev/null | sed -e 's/\.sh$//' -e 's/^/1 ' > $TMPORDER
  else
    sort $TESTORDER > $TMPORDER
  fi
else
  for t in $teststorun; do
    echo "1 $t"
  done > $TMPORDER
fi

test -d "$_MKCONFIG_RUNTMPDIR" && rm -rf "$_MKCONFIG_RUNTMPDIR"
mkdir $_MKCONFIG_RUNTMPDIR

MAINLOG=${_MKCONFIG_RUNTMPDIR}/main.log
> $MAINLOG
exec 8>>$MAINLOG
echo "## locating valid shells"
echo ${EN} "   ${EC}"
getlistofshells 5>&1 >&8 2>&1
echo ""
export shelllist
grc=0
count=0
fcount=0
lastpass=""
# save stdin in fd 7
exec 7<&0 < ${TMPORDER}
while read tline; do
  set $tline
  pass=$1
  tbase=$2
  if [ "$lastpass" = "" ]; then
    lastpass=$pass
  fi
  if [ $grc -ne 0 -a "$lastpass" != "$pass" ]; then
    echo "## stopping tests due to failures in pass $lastpass"
    echo "## stopping tests due to failures in pass $lastpass" >&8
    break
  fi

  if [ -d "$tbase" ]; then
    $0 $tbase
    continue
  fi

  tf="${tbase}.sh"
  tconfig="${tbase}.config"
  tconfh="${tbase}.ctmp"

  ok=T
  if [ ! -f ./$tf ]; then
    echo "$tbase ... missing ... failed"
    echo "$tbase ... missing ... failed" >&8
    ok=F
  elif [ ! -x ./$tf ]; then
    echo "$tbase ... permission denied ... failed"
    echo "$tbase ... permission denied ... failed" >&8
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
  if [ -f ${tbase}.mksh -o -f ${tbase}.mkshpl ]; then
    arg="mkconfig.sh"
    suffix="_sh"
  fi

  scount=""
  echo ${EN} "$tbase ...${EC}"
  echo ${EN} "$tbase ...${EC}" >&8
  _MKCONFIG_TSTRUNTMPDIR=$_MKCONFIG_RUNTMPDIR/${tbase}${suffix}
  export _MKCONFIG_TSTRUNTMPDIR
  mkdir ${_MKCONFIG_TSTRUNTMPDIR}
  if [ -f $tconfig ]; then
    cp $tconfig $_MKCONFIG_TSTRUNTMPDIR/$tconfh
  fi
  $_MKCONFIG_RUNTESTDIR/$tf -d
  $_MKCONFIG_RUNTESTDIR/$tf -d >&8

  if [ -f ${tbase}.mksh -o -f ${tbase}.mkshpl ]; then
    echo ${EN} " ...${EC}"
    echo ${EN} " ...${EC}" >&8
    src=0
    scount=1
    for s in $shelllist; do
      unset _shell
      unset shell
      cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
      ss=`eval $cmd`
      if [ "$ss" = "sh" ]; then
        ss=`echo $s | sed 's,.*/,,'`
      fi
      _MKCONFIG_SHELL=$s
      export _MKCONFIG_SHELL
      shell=$ss

      runshelltest
      src=$?
      domath scount "$scount + 1"

      unset _shell
      unset shell
      unset _MKCONFIG_SHELL
    done
  else
    runshelltest
    src=$?
  fi

  if [ $src -ne 0 ]; then
    echo " ... failed"
    echo " failed" >&8
    domath fcount "$fcount + 1"
    src=1
    grc=1
  else
    echo " ... success"
    echo " success" >&8
  fi
  domath count "$count + 1"

  if [ "$DOPERL" = "T" -a \( -f ${tbase}.mkshpl -o -f ${tbase}.mkpl \) ]; then
    _MKCONFIG_TSTRUNTMPDIR=$_MKCONFIG_RUNTMPDIR/${tbase}_pl
    export _MKCONFIG_TSTRUNTMPDIR
    mkdir ${_MKCONFIG_TSTRUNTMPDIR}
    TSTRUNLOG=$_MKCONFIG_TSTRUNTMPDIR/${tbase}.log
    > $TSTRUNLOG
    exec 9>>$TSTRUNLOG

    dt=`date`
    echo "####" >&9
    echo "# Test: $tf mkconfig.pl" >&9
    echo "# $dt" >&9
    echo "####" >&9
    echo ${EN} "$tbase ...${EC}"
    echo ${EN} "$tbase ...${EC}" >&8
    $_MKCONFIG_RUNTESTDIR/$tf -d
    $_MKCONFIG_RUNTESTDIR/$tf -d >&8
    echo ${EN} " ... perl${EC}"
    echo ${EN} " ... perl${EC}" >&8
    echo "## Using mkconfig.pl " >&9
    if [ -f $tconfig ]; then
      cp $tconfig $_MKCONFIG_TSTRUNTMPDIR/$tconfh
    fi

    cd $_MKCONFIG_TSTRUNTMPDIR
    # dup stdout to 5; redirect stdout to 9; redirect stderr to new 1.
    $_MKCONFIG_RUNTESTDIR/$tf perl $_MKCONFIG_DIR/mkconfig.pl 5>&1 >&9 2>&1
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
  fi

  lastpass=$pass
done
# set std to saved fd 7; close 7
exec <&7 7<&-
test -f $TMPORDER && rm -f $TMPORDER

if [ $count -eq 0 ]; then  # this can't be right...
  $fcount = -1
fi

exec 8>&-

echo "$count tests $fcount failures"
if [ $fcount -eq 0 ]; then
  if [ "$MKC_KEEP_RUN_TMP" = "" ]; then
    test -d "$_MKCONFIG_RUNTMPDIR" && rm -rf "$_MKCONFIG_RUNTMPDIR"
  fi
fi

exit $fcount
