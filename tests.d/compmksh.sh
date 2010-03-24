#!/bin/sh

script=$@
echo ${EN} "compile mkconfig.sh${EC}" >&3

grc=0

echo ${EN} " ${EC}" >&3

plist=""
ls -ld /bin | grep -- '->' > /dev/null 2>&1
if [ $? -ne 0 ]; then
  plist=/bin
fi
plist="${plist} /usr/bin /usr/local/bin"

for p in $plist; do
  for s in sh bash posh ash dash; do
    if [ -x $p/$s ]; then
      ls -l $p/$s | grep -- '->' > /dev/null 2>&1
      rc1=$?
      ls -l $p/$s | grep '/etc/alternatives' > /dev/null 2>&1
      rc2=$?
      if [ $rc1 -ne 0 -o $rc2 -eq 0 ]; then
        echo ${EN} "${s} ${EC}" >&3
        echo "   testing with ${s} "
        $p/$s -n $RUNTOPDIR/mkconfig.sh
        rc=$?
        if [ $rc -ne 0 ];then grc=$rc; fi
      fi
    fi
  done

  for s in ksh; do
    if [ -x $p/$s ]; then
      ls -l $p/$s | grep -- '->' > /dev/null 2>&1
      rc1=$?
      ls -l $p/$s | grep '/etc/alternatives' > /dev/null 2>&1
      rc2=$?
      if [ $rc1 -ne 0 -o $rc2 -eq 0 ]; then
        cmd="$p/$s -c \". $RUNTOPDIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
        tshell=`eval $cmd`
        case $tshell in
          pdksh)
            ;;
          *)
            echo ${EN} "${s} ${EC}" >&3
            echo "   testing with ${s} "
            $p/$s -n $RUNTOPDIR/mkconfig.sh
            rc=$?
            if [ $rc -ne 0 ];then grc=$rc; fi
            ;;
        esac
      fi
    fi
  done
done

exit $grc
