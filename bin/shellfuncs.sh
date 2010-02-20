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
  (eval "x=a;x+=b; test z\$x = zab") 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasappend=1
  fi
  ( eval "x=bcb;y=\${x/c/_};test z\$y = zb_b")
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
  fi
  if [ "$BASH_VERSION" != "" ]; then
    shell=bash
  fi
  if [ "$ZSH_VERSION" != "" ]; then
    shell=zsh
  fi
  if [ "$shell" = "sh" -a "$_" != "" ]; then
    case $_ in
      *bash)
        shell=bash
        ;;
      *dash)
        shell=dash
        ;;
      *ksh)
        shell=ksh
        ;;
      *zsh)
        shell=zsh
        ;;
    esac
  fi
  echo $shell
}

testshell () {
  rc=0
  shell=$1
  baseshell=`basename $SHELL`
  if [ "$baseshell" = "pdksh" -a "$shell" = "ksh" ]; then
    shell=pdksh
  fi
  # test if $SHELL and what type of shell started this script are equal.
  # if not, the shell capabilities test will break, so restart
  # this program using a standard shell.
  ok=0
  # sh is commonly bash in disguise
  if [ "$shell" = "sh" -a "$baseshell" = "bash" ]; then
    ok=1
  fi
  # dash is commonly installed as sh
  if [ "$shell" = "sh" -a "$baseshell" = "dash" ]; then
    ok=1
  fi
  if [ "$shell" = "$baseshell" ]; then
    ok=1
  fi
  if [ "$baseshell" = "pdksh" ]; then   # broken
    ok=0
  fi
  if [ "$baseshell" = "zsh" ]; then   # broken
    ok=0
  fi
  if [ $ok -eq 0 ]; then
    SHELL=/bin/sh
    systype=`uname -s 2>/dev/null`
    noksh=0
    case ${systype} in
      CYGWIN*)
        noksh=1     # cygwin's ksh is a link to pdksh
        ;;
    esac
    if [ $noksh -eq 0 -a -x /usr/bin/ksh ]; then
      SHELL=/usr/bin/ksh
    fi
    if [ $noksh -eq 1 -a -x /usr/bin/dash ]; then
      SHELL=/usr/bin/dash
    fi
    export SHELL
    rc=1
  fi
  return $rc
}
