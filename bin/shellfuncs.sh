#!/bin/sh
#
# Copyright 2010-2018 Brad Lanam Walnut Creek, CA, USA
#

if [ ! -f "${_MKCONFIG_DIR}/VERSION" ]; then
  echo "Unable to locate ${_MKCONFIG_DIR}/VERSION."
  echo "Not a valid mkconfig installation."
  exit 1
fi

# dash on Mandriva 2011 segfaults intermittently when:
#   read _MKCONFIG_VERSION < ${_MKCONFIG_DIR}/VERSION
#   export _MKCONFIG_VERSION
# was used.
_MKCONFIG_VERSION=`cat ${_MKCONFIG_DIR}/VERSION`
export _MKCONFIG_VERSION

# posh set command doesn't output correct data; don't bother with it.
# older yash has quoting/backquote issues (what version did this get fixed?)
# zsh is not bourne shell compatible
#   set | grep can be fixed (nulls are output) with: set | strings | grep
#   and 'emulate ksh' can be set in mkconfig.sh, but there
#   are more issues, and I'm not interested in tracking them down.
tryshell="ash bash bash2 bash3 bash4 bash5 dash ksh ksh88 ksh93 mksh pdksh sh sh5 osh yash"

mkconfigversion () {
  echo "mkconfig version ${_MKCONFIG_VERSION}"
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

test_echo () {
  shhasprintf=0
  (eval 'printf %s hello >/dev/null') 2>/dev/null
  rc=$?
  # Virtually all shells have printf.
  # I had not known it was supported so far back -- most
  # everything used echo, and printf was not mentioned much.
  # 'printf' is POSIX compliant.
  if [ $rc -eq 0 ]; then
    shhasprintf=1
    eval 'putsnonl () { printf '%s' "$*"; }'
    eval 'puts () { printf "%s\n" "$*"; }'
  fi

  #
  # Tru64 sh has some weird bugs.
  # Not sure where the bug occurs -- probably both 'echo' and 'read',
  # and they cancel other out.
  # Backslash interpolation with echo and single quotes has issues.
  # Apparently I didn't code anything that ran into that problem.
  #
  # The read/printf combo fails due to differences from read/echo.
  #
  # 2019-6-26: Apparently some older ksh93 also have this issue.
  #
  # $ echo "a \\ b"
  # a \ b
  # $ printf "%s\n" "a \\ b"
  # a \ b
  # $ cat tt
  # a \\ b
  # $ read tdat < tt
  # $ echo "$tdat"
  # a \ b
  # $ printf "%s\n" "$tdat"
  # a \\ b              # should be: a \ b
  # $ echo 'a \\ b'
  # a \ b               # should be: a \\ b
  # $ printf "%s\n" 'a \\ b'
  # a \\ b
  # $
  #

  # Test for interpolation bugs.
  # If bugs are present, use 'echo'.
  tz="a \\\\ b"            # should interpolate as: a \\ b
  t1=`echo "$tz"`          # and both of these should return: a \\ b
  t2=`printf '%s\n' "$tz"`
  # have to test against the original in order to catch the change
  if [ \( "$tz" != "$t1" \) -o \( "$tz" != "$t2" \) ]; then
    shhasprintf=0
  fi

  # 'echo' works everywhere, but is not a POSIX compliant command.
  # Have not found any bourne compatible shell that does not support
  # either -n or \c.
  if [ $shhasprintf -eq 0 ]; then
    _tEN='-n'
    _tEC=''
    if [ "`echo -n test`" = "-n test" ]; then
      _tEN=''
      _tEC='\c'
    fi
    eval 'putsnonl () { echo ${_tEN} "$*${_tEC}"; }'
    eval 'puts () { echo "$*"; }'
  fi
}

# The += form is much, much faster and less prone to errors.
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

test_readraw () {
  shreqreadraw=0
  # unixware 7.14 compiles and runs this code ok, but it's shell gets
  # completely wacked out later.  So run it in a subshell.
  # (similar to mandriva 2011 problem with read < file)
  (
    rrv='aa\\\\bb'
    read rrx << _HERE_
$rrv
_HERE_
    (
      eval "read -r rry <<_HERE_
$rrv
_HERE_"
    ) 2>/dev/null
    yrc=$?
    if [ $yrc -eq 0 ]; then
      read -r rry << _HERE_
$rrv
_HERE_
      if [ "${rrx}" != 'aa\\bb' -a "${rry}" = 'aa\\\\bb' ]; then
        shreqreadraw=1
      fi
    fi
    exit $shreqreadraw
  )
  shreqreadraw=$?
}

# use the faster method $((expr)) if possible.
test_math () {
  shhasmath=0
  (eval 'x=1;w=0+1;y=$(($x+1));v=$(($w)); test z$y = z2 -a z$v = z1 ') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasmath=1
    eval 'domath () { mthvar=$1; mthval=$(($2)); eval $mthvar=$mthval; }'
  else
    eval 'domath () { mthvar=$1; mthval=`expr $2`; eval $mthvar=$mthval; }'
  fi
}

# use the faster shell built-in if possible.
test_upper () {
  shhasupper=0
  (eval 'typeset -u xuvar;xuvar=x;test z$xuvar = zX') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhasupper=1
    eval 'toupper () { ucvar=$1; typeset -u ucval; eval "ucval=\${$ucvar};$ucvar=\$ucval"; }'
  else
    eval 'toupper () { ucvar=$1; cmd="$ucvar=\`echo \${$ucvar} | tr \"[a-z]\" \"[A-Z]\"\`"; eval "$cmd"; }'
  fi
}

# use the faster shell built-in if possible.
test_lower () {
  shhaslower=0
  (eval 'typeset -l xuvar;xuvar=X;test z$xuvar = zx') 2>/dev/null
  if [ $? -eq 0 ]; then
    shhaslower=1
    eval 'tolower () { lcvar=$1; typeset -l lcval; eval "lcval=\${$lcvar};$lcvar=\$lcval"; }'
  else
    eval 'tolower () { lcvar=$1; cmd="$lcvar=\`echo \${$lcvar} | tr \"[A-Z]\" \"[a-z]\"\`"; eval "$cmd"; }'
  fi
}

testshcapability () {
  test_echo
  test_append
  test_readraw
  test_math
  test_upper
  test_lower
}

getshelltype () {
  if [ "$1" != "" ]; then
    trs=$1
    shift
  fi
  gstecho=F
  if [ "$1" = echo ]; then
    gstecho=T
  fi

  baseshell=${_shell:-sh} # unknown or old
  shell=${_shell:-sh}     # unknown or old
  if [ "$trs" != "" ]; then
    dispshell=`echo $trs | sed -e 's,.*/,,'`
  else
    dispshell=$shell
  fi
  ( eval 'echo ${.sh.version}' ) >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    eval 'KSH_VERSION=${.sh.version}'
  fi
  if [ "$KSH_VERSION" != "" ]; then
    shell=ksh
    baseshell=ksh
    shvers=$KSH_VERSION
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
    shvers=$BASH_VERSION
    ver=`echo $BASH_VERSION | sed 's/\..*//'`
    shell=bash${ver}
    baseshell=bash
  elif [ "$ZSH_VERSION" != "" ]; then
    shvers=$ZSH_VERSION
    shell=zsh
    baseshell=zsh
  elif [ "$POSH_VERSION" != "" ]; then
    shvers=$POSH_VERSION
    shell=posh
    baseshell=posh
  elif [ "$YASH_VERSION" != "" ]; then
    shvers=$YASH_VERSION
    shell=yash
    baseshell=yash
  elif [ "$OIL_VERSION" != "" ]; then
    shvers=$OIL_VERSION
    shell=osh
    baseshell=osh
  fi

  if [ $dispshell = sh -a $dispshell != $shell ]; then
    dispshell="$dispshell-$shell"
  elif [ $dispshell = $baseshell ]; then
    dispshell=$shell
  fi
  # can try --version, but don't really know the path
  # of the shell running us; can't depend on $SHELL.
  # and it only works for bash and some versions of ksh.
  if [ $gstecho = T ]; then
    echo $dispshell $shvers
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

  getshelltype  # for display of error below
  chkshell "" $shell
  if [ $? -ne 0 ]; then
    echo "The shell in use ($dispshell) does not have the correct functionality:" >&2
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
  shellpath=$2

  grc=0

  case $shellpath in
    *yash)
      # reject older versions of yash
      # I do not know in what version the quoting/backquoting issues
      # got fixed.
      rc=`"$YASH_VERSION < 2.48" | bc -l`
      if [ $rc -eq 0 ]; then
        chkmsg="${chkmsg}
  older versions of yash are not supported"
        grc=1
      fi
      ;;
  esac

  chkmsg=""
  # test to make sure the set command works properly
  # some shells output xyzzy=abc def
  # some shells output xyzzy='abc def'
  # some shells output xyzzy=$'abc def' (ok; handled in mkconfig.sh)
  # yash does this correctly, but had quoting/backquote issues in older versions.
  (
    cmd='xyzzy="abc def"; val=`set | grep "^xyzzy"`; test "$val" = "xyzzy=abc def"'
    eval $cmd 2>/dev/null
    if [ $? -eq 0 ]; then
      exit 0
    fi
    cmd="xyzzy=\"abc def\"; val=\`set | grep \"^xyzzy\"\`; test \"\$val\" = \"xyzzy='abc def'\" -o \"\$val\" = \"xyzzy=\\$'abc def'\""
    eval $cmd 2>/dev/null
    rc=$?
    exit $rc
  )
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=$rc
    chkmsg="${chkmsg}
  'set' output not x=a b or x='a b' or x=\$'a b'."
  fi

  # test to make sure the 'set -f' command is supported.
  (
    cmd='set -f'
    eval $cmd 2>/dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      exit 0
    fi
    exit $rc
  )
  rc=$?
  if [ $rc -ne 0 ]; then
    grc=$rc
    chkmsg="${chkmsg}
  'set -f' not supported"
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
