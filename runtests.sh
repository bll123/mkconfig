#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 1994-2010 Brad Lanam, Walnut Creek, CA
#

clean () {
  tbase=$1
  rm -rf mkconfig.log mkconfig.cache _tmp_mkconfig _tmp_$tbase \
    reqlibs.txt $tbase.ctmp $tbase.ctest > /dev/null 2>&1
}

mypath=`dirname $0`
. ${mypath}/features/shellfuncs.sh

shell=`getshelltype`
testshell $shell
if [ $? != 0 ]; then
  exec $SHELL $0 $@
fi
testshcapability
setechovars
export EN EC

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

count=0
fcount=0
for tf in test_??.sh
do
  tbase=`echo $tf | sed 's/\.sh$//'`
  tlog="${tbase}.log"
  tmkconfig="${tbase}.mkconfig"
  tconfig="${tbase}.config"
  tconfh="${tbase}.ctmp"

  clean $tbase
  if [ ! -x ./$tf ]; then
    echo "permission denied"
    fcount=`domath "$fcount + 1"`
    count=`domath "$count + 1"`
    rm -f ${tlog}
    clean $tbase
    continue
  fi

  > ${tlog}
  grc=0
  arg=""
  if [ -f $tmkconfig ]; then
    echo "##==== mkconfig.sh " >> ${tlog}
    arg="mkconfig.sh"
  fi
  echo "##== env" >> ${tlog}
  env | sort >> ${tlog}
  echo "##== stdout" >> ${tlog}
  echo ${EN} "$tf ... ${arg} ${EC}"
  if [ -f $tconfig ]; then
    cat $tconfig > $tconfh
  fi
  ${SHELL} ./$tf "${SHELL} ../$arg" 3>&1 >> ${tlog} 2>&1
  rc=$?
  if [ -f mkconfig.log ]; then
    echo "##== mkconfig.log" >> ${tlog}
    cat mkconfig.log >> ${tlog}
  fi
  if [ $rc -ne 0 ]; then
    echo " ... failed"
    fcount=`domath "$fcount + 1"`
    grc=1
  else
    echo " ... success"
    if [ ! -f $tmkconfig ]; then
      rm -f ${tlog}
    fi
  fi
  clean $tbase
  count=`domath "$count + 1"`

  if [ -f $tmkconfig ]; then
    echo ${EN} "$tf ... mkconfig.pl ${EC}"
    echo "##==== mkconfig.pl " >> ${tlog}
    echo "##== env" >> ${tlog}
    env | sort >> ${tlog}
    echo "##== stdout" >> ${tlog}
    if [ -f $tconfig ]; then
      cat $tconfig > $tconfh
    fi
    ${SHELL} ./$tf perl ../mkconfig.pl 3>&1 >> ${tlog} 2>&1
    rc=$?
    echo "##== mkconfig.log" >> ${tlog}
    cat mkconfig.log >> ${tlog}
    if [ $rc -ne 0 ]; then
      echo " ... failed"
      fcount=`domath "$fcount + 1"`
    else
      echo " ... success"
      if [ $grc -eq 0 ]; then
        rm -f ${tlog}
      fi
    fi
    clean $tbase
    count=`domath "$count + 1"`
  fi
done

echo "$count tests $fcount failures"
exit $fcount
