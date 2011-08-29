#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA, USA
#

read _MKCONFIG_VERSION < ${_MKCONFIG_DIR}/VERSION
export _MKCONFIG_VERSION

# posh set command doesn't output correct data; don't bother with it.
# yash has quoting/backquote issues
# zsh is not bourne shell compatible
#   set | grep can be fixed with: set | strings | grep
#   and 'emulate ksh' can be set in mkconfig.sh, but there
#   are more issues, and I'm not interested in tracking them down.
tryshell="ash bash dash ksh mksh pdksh sh sh5"

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
  (eval 'typeset -u xuvar;xuvar=x;test z$xuvar = zX') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasupper=1
    eval 'toupper () { ucvar=$1; typeset -u uval; eval "uval=\${$ucvar};$ucvar=\$uval"; }'
  else
    eval 'toupper () { ucvar=$1; cmd="$ucvar=\`echo \${$ucvar} | tr \"[a-z]\" \"[A-Z]\"\`"; eval "$cmd"; }'
  fi
}

test_lower () {
  shhaslower=0
  (eval 'typeset -l xuvar;xuvar=X;test z$xuvar = zx') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhaslower=1
    eval 'tolower () { lcvar=$1; typeset -l lval; eval "lval=\${$lcvar};$lcvar=\$lval"; }'
  else
    eval 'tolower () { lcvar=$1; cmd="$lcvar=\`echo \${$lcvar} | tr \"[A-Z]\" \"[a-z]\"\`"; eval "$cmd"; }'
  fi
}

testshcapability () {
  test_append
  test_math
  test_upper
  test_lower
}

getshelltype () {
  doecho=F
  if [ "$1" = "echo" ]; then
    doecho=T
  fi

  shell=${_shell:-sh}   # unknown or old
  baseshell=${_shell:-sh}
  ( eval 'echo ${.sh.version}' ) >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    eval 'KSH_VERSION=${.sh.version}'
  fi
  if [ "$KSH_VERSION" != "" ]; then
    shell=ksh
    baseshell=ksh
    dvers=$KSH_VERSION
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
    dvers=$BASH_VERSION
    ver=`echo $BASH_VERSION | sed 's/\..*//'`
    shell=bash${ver}
  elif [ "$ZSH_VERSION" != "" ]; then
    baseshell=zsh
    dvers=$ZSH_VERSION
    shell=zsh
  elif [ "$POSH_VERSION" != "" ]; then
    baseshell=posh
    dvers=$POSH_VERSION
    shell=posh
  elif [ "$YASH_VERSION" != "" ]; then
    baseshell=yash
    dvers=$YASH_VERSION
    shell=yash
  fi

  # can try --version, but don't really know the path
  # of the shell running us; can't depend on $SHELL.
  # and it only works for bash and some versions of ksh.
  if [ $doecho = "T" ]; then
    echo $baseshell $shell $dvers
  fi
}

doshelltest () {
  # force shell type.
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    if [ "$SHELL" != "$_MKCONFIG_SHELL" ]; then
      SHELL="$_MKCONFIG_SHELL"
      export SHELL
      loc=`pwd`
      s=$1
      shift
      exec $SHELL $dstscript $s -d $loc $@
    fi
  fi

  getshelltype

  chkshell
  if [ $? -ne 0 ]; then
    echo "The shell in use ($shell) does not have the correct functionality:" >&2
    echo $chkmsg >&2
    echo "Please try another shell.
_MKCONFIG_SHELL can be set to the path of another shell
to override /bin/sh." >&2
    exit 1
  fi
  testshcapability
}

locatecmd () {
  lvar=$1
  ltcmd=$2

  getpaths

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
  doecho=F
  if [ "$1" = "echo" ]; then
    doecho=T
  fi

  grc=0

  TMP=chksh$$
  chkmsg=""
  # test to make sure the set command works properly
  # some shells output xyzzy=abc def
  # some shells output xyzzy='abc def'
  # some shells output xyzzy=$'abc def' (ok; handled in mkconfig.sh)
  # yash does this correctly, but has quoting/backquote issues
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
  'set' output not x=a b or x='a b' or x=\$'a b'."
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

  if [ $doecho = "T" ]; then
    echo $chkmsg
  fi

  return $grc
}

getpaths () {
  if [ "$_pthlist" != "" ]; then
    return
  fi

  systype=`uname -s`
  tpthlist=`echo $PATH | sed 's/:/ /g'`

  # cygwin's /bin and /usr/bin are both mounted on same spot
  case ${systype} in
    CYGWIN*)
      d=/bin
      tpthlist=`echo $tpthlist | sed -e "s,^$d ,," -e "s, $d,,"`
      ;;
  esac

  # remove symlinks
  for d in $tpthlist; do
    if [ ! -d $d ]; then
      tpthlist=`echo $tpthlist | sed -e "s,^$d ,," -e "s, $d,,"`
    else
      if [ -h $d ]; then
        tpthlist=`echo $tpthlist | sed -e "s,^$d ,," -e "s, $d,,"`
        # make sure path symlink is pointing to is in the list
        npath=`ls -ld $d | sed 's/.*-> //'`
        tpthlist="$tpthlist $npath"
      fi
    fi
  done

  # remove dups
  _pthlist=""
  for d in $tpthlist; do
    _pthlist="$_pthlist
$d"
  done
  _pthlist=`echo $_pthlist | sort -u`
}

initifs () {
  hasifs=0
  if [ "$IFS" != "" ]; then
    OIFS="$IFS"
    hasifs=1
  fi
}

setifs () {
  # just newline for parsing include section
  IFS="
"
}

resetifs () {
  if [ $hasifs -eq 1 ]; then
    IFS="$OIFS"
  else
    unset IFS
  fi
}

boolclean () {
  nm=$1

  dosubst $nm '(' ' ( ' ')' ' ) '
  dosubst $nm ' not ' ' ! ' ' and ' ' -a ' ' or ' ' -o '
  dosubst $nm '!' ' ! ' '&&' ' -a ' '||' ' -o '
  dosubst $nm ' \+' ' ' '^ *' '' ' *$' ''
}
