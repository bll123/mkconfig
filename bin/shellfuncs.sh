#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA, USA
#

mkconfigversion () {
  echo "mkconfig version `cat $mypath/VERSION`"
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

test_append () {
  shhasappend=0
  (eval 'x=a;x+=b; test z$x = zab') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasappend=1
    eval 'doappend () { eval $1+=\$2; }'
  else
    eval 'doappend () { eval $1=\$${1}\$2; }'
  fi
}

test_paramsub () {
  shhasparamsub=0
  ( eval 'x=bcb;y=${x/c/_};test z${y} = zb_b') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasparamsub=1
    eval 'dosubst () { var=$1; shift;
        while test $# -gt 0; do
        pattern=$1; sub=$2;
        var=${var//${pattern}/${sub}};
        shift; shift; done; echo $var; }'
  else
    eval 'dosubst () { var=$1; shift;
        sedargs=""; while test $# -gt 0; do pattern=$1; sub=$2;
        sedargs="${sedargs} -e \"s~${pattern}~${sub}~g\""; shift; shift; done
        var=`eval "echo \"${var}\" | sed ${sedargs}"`; echo $var; }'
  fi
}

test_math () {
  shhasmath=0
  (eval 'x=1;y=$(($x+1)); test z$y = z2') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasmath=1
    eval 'domath () { echo $(($1)); }'
  else
    eval 'domath () { echo `expr $1`; }'
  fi
}

test_upper () {
  shhasupper=0
  (eval 'typeset -u var;var=x;test z$var = zX') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasupper=1
    eval 'toupper () { typeset -u uval;uval=$1;echo $uval; }'
  else
    eval 'toupper () { echo `echo $1 | tr '[a-z]' '[A-Z]'`; }'
  fi
}

testshcapability () {
  test_append
  test_paramsub
  test_math
  test_upper
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
  if [ "$shell" = "sh" ]; then
    out=`$SHELL --version exit 2>&1`
    echo $out | grep 'bash' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      shell=bash
    fi
    if [ "$shell" = "sh" ]; then
      echo $out | grep 'AT&T' > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        shell=ksh
      fi
    fi
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
      shell=sh5
    else
      SHELL=/bin/sh
      shell=sh
    fi
    rc=1
  fi

  # bash is really slow, replace it if possible.
  if [ $ok -eq 0 -o $shell = "bash" ]; then
    noksh=0
    if [ -x /usr/bin/ksh ]; then
      SHELL=/usr/bin/ksh
      shell=ksh
      tcmd="/usr/bin/ksh -c \"echo \\\$KSH_VERSION\""
      vers=`eval ${tcmd}`
      case $vers in
        *PD*)
          noksh=1               # but not w/pdksh; some versions crash
          SHELL=/bin/sh
          shell=sh
          ;;
        *)
          rc=1
          ;;
      esac
    else
      noksh=1
    fi

    # either of these are fine...no preference
    if [ $noksh -eq 1 -a -x /bin/ash ]; then
      SHELL=/bin/ash
      shell=ash
      rc=1
    fi
    if [ $noksh -eq 1 -a -x /bin/dash ]; then
      SHELL=/bin/dash
      shell=dash
      rc=1
    fi
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

  # make sure SHELL env var is set.
  wsh=`locatecmd $shell`
  SHELL=${wsh}
  export SHELL
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

