#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA, USA
#

mkconfigversion () {
  read vers < ${MKCONFIG_DIR}/VERSION
  echo "mkconfig version ${vers}"
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

# some shells don't do character classes in conjunction
# with parameter substitution.
test_paramsub () {
  shhasparamsub=0
  ( eval 'x=bcb;y=${x/c/_};test z${y} = zb_b') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasparamsub=1
    eval 'dosubst () { subvar=$1; shift;
        while test $# -gt 0; do
        pattern=$1; sub=$2;
        eval $subvar=\${${subvar}//${pattern}/${sub}};
        shift; shift; done; }'
  else
    eval 'dosubst () { subvar=$1; shift; sa="";
      while test $# -gt 0; do pattern=$1; sub=$2; shift; shift;
      sa="${sa} -e \"s~${pattern}~${sub}~g\""; done;
      cmd="${subvar}=\`echo \${${subvar}} | sed ${sa}\`"; eval $cmd; }'
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
  test_paramsub
  test_math
  test_upper
}

getshelltype () {
  shell=${_shell:-sh}   # unknown or old
  baseshell=${_shell:-sh}
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

  if [ "$shell" = "sh" ]; then
    line=`ls -l /bin/sh | grep -- '->' 2>/dev/null`
    if [ "$line" != "" ]; then
      shell=`echo $line | sed -e 's,.* ,,' -e 's,.*/,,'`
      baseshell=$shell
    fi
  fi

  # $SHELL is not reset when a new shell or script
  # is started.  So it can't be depended upon to
  # determine which shell is running.  So only use
  # these tests if $SHELL = /bin/sh .
  if [ "$shell" = "sh" -a "$SHELL" = "/bin/sh" ]; then
    out=`$SHELL --version exit 2>&1`
    echo $out | grep 'bash' > /dev/null 2>&1
    if [ $? -eq 0 ]; then
      shell=bash
      baseshell=bash
    fi
    if [ "$shell" = "sh" ]; then
      echo $out | grep 'AT&T' > /dev/null 2>&1
      if [ $? -eq 0 ]; then
        shell=ksh
        baseshell=ksh
      fi
    fi
  fi
}

testshell () {
  rc=0

  if [ "$_shell" != "" ]; then
    return $rc
  fi

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
      cmd="/bin/sh -c \". $MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
      shell=`eval $cmd`
    fi
    rc=1
  else
    locatecmd wsh $baseshell
    SHELL=$wsh
  fi

  isbash=F
  case $shell in
    bash*)
      isbash=T
      ;;
  esac

  # bash is really slow, replace it if possible.
  noksh=0
  if [ $ok -eq 0 -o $isbash = "T" ]; then
    locatecmd wmksh mksh
    if [ "$wmksh" != "" ]; then
      SHELL=$wmksh
      shell=mksh
      rc=1
      noksh=0
    else
      noksh=1
    fi

    if [ $noksh -eq 1 ]; then
      locatecmd wksh ksh
      if [ "$wksh" != "" ]; then
        cmd="$wksh -c \". $MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
        tshell=`eval $cmd`
        case $tshell in
          pdksh)             # but not w/pdksh; some versions crash
            ;;
          ksh*)
            SHELL=$wksh
            shell=$tshell
            rc=1
            noksh=0
            ;;
        esac
      fi
    fi

    # any of these are fine...no preference
    if [ $noksh -eq 1 -a -x /bin/dash ]; then
      SHELL=/bin/dash
      shell=dash
      rc=1
    elif [ $noksh -eq 1 -a -x /bin/ash ]; then
      SHELL=/bin/ash
      shell=ash
      rc=1
    elif [ $noksh -eq 1 -a -x /bin/posh ]; then
      SHELL=/bin/ash
      shell=ash
      rc=1
    elif [ $noksh -eq 1 -a -x /bin/sh ]; then
      SHELL=/bin/sh
      shell=sh
      rc=1
    fi
  fi

  export SHELL
  return $rc
}

doshelltest () {
  dstscript=$1
  shift

  getshelltype
  testshell
  if [ $? != 0 ]; then
    _shell=$shell
    export _shell
    exec $SHELL $dstscript $@
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

getlistofshells () {
  dlist=""
  ls -ld /bin | grep -- '->' > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    dlist=/bin
  fi
  dlist="${dlist} /usr/bin /usr/local/bin"

  shelllist=""
  for d in $dlist; do
    for s in sh bash posh ash dash mksh ksh; do
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

        cmd="$wksh -c \". $MKCONFIG_DIR/shellfuncs.sh;getshelltype;echo \\\$shell\""
        shell=`eval $cmd`
        case $shell in
          pdksh)
            ;;
          *)
            shelllist="${shelllist}
$rs"
            ;;
        esac
      fi
    done
  done
  shelllist=`echo "$shelllist" | sort -u`
}
