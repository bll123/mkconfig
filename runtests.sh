#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 1994-2010 Brad Lanam, Walnut Creek, CA
#

RUNTMP=_tmp_runtests
export RUNTMP

mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
. ${mypath}/shellfuncs.sh

doshelltest $@
setechovars
mkconfigversion

RUNTOPDIR=`pwd`
export RUNTOPDIR
RUNLOG=$RUNTOPDIR/tests.log
TRUNLOG=$RUNTOPDIR/test_tmp.log

testdir=$1
if [ ! -d $testdir ]; then
  echo "## Unable to locate $testdir"
  exit 1
fi

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

if [ ! -f test_order ]; then
  echo "## Unable to locate 'test_order'"
  exit 1
fi

test -d "$RUNTMP" && rm -rf "$RUNTMP"
mkdir $RUNTMP
> $RUNLOG

tot=`wc -l test_order | sed 's/ .*//'`
pass=1
count=0
fcount=0
while test $count -lt $tot; do
  exec 7<&0 < test_order
  while read tfline; do
    set $tfline
    passnum=$1
    tbase=$2
    if [ $passnum -ne $pass ]; then
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
      fcount=`domath "$fcount + 1"`
      count=`domath "$count + 1"`
      clean $tbase
      continue
    fi

    > $TRUNLOG
    dt=`date`
    echo "####" >> $TRUNLOG
    echo "# Test: $tf $arg" >> $TRUNLOG
    echo "# $dt" >> $TRUNLOG
    echo "####" >> $TRUNLOG
    grc=0
    arg=""
    if [ -f $tmkconfig ]; then
      echo "##==  mkconfig.sh " >> ${TRUNLOG}
      arg="mkconfig.sh"
    fi
    echo ${EN} "$tf ... ${arg} ${EC}"
    if [ -f $tconfig ]; then
      cat $tconfig > $RUNTMP/$tconfh
    fi

    cd $RUNTMP
    echo "##== stdout" >> ${TRUNLOG}
    ${SHELL} ../$tf "${SHELL} ../../$arg" 3>&1 >> ${TRUNLOG} 2>&1
    rc=$?
    if [ -f mkconfig.log ]; then
      echo "##== mkconfig.log" >> ${TRUNLOG}
      cat mkconfig.log >> ${TRUNLOG}
    fi
    cd ..

    dt=`date`
    echo "####" >> $TRUNLOG
    echo "# $dt" >> $TRUNLOG
    echo "####" >> $TRUNLOG
    if [ $rc -ne 0 ]; then
      echo " ... failed"
      fcount=`domath "$fcount + 1"`
      grc=1
      cat $TRUNLOG >> $RUNLOG
    else
      echo " ... success"
    fi
    rm -f $TRUNLOG
    count=`domath "$count + 1"`

    if [ -f $tmkconfig ]; then
      > $TRUNLOG
      dt=`date`
      echo "####" >> $TRUNLOG
      echo "# Test: $tf mkconfig.pl" >> $TRUNLOG
      echo "# $dt" >> $TRUNLOG
      echo "####" >> $TRUNLOG
      echo ${EN} "$tf ... mkconfig.pl ${EC}"
      echo "##== mkconfig.pl " >> ${TRUNLOG}
      if [ -f $tconfig ]; then
        cat $tconfig > $RUNTMP/$tconfh
      fi

      cd $RUNTMP
      echo "##== stdout" >> ${TRUNLOG}
      ${SHELL} ../$tf perl ../../mkconfig.pl 3>&1 >> ${TRUNLOG} 2>&1
      rc=$?
      if [ -f mkconfig.log ]; then
        echo "##== mkconfig.log" >> ${TRUNLOG}
        cat mkconfig.log >> ${TRUNLOG}
      fi
      cd ..

      dt=`date`
      echo "####" >> $TRUNLOG
      echo "# $dt" >> $TRUNLOG
      echo "####" >> $TRUNLOG
      if [ $rc -ne 0 ]; then
        echo " ... failed"
        fcount=`domath "$fcount + 1"`
        cat $TRUNLOG >> $RUNLOG
      else
        echo " ... success"
      fi
      rm -f $TRUNLOG
      count=`domath "$count + 1"`
    fi
  done
  exec <&7 7<&-
  pass=`domath "$pass + 1"`
done

if [ $fcount -eq 0 ]; then
  rm -f $RUNLOG
fi

echo "$count tests $fcount failures"
test -d "$RUNTMP" && rm -rf "$RUNTMP"
exit $fcount
