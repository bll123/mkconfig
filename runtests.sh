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
#    3 - stdout (as 1 is directed to the log)
#

TESTORDER=test_order
RUNTMP=_tmp_runtests
export RUNTMP

RUNTOPDIR=`pwd`
export RUNTOPDIR

mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
cd $mypath
MKCONFIG_DIR=`pwd`
export MKCONFIG_DIR
cd $RUNTOPDIR
. ${MKCONFIG_DIR}/shellfuncs.sh

doshelltest $0 $@
setechovars
mkconfigversion

RUNLOG=$RUNTOPDIR/tests.log
TSTRUNLOG=$RUNTOPDIR/test_tmp.log

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

RUNTESTDIR=`pwd`
export RUNTESTDIR
RUNTMPDIR="$RUNTESTDIR/$RUNTMP"
export RUNTMPDIR

if [ "$teststorun" = "" ]; then
  if [ ! -f "$TESTORDER" ]; then
    teststorun=`ls -1d *.d *.sh 2>/dev/null | sed 's/\.sh$//'`
  else
    teststorun=`sort $TESTORDER | sed 's/.* //'`
  fi
fi

test -d "$RUNTMP" && rm -rf "$RUNTMP"
mkdir $RUNTMP
> $RUNLOG

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
    arg="$MKCONFIG_DIR/$arg"
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
    ${SHELL} ../$tf perl $MKCONFIG_DIR/mkconfig.pl 3>&1 >&9 2>&1
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

if [ $fcount -eq 0 ]; then
  rm -f $RUNLOG
fi
if [ $count -eq 0 ]; then  # this can't be right...
  $fcount = -1
fi

echo "$count tests $fcount failures"
test -d "$RUNTMP" && rm -rf "$RUNTMP"
exit $fcount
