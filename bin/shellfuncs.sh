#!/bin/sh

setechovars () {
  EN='-n'
  EC=''
  if [ "`echo -n test`" = "-n test" ]; then
    EN=''
    EC='\c'
  fi
  export EN
  export EC
}

testshcapability () {
  shhasappend=0
  shhasparamsub=0
  shhasmath=0
  (eval "x=a;x+=b; test z\$x = zab") 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasappend=1
  fi
  ( eval "x=bcb;y=\${x/c/_};test z\$y = zb_b") 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasparamsub=1
    # old freebsd shell complains if this substitution is inline.
    # so replace the function when this capability is available.
    eval 'dosubst () { var=$1; shift;
        while test $# -gt 0; do
        pattern=$1; sub=$2;
        var=${var//${pattern}/${sub}};
        shift; shift; done; echo $var; } '
  fi
  (eval "x=1;y=\$((\$x+1)); test z\$y = z2") 2>/dev/null
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
    sedargs="${sedargs} -e 's~${pattern}~${sub}~g'"
    shift
    shift
  done
  var=`eval "echo ${var} | sed ${sedargs}"`
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
  echo $val
}

getshelltype () {
  shell="sh"   # unknown or old
  if [ "$KSH_VERSION" != "" ]; then
    shell=ksh
    case $KSH_VERSION in
      *PD*)
        shell=pdksh
        ;;
    esac
  fi
  if [ "$BASH_VERSION" != "" ]; then
    shell=bash
  fi
  if [ "$ZSH_VERSION" != "" ]; then
    shell=zsh
  fi
  echo $shell
}

testshell () {
  rc=0
  shell=$1
  ok=1
  if [ "$shell" = "pdksh" ]; then   # often broken
    ok=0
  fi
  if [ "$shell" = "zsh" ]; then   # broken
    ok=0
  fi

  if [ $ok -eq 0 ]; then
    SHELL=/bin/sh
    rc=1
  fi

  # most anything's better than bash.
  if [ $shell = "bash" ]; then
    noksh=0
    if [ -x /usr/bin/ksh ]; then
      SHELL=/usr/bin/ksh
      vers=`/usr/bin/ksh -c "echo \$KSH_VERSION"`
      case $vers in
        *PD*)
          noksh=1
          SHELL=/bin/sh
          ;;
      esac
    fi
    if [ $noksh -eq 1 -a -x /bin/ash ]; then
      SHELL=/bin/ash
    fi
    if [ $noksh -eq 1 -a -x /bin/dash ]; then
      SHELL=/bin/dash
    fi
    export SHELL
    rc=1
  fi

  if [ $rc -eq 0 ]; then
    wsh=`locatecmd $shell`
    SHELL=${wsh}
    export SHELL
  fi

  return $rc
}

doshelltest () {
  shell=`getshelltype`
  testshell $shell
  if [ $? != 0 ]; then
    exec $SHELL $0 $@
  fi
  testshcapability
}

locatecmd () {
  tcmd=$1
  if [ "$pthlist" = "" ]; then
    pthlist=`dosubst "$PATH" ';' ' ' ':' ' '`
  fi
  trc=""
  for p in $pthlist; do
    if [ -x "$p/$tcmd" ]; then
      trc="$p/$tcmd"
      break
    fi
  done
  echo $trc
}
