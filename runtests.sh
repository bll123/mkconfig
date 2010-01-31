#!/bin/sh

export CC=cc

EN='-n'
EC=''

echo -n 'test' | grep -- '-n' > /dev/null 2>&1
rc=$?
if [ $rc -eq 0 ]
then
    EN=''
    EC='\c'
fi

clean () {
  rm -rf mkconfig.log mkconfig.cache _tmp_mkconfig \
    reqlibs.txt config.h > /dev/null 2>&1
}

count=0
fcount=0
for tf in test_??.sh
do
  tlog=`echo $tf | sed 's/\.sh$/.log/'`
  echo ${EN} "$tf ... ${EC}"
  clean
  echo "## stdout" > ${tlog}
  ./$tf >> ${tlog} 2>&1
  rc=$?
  if [ $rc -ne 0 ]
  then
    echo "failed"
    fcount=`expr $fcount + 1`
    echo "## mkconfig.log" >> ${tlog}
    cat mkconfig.log >> ${tlog}
  else
    echo "success"
    rm -f ${tlog} 
  fi
  clean
  count=`expr $count + 1`
done

echo "$count tests $fcount failures"
exit $fcount
