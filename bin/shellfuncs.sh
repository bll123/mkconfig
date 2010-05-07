#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA, USA
#

read _MKCONFIG_VERSION < ${_MKCONFIG_DIR}/VERSION
export _MKCONFIG_VERSION

tryshell="ash bash dash ksh mksh posh sh sh5"

mkconfigversion () {
  echo "mkconfig version ${_MKCONFIG_VERSION}"
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

dosubst () { 
  subvar=$1
  shift
  sa=""
  while test $# -gt 0; do 
    pattern=$1
    sub=$2
    shift
    shift
    sa="${sa} -e \"s~${pattern}~${sub}~g\""
  done
  cmd="${subvar}=\`echo \${${subvar}} | sed ${sa}\`"
  eval $cmd; 
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

test_math () {
  shhasmath=0
  (eval 'x=1;y=$(($x+1)); test z$y = z2') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasmath=1
    eval 'domath () { mthvar=$1; val=$(($2)); eval $mthvar=$val; }'
  else
    eval 'domath () { mthvar=$1; val=`expr $2`; eval $mthvar=$val; }'
  fi
}

test_upper () {
  shhasupper=0
  (eval 'typeset -u var;var=x;test z$var = zX') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasupper=1
    eval 'toupper () { ucvar=$1; typeset -u uval; eval "uval=\${$ucvar};$ucvar=\$uval"; }'
  else
    eval 'toupper () { ucvar=$1; cmd="$ucvar=\`echo \${$ucvar} | tr \"[a-z]\" \"[A-Z]\"\`"; eval "$cmd"; }'
  fi
}

testshcapability () {
  test_append
  test_math
  test_upper
}

getshelltype () {
  shell=${_shell:-sh}   # unknown or old
  baseshell=${_shell:-sh}
  ( eval 'echo ${.sh.version}' ) >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    eval 'KSH_VERSION=${.sh.version}'
  fi
  if [ "$KSH_VERSION" != "" ]; then
    shell=ksh
    baseshell=ksh
    case $KSH_VERSION in
      *PD*)
        shell=pdksh
        ;;
      *93*)
        shell=ksh93
        ;;
      *88*)
        shell=ksh88
        ;;
      *MIRBSD*)
        shell=mksh
        ;;
    esac
  elif [ "$BASH_VERSION" != "" ]; then
    baseshell=bash
    ver=`echo $BASH_VERSION | sed 's/\..*//'`
    shell=bash${ver}
  elif [ "$ZSH_VERSION" != "" ]; then
    baseshell=zsh
    shell=zsh
  elif [ "$POSH_VERSION" != "" ]; then
    baseshell=posh
    shell=posh
  fi

  # can try --version, but don't really know the path
  # of the shell running us; can't depend on $SHELL.
  # and it only works for bash and some versions of ksh.
}

doshelltest () {
  # force shell type.
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    if [ "$SHELL" != "$_MKCONFIG_SHELL" ]; then
      SHELL="$_MKCONFIG_SHELL"
      export SHELL
      exec $SHELL $dstscript $@
    fi
  fi

  getshelltype
  chkshell
  if [ $? -ne 0 ]; then
    echo "The shell in use ($shell) does not have the correct functionality:" >&2
    echo $chkmsg >&2
    echo "Please try another shell." >&2
    exit 1
  fi
  testshcapability
}

locatecmd () {
  lvar=$1
  ltcmd=$2

  if [ "$_pthlist" = "" ]; then
    _pthlist=`echo $PATH | sed 's/:/ /g'`
  fi

  lcmd=""
  for p in $_pthlist; do
    if [ -x "$p/$ltcmd" ]; then
      lcmd="$p/$ltcmd"
      break
    fi
  done
  eval $lvar=$lcmd
}

# function to make sure the shell has
# some basic capabilities w/o weirdness.
chkshell () {

  grc=0

  TMP=x$$
  chkmsg=""
  # test to make sure the set command works properly
  # some shells output xyzzy='abc def'
  # some shells output xyzzy=$'abc def' (ok; handled in mkconfig.sh)
  (
    cmd='xyzzy="abc def"; val=`set | grep "^xyzzy"`; test "$val" = "xyzzy=abc def"'
    eval $cmd 2>/dev/null
    if [ $? -eq 0 ]; then
      exit 0
    fi
    cmd="xyzzy=\"abc def\"; val=\`set | grep \"^xyzzy\"\`; test \"\$val\" = \"xyzzy='abc def'\" -o \"\$val\" = \"xyzzy=\\$'abc def'\""
    eval $cmd 2>/dev/null
    if [ $? -eq 0 ]; then
      exit 0
    fi
    exit 1
  )
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=$rc
    chkmsg="${chkmsg}
'set' output not x=a b or x='a b'."
  fi

  # test for broken output redirect (e.g. zsh hangs)
  (
    rm -f $TMP $TMP.out > /dev/null 2>&1
    cmd="> $TMP;test -f $TMP;echo \$? > $TMP.out"
    eval $cmd &
    job=$!
    sleep 1
    rc=1
    if [ ! -f $TMP.out ]; then
      kill $job
    else
      rc=`cat $TMP.out`
    fi
    rm -f $TMP $TMP.out > /dev/null 2>&1
    exit $rc
  )
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=$rc
    chkmsg="${chkmsg}
Does not support > filename."
  fi

  if [ "$TSHELL" != "" ]; then
    # test for -n not supported.
    (
      rm -f $TMP $TMP.out > /dev/null 2>&1
      echo 'exit 1' > $TMP
      chmod a+rx $TMP
      cmd="$TSHELL -n $TMP;echo \$? > $TMP.out"
      eval $cmd &
      job=$!
      sleep 1
      rc=1
      if [ ! -f $TMP.out ]; then
        kill $job
      else
        rc=`cat $TMP.out`
      fi
      rm -f $TMP $TMP.out > /dev/null 2>&1
      exit $rc
    )
    rc=$?
    if [ $rc -ne 0 ]; then
      grc=$rc
      chkmsg="${chkmsg}
Does not support -n."
    fi
  fi

  return $grc
}

getlistofshells () {
  pthlist=`echo $PATH | sed 's/:/ /g'`
  ls -ld /bin | grep -- '->' > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    pthlist=`echo $pthlist | sed -e 's,^/bin ,,' -e 's, /bin ,,'`
  fi

  tshelllist=""
  for d in $pthlist; do
    for s in $tryshell ; do
      if [ -x $d/$s ]; then
        rs=`ls -l $d/$s | sed 's/.* //'`
        case $rs in
          /*)
            ;;
          *)
            rs=$d/$rs
            ;;
        esac
        if [ "$rs" != "$d/$s" ]; then
          rs=`ls -l $rs | sed 's/.* //'`
          case $rs in
            /*)
              ;;
            *)
              rs=$d/$rs
              ;;
          esac
        fi

        cmd="$rs -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
        shell=`eval $cmd`
        case $shell in
          pdksh)
            ;;
          *)
            tshelllist="${tshelllist}
$rs"
            ;;
        esac
      fi
    done
  done
  tshelllist=`echo "$tshelllist" | sort -u`

  systype=`uname -s`
  shelllist=""
  for s in $tshelllist; do
    # OSF1 /sbin/sh hangs on compilation.
    if [ "$systype" = "OSF1" -a "$s" = "/sbin/sh" ]; then
      continue
    fi
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;TSHELL=$s;chkshell\""
    eval $cmd
    if [ $? -eq 0 ]; then
      shelllist="${shelllist} $s"
    fi
  done
}
