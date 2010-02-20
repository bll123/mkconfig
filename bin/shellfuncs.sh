#!/bin/sh

setechovars () {
  EN='-n'
  EC=''
  if [ "`echo -n test`" = "-n test" ]; then
    EN=''
    EC='\c'
  fi
}

testshcapability () {
  shhasappend=0
  shhasparamsub=0
  shhasmath=0
  $SHELL -c "xtmp=abc;ytmp=abc;xtmp+=\$ytmp" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    shhasappend=1
  fi
  $SHELL -c "xtmp=abc.abc;y=\${xtmp//./_}" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    shhasparamsub=1
  fi
  $SHELL -c "xtmp=1;y=\$((\$xtmp+1))" > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    shhasmath=1
  fi
}

dosubst () {
  var=$1
  shift
  sedargs=""
  while test $# -gt 0; do
    pattern=$1
    sub=$2
    if [ $shhasparamsub -eq 1 ]; then
      var=${var//${pattern}/${sub}}
    else
      sedargs="${sedargs} -e 's~${pattern}~${sub}~g'"
    fi
    shift
    shift
  done
  if [ $shhasparamsub -eq 0 ]; then
    var=`eval "echo ${var} | sed ${sedargs}"`
  fi
  echo $var
}

doappend () {
  var=$1
  val=$2
  if [ $shhasappend -eq 1 ]; then
    eval $var+=\$val
  else
    eval $var=\$${var}\$val
  fi
}

domath () {
  expr=$1
  if [ $shhasmath -eq 1 ]; then
    val=$(($expr))
  else
    val=`expr $expr`
  fi
}
