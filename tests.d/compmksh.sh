#!/bin/sh

script=$@
echo ${EN} "compile mkconfig.sh${EC}" >&3

grc=0

echo ${EN} " ${EC}" >&3
for s in /bin/sh /bin/bash /bin/posh /bin/ash /bin/dash; do
  if [ -x $s ]; then
    ls -l $s | grep -- '->' > /dev/null 2>&1
    rc1=$?
    ls -l $s | grep '/etc/alternatives' > /dev/null 2>&1
    rc2=$?
    if [ $rc1 -ne 0 -o $rc2 -eq 0 ]; then
      sh=`echo $s | sed 's,.*/,,'`
      echo ${EN} "${sh} ${EC}" >&3
      echo "   testing with ${sh} "
      $s -n $RUNTOPDIR/mkconfig.sh
      rc=$?
      if [ $rc -ne 0 ];then grc=$rc; fi
    fi
  fi
done

for s in /usr/bin/ksh /bin/ksh; do
  if [ $s = "/bin/ksh" ]; then
    ls -l /bin | grep -- '->' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      continue
    fi
  fi

  if [ -x $s ]; then
    ls -l $s | grep -- '->' > /dev/null 2>&1
    rc1=$?
    ls -l $s | grep '/etc/alternatives' > /dev/null 2>&1
    rc2=$?
    if [ $rc1 -ne 0 -o $rc2 -eq 0 ]; then
      cmd="$s -c \". $mypath/shellfuncs.sh;getshelltype;echo \\\$shell\""
      tshell=`eval $cmd`
      case $tshell in
        pdksh)
          ;;
        *)
          sh=`echo $s | sed 's,.*/,,'`
          echo ${EN} "${sh} ${EC}" >&3
          echo "   testing with ${sh} "
          $s -n $RUNTOPDIR/mkconfig.sh
          rc=$?
          if [ $rc -ne 0 ];then grc=$rc; fi
          ;;
      esac
    fi
  fi
done

exit $grc
