#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA, USA
#

mkconfigversion () {
  echo "mkconfig version 1.2"
}

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
  shhasupper=0
  (eval "x=a;x+=b; test z\$x = zab") 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasappend=1
    eval 'doappend () { var=$1; val=$2; eval $var+=\$val; }'
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
    eval 'domath () { expr=$1; val=$(($expr)); echo $val; }'
  fi
  (eval "typeset -u var;var=x;test z\$var = zX") 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasupper=1
    eval 'toupper () { val=$1; typeset -u uval;uval=$val;echo $uval; }'
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
  var=`eval "echo \"${var}\" | sed ${sedargs}"`
  echo $var
}

doappend () {
  var=$1
  val=$2
  eval $var=\$${var}\$val
}

domath () {
  expr=$1
  val=`expr $expr`
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
  elif [ "$BASH_VERSION" != "" ]; then
    shell=bash
  elif [ "$ZSH_VERSION" != "" ]; then
    shell=zsh
  fi
  echo $shell
}

testshell () {
  rc=0
  shell=$1

  # force shell type.
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    if [ "$SHELL" != "$_MKCONFIG_SHELL" ]; then
      SHELL="$_MKCONFIG_SHELL"
      export SHELL
      rc=1
    fi
    return $rc
  fi

  ok=1
  if [ "$shell" = "pdksh" ]; then   # often broken
    ok=0
  fi
  if [ "$shell" = "zsh" ]; then   # broken
    ok=0
  fi

  if [ $ok -eq 0 ]; then
    # if this system is old enough to have /bin/sh5,
    # we want it in preference to other shells
    if [ -f /bin/sh5 ]; then
      SHELL=/bin/sh5
    else
      SHELL=/bin/sh
    fi
    rc=1
  fi

  # bash is really slow, replace it if possible.
  if [ $ok -eq 0 -o $shell = "bash" ]; then
    noksh=0
    if [ -x /usr/bin/ksh ]; then
      SHELL=/usr/bin/ksh
      tcmd="/usr/bin/ksh -c \"echo \\\$KSH_VERSION\""
      vers=`eval ${tcmd}`
      case $vers in
        *PD*)
          noksh=1
          SHELL=/bin/sh
          ;;
        *)
          rc=1
          ;;
      esac
    else
      noksh=1
    fi

    if [ $noksh -eq 1 -a -x /bin/ash ]; then
      SHELL=/bin/ash
      rc=1
    fi
    if [ $noksh -eq 1 -a -x /bin/dash ]; then
      SHELL=/bin/dash
      rc=1
    fi
  fi

  # make sure SHELL env var is set.
  if [ $rc -eq 0 ]; then
    wsh=`locatecmd $shell`
    SHELL=${wsh}
  fi

  export SHELL
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

toupper () {
  val=$1
  echo `echo $val | tr '[a-z]' '[A-Z]'`
}
