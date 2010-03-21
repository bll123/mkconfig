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
#    7 - temporary for mkconfig.sh
#    9 - $TSTRUNLOG
#    3 - stdout (as 1 is directed to the log)
#

TESTORDER=test_order
RUNTMP=_tmp_runtests
export RUNTMP

mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
export mypath
. ${mypath}/shellfuncs.sh

doshelltest $@
setechovars
mkconfigversion

RUNTOPDIR=`pwd`
export RUNTOPDIR
RUNLOG=$RUNTOPDIR/tests.log
TSTRUNLOG=$RUNTOPDIR/test_tmp.log

testdir=$1
if [ ! -d $testdir ]; then
  echo "## Unable to locate $testdir"
  exit 1
fi

shift
teststorun="$*"

CC=${CC:-cc}
export CC

cd $testdir
if [ $? != 0 ]; then
  echo "## Unable to cd to $testdir"
  exit 1
fi

RUNTESTDIR="$RUNTOPDIR/$testdir"
export RUNTESTDIR
RUNTMPDIR="$RUNTESTDIR/$RUNTMP"
export RUNTMPDIR

notestorder=F
if [ ! -f "$TESTORDER" ]; then
  notestorder=T
  ls -1d *.d *.sh 2>/dev/null | grep -v $TESTORDER |
    sed -e 's/^/1 /' -e 's/\.sh$//' > $TESTORDER
fi

test -d "$RUNTMP" && rm -rf "$RUNTMP"
mkdir $RUNTMP
> $RUNLOG

if [ "$teststorun" != "" ]; then
  tot=`echo $teststorun | wc -w`
else
  tot=`wc -l $TESTORDER | sed -e 's/^ *//' -e 's/ .*//'`
fi
pass=1
count=0
fcount=0
while test $count -lt $tot; do
  exec 7<&0 < $TESTORDER
  while read tfline; do
    set $tfline
    passnum=$1
    tbase=$2
    if [ $passnum -ne $pass ]; then
      continue
    fi

    if [ "$teststorun" != "" ]; then
      echo $teststorun | grep $tbase > /dev/null 2>&1
      rc=$?
      if [ $rc -ne 0 ]; then
        continue
      fi
    fi

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
      echo "$tf: missing"
      ok=F
    fi
    if [ ! -x ./$tf ]; then
      echo "$tf: permission denied"
      ok=F
    fi
    if [ $ok = F ]; then
      domath fcount "$fcount + 1"
      domath count "$count + 1"
      clean $tbase
      continue
    fi

    > $TSTRUNLOG
    exec 9>>$TSTRUNLOG
    dt=`date`
    echo "####" >&9
    echo "# Test: $tf $arg" >&9
    echo "# $dt" >&9
    echo "####" >&9
    grc=0
    arg=""
    if [ -f $tmkconfig ]; then
      echo "##==  mkconfig.sh " >&9
      arg="mkconfig.sh"
    fi
    echo ${EN} "$tf ... ${arg} ${EC}"
    if [ -f $tconfig ]; then
      cat $tconfig > $RUNTMP/$tconfh
    fi
    if [ "$arg" != "" ]; then
      arg="../../$arg"
    fi

    cd $RUNTMP
    echo "##== stdout" >&9
    ${SHELL} ../$tf "${SHELL} $arg" 3>&1 >&9 2>&1
    rc=$?
    if [ -f mkconfig.log ]; then
      echo "##== mkconfig.log" >&9
      cat mkconfig.log >&9
    fi
    cd ..

    dt=`date`
    echo "####" >&9
    echo "# $dt" >&9
    echo "####" >&9
    if [ $rc -ne 0 ]; then
      echo " ... failed"
      domath fcount "$fcount + 1"
      grc=1
      cat $TSTRUNLOG >> $RUNLOG
    else
      echo " ... success"
    fi
    rm -f $TSTRUNLOG
    domath count "$count + 1"

    if [ -f $tmkconfig ]; then
      > $TSTRUNLOG
      dt=`date`
      echo "####" >&9
      echo "# Test: $tf mkconfig.pl" >&9
      echo "# $dt" >&9
      echo "####" >&9
      echo ${EN} "$tf ... mkconfig.pl ${EC}"
      echo "##== mkconfig.pl " >&9
      if [ -f $tconfig ]; then
        cat $tconfig > $RUNTMP/$tconfh
      fi

      cd $RUNTMP
      echo "##== stdout" >&9
      ${SHELL} ../$tf perl ../../mkconfig.pl 3>&1 >&9 2>&1
      rc=$?
      if [ -f mkconfig.log ]; then
        echo "##== mkconfig.log" >&9
        cat mkconfig.log >&9
      fi
      cd ..

      dt=`date`
      echo "####" >&9
      echo "# $dt" >&9
      echo "####" >&9
      exec 9>&-
      if [ $rc -ne 0 ]; then
        echo " ... failed"
        domath fcount "$fcount + 1"
        cat $TSTRUNLOG >> $RUNLOG
      else
        echo " ... success"
      fi
      rm -f $TSTRUNLOG
      domath count "$count + 1"
    fi
  done
  exec <&7 7<&-
  domath pass "$pass + 1"
done

if [ "$notestorder" = "T" ]; then
  rm -f $TESTORDER > /dev/null 2>&1
fi

if [ $fcount -eq 0 ]; then
  rm -f $RUNLOG
fi
if [ $count -eq 0 ]; then  # this can't be right...
  $fcount = -1
fi

echo "$count tests $fcount failures"
test -d "$RUNTMP" && rm -rf "$RUNTMP"
exit $fcount
