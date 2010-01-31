#!/bin/sh

export CC=${CC:-cc}

export EN='-n'
export EC=''
exec 3>&1

echo -n 'test' | grep -- '-n' > /dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]
then
    EN=''
    EC='\c'
fi

clean () {
  tbase=$1
  rm -rf mkconfig.log mkconfig.cache _tmp_mkconfig \
    reqlibs.txt config.h $tbase.configh > /dev/null 2>&1
}

count=0
fcount=0
for tf in test_??.sh
do
  tbase=`echo $tf | sed 's/\.sh$//'`
  tlog="${tbase}.log"
  tmkconfig="${tbase}.mkconfig"
  tconfig="${tbase}.config"
  tconfh="${tbase}.configh"

  clean $tbase
  if [ ! -x ./$tf ]; then
    echo "permission denied"
    fcount=`expr $fcount + 1`
    count=`expr $count + 1`
    rm -f ${tlog}
    clean $tbase
    continue
  fi

  > ${tlog}
  grc=0
  arg=""
  if [ -f $tmkconfig ]; then
    echo "## === mkconfig.sh " >> ${tlog}
    arg="mkconfig.sh"
  fi
  echo "## stdout" >> ${tlog}
  echo ${EN} "$tf ... ${arg} ${EC}"
  if [ -f $tconfig ]; then
    cp -pf $tconfig $tconfh
  fi
  ./$tf $arg >> ${tlog} 2>&1
  rc=$?
  if [ -f mkconfig.log ]; then
    echo "## mkconfig.log" >> ${tlog}
    cat mkconfig.log >> ${tlog}
  fi
  if [ $rc -ne 0 ]; then
    echo " ... failed"
    fcount=`expr $fcount + 1`
    grc=1
  else
    echo " ... success"
  fi
  clean $tbase
  count=`expr $count + 1`

  if [ -f $tmkconfig ]; then
    echo ${EN} "$tf ... mkconfig.pl ${EC}"
    echo "## === mkconfig.pl " >> ${tlog}
    echo "## stdout" >> ${tlog}
    if [ -f $tconfig ]; then
      cat $tconfig | sed 's/_mkconfig_sh 1/_mkconfig_sh 0/' |
        sed 's/_mkconfig_pl 0/_mkconfig_pl 1/' > $tconfh
    fi
    ./$tf mkconfig.pl >> ${tlog} 2>&1
    rc=$?
    echo "## mkconfig.log" >> ${tlog}
    cat mkconfig.log >> ${tlog}
    if [ $rc -ne 0 ]; then
      echo " ... failed"
      fcount=`expr $fcount + 1`
    else
      echo " ... success"
      if [ $grc -eq 0 ]; then
        rm -f ${tlog}
      fi
    fi
    clean $tbase
    count=`expr $count + 1`
  fi
done

echo "$count tests $fcount failures"
exit $fcount
