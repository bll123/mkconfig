#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 1994-2010 Brad Lanam, Walnut Creek, CA
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - $TSTRUNLOG
#    8 - $MAINLOG
#    7 - $TMPORDER
#    5 - stdout (as 1 is directed to the log)
#

set -f # global

DOPERL=T
TESTORDER=test_order
SUBDIR=F

# this is a workaround for ksh93 on solaris
if [ "$1" = "-d" ]; then
  cd $2
  shift
  shift
fi
unset CDPATH

if [ "$1" = "-s" ]; then
  SUBDIR=T
  shift
  CC="$1"
  DC="$2"
  shelllist="$3"
  _pthlist="$4"
  TMPOUT="$5"
  shift; shift; shift; shift; shift
fi

if [ $# -lt 1 ]; then
  echo "Usage: $0 <test-dir> [<test-to-run> ...]"
  exit 1
fi

unset GREP_OPTIONS
unset ENV
unalias sed > /dev/null 2>&1
unalias grep > /dev/null 2>&1
unalias ls > /dev/null 2>&1
unalias rm > /dev/null 2>&1
LC_ALL=C
export LC_ALL

# this is used for regression testing.
getlistofshells () {

  getpaths
  echo "## PATH: $PATH" >&8
  echo "## paths: $_pthlist" >&8

  tshelllist=""
  inodelist=""
  for d in $_pthlist; do
    for s in $tryshell ; do
      rs=$d/$s
      if [ -f $rs ]; then
        if [ -h $rs ]; then
          while [ -h $rs ]; do
            rs="`ls -l $rs | sed 's/.* //'`"
            case $rs in
              /*)
                ;;
              *)
                rs="$d/$rs"
                ;;
            esac
            rs=`echo $rs | sed 's,/[^/]*/\.\./,/,'`
            rs=`echo $rs | sed 's,/[^/]*/\.\./,/,'`
            rs=`echo $rs | sed 's,/[^/]*/\.\./,/,'`
          done
        fi # if symlink

        inode=`ls -i ${rs} | sed 's/ .*//'`
        inode=${inode}${s}   # append shell type also
        found=F
        for i in $inodelist; do
          if [ "$inode" = "${i}" ]; then
            found=T
            break
          fi
        done
        if [ $found = T ]; then
          continue
        fi

        if [ -x $rs ]; then
          cmd="$rs -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype echo\""
          set `eval $cmd`
  	shell=$2
          echo "  found: $rs ($shell)" >&8
          case $shell in
            *)
              tshelllist="${tshelllist}
  $rs"
              inodelist="${inodelist}
  ${inode}"
              ;;
          esac
        fi # if executable
      fi  # if there is a file
    done
  done
  tshelllist=`echo "$tshelllist" | sort -u`

  systype=`uname -s`
  shelllist=""
  for s in $tshelllist; do
    echo ${EN} "  check $s${EC}" >&8
    echo ${EN} "   $s${EC}"
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;TSHELL=$s;chkshell echo\""
    eval $cmd >&8 2>&1
    rc=$?
    cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;TSHELL=$s;getshelltype echo\""
    set `eval $cmd`
    tbaseshell=$1
    tshell=$2
    shift;shift
    tdvers=$@
    if [ $rc -eq 0 ]; then
      echo " ok" >&8
      shelllist="${shelllist} $s"
      echo " [$tshell $tdvers] (ok)"
    else
      echo " ng" >&8
      echo " : $chkmsg" >&8
      echo " [$tshell $tdvers] (ng)"
    fi
  done
}

runshelltest () {
  stag=""
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    stag=".${scount}_${shell}"
  fi
  TSTRUNLOG=${_MKCONFIG_TSTRUNTMPDIR}/${tbase}.log${stag}
  > $TSTRUNLOG
  exec 9>>$TSTRUNLOG

  echo "####" >&9
  echo "# Test: $tbase $arg" >&9
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    echo "## testing with ${_MKCONFIG_SHELL} " >&9
  fi
  echo "# $dt" >&9
  echo "####" >&9

  cd $_MKCONFIG_TSTRUNTMPDIR
  if [ "$_MKCONFIG_SHELL" != "" ]; then
    echo ${EN} " ${ss}${EC}"
  fi
  targ=$arg
  if [ "$arg" != "" ]; then
    targ="$_MKCONFIG_DIR/$arg"
  fi
  # dup stdout to 5; redirect stdout to 9; redirect stderr to new 1.
  ${_MKCONFIG_SHELL} $_MKCONFIG_RUNTESTDIR/$tf "$stag" $targ 5>&1 >&9 2>&1
  rc=$?
  cd $_MKCONFIG_RUNTESTDIR

  dt=`date`
  echo "####" >&9
  echo "# $dt" >&9
  echo "# exit $rc" >&9
  echo "####" >&9
  exec 9>&-
  if [ $rc -ne 0 -a "$_MKCONFIG_SHELL" != "" ]; then
    echo ${EN} "*${EC}"
  fi
  return $rc
}

#
# main
#

_MKCONFIG_RUNTOPDIR=`pwd`
export _MKCONFIG_RUNTOPDIR
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
if [ "$mypath" = "runtests.sh" ]; then
  mypath=.
fi
_MKCONFIG_DIR=`(cd $mypath;pwd)`
export _MKCONFIG_DIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

_MKC_ONCE=0
export _MKC_ONCE
_MKC_SH=1
export _MKC_SH
_MKC_PL=2
export _MKC_PL
_MKC_SH_PL=3
export _MKC_SH_PL

doshelltest $0 $@
if [ $SUBDIR = "F" ]; then
  setechovars
  mkconfigversion
fi

testdir=$1
if [ ! -d $testdir ]; then
  echo "## Unable to locate $testdir"
  exit 1
fi

shift
teststorun=$*

cd $testdir
if [ $? != 0 ]; then
  echo "## Unable to cd to $testdir"
  exit 1
fi

_MKCONFIG_RUNTESTDIR=`pwd`
export _MKCONFIG_RUNTESTDIR

if [ $SUBDIR = "F" ]; then
  _MKCONFIG_RUNTMPDIR=$_MKCONFIG_RUNTOPDIR/_mkconfig_runtests
  export _MKCONFIG_RUNTMPDIR

  CC=${CC:-cc}
  export CC
  DC=${DC:-gdc}
  export DC
else
  btestdir=`echo $testdir | sed 's,.*/,,'`
  _MKCONFIG_RUNTMPDIR=$_MKCONFIG_RUNTOPDIR/_mkconfig_runtests/$btestdir
  export _MKCONFIG_RUNTMPDIR
fi

TMPORDER=test_order.tmp
> $TMPORDER
if [ "$teststorun" = "" ]; then
  if [ ! -f "$TESTORDER" ]; then
    ls -1d *.d *.sh 2>/dev/null | sed -e 's/\.sh$//' -e 's/^/1/' >> $TMPORDER
  else
    sort -n $TESTORDER >> $TMPORDER
  fi
else
  for t in $teststorun; do
    echo "1 $t"
  done >> $TMPORDER
fi

if [ $SUBDIR = "F" ]; then
  test -d $_MKCONFIG_RUNTMPDIR && rm -rf "$_MKCONFIG_RUNTMPDIR"
fi
test -d $_MKCONFIG_RUNTMPDIR || mkdir $_MKCONFIG_RUNTMPDIR

MAINLOG=${_MKCONFIG_RUNTMPDIR}/main.log
if [ $SUBDIR = "F" ]; then
  > $MAINLOG
fi
exec 8>>$MAINLOG

if [ $SUBDIR = "F" ]; then
  echo "## locating valid shells"
  getlistofshells
fi

locatecmd awkcmd awk
locatecmd nawkcmd nawk
locatecmd gawkcmd gawk
locatecmd mawkcmd mawk
if [ "$nawkcmd" != "" ]; then
  awkcmd=$nawkcmd
fi
if [ "$mawkcmd" != "" ]; then
  awkcmd=$mawkcmd
fi
if [ "$gawkcmd" != "" ]; then
  awkcmd=$gawkcmd
fi
echo "awk: $awkcmd" >&8

export shelllist
grc=0
count=0
fcount=0
fpass=0
lastpass=""
# save stdin in fd 7
exec 7<&0 < ${TMPORDER}
while read tline; do
  set $tline
  pass=$1
  tbase=$2
  if [ "$lastpass" = "" ]; then
    lastpass=$pass
  fi
  if [ $grc -ne 0 -a "$lastpass" != "$pass" ]; then
    if [ $SUBDIR = "F" ]; then
      echo "## stopping tests due to failures in $testdir/ pass $lastpass"
    else
      fpass=$lastpass
    fi
    echo "## stopping tests due to failures in $testdir/ pass $lastpass" >&8
    break
  fi

  if [ -d "$tbase" ]; then
    ocwd=`pwd`
    cd $_MKCONFIG_DIR
    TMPOUT=${_MKCONFIG_TSTRUNTMPDIR}/${tbase}.out
    ${_MKCONFIG_SHELL} ./runtests.sh -s "$CC" "$DC" "$shelllist" "$_pthlist" $TMPOUT $testdir/$tbase
    retvals=`tail -1 $TMPOUT`
    rm -f $TMPOUT > /dev/null 2>&1
    set $retvals
    retcount=$1
    retfcount=$2
    retfpass=$3
    domath count "$count + $retcount"
    domath fcount "$fcount + $retfcount"
    rc=$retfcount
    if [ $rc -ne 0 ]; then
      grc=$rc
      echo "## stopping tests due to failures in $testdir/$tbase/ pass $retfpass (pass $lastpass) "
      echo "## stopping tests due to failures in $testdir/$tbase/ pass $retfpass (pass $lastpass)" >&8
      break
    fi
    cd $ocwd
    continue
  fi

  tprefix=`echo $tbase | sed 's/-.*//'`
  if [ "${CC}" = "" -a "$tprefix" = "c" ]; then
    continue
  fi
  if [ "${DC}" = "" -a "$tprefix" = "d" ]; then
    continue
  fi
  tf="${tbase}.sh"
  tconfig="${tbase}.config"
  tconfh="${tbase}.ctmp"

  ok=T
  if [ ! -f ./$tf ]; then
    echo "$tbase ... missing ... failed"
    echo "$tbase ... missing ... failed" >&8
    ok=F
  elif [ ! -x ./$tf ]; then
    echo "$tbase ... permission denied ... failed"
    echo "$tbase ... permission denied ... failed" >&8
    ok=F
  fi
  if [ $ok = F ]; then
    domath fcount "$fcount + 1"
    domath count "$count + 1"
    continue
  fi

  dt=`date`
  arg="mkconfig.sh"

  scount=""
  echo ${EN} "$tbase ...${EC}"
  echo ${EN} "$tbase ...${EC}" >&8
  _MKCONFIG_TSTRUNTMPDIR=$_MKCONFIG_RUNTMPDIR/${tbase}
  export _MKCONFIG_TSTRUNTMPDIR
  mkdir ${_MKCONFIG_TSTRUNTMPDIR}
  if [ -f $tconfig ]; then
    cp $tconfig $_MKCONFIG_TSTRUNTMPDIR/$tconfh
  fi
  tfdisp=`$_MKCONFIG_RUNTESTDIR/$tf -d`
  echo ${EN} " ${tfdisp}${EC}"
  echo ${EN} " ${tfdisp}${EC}" >&8
  $_MKCONFIG_RUNTESTDIR/$tf -q
  runshpl=$?

  if [ $runshpl -eq $_MKC_SH -o $runshpl -eq $_MKC_SH_PL ]; then
    echo ${EN} " ...${EC}"
    echo ${EN} " ...${EC}" >&8
    src=0
    scount=1
    for s in $shelllist; do
      unset _shell
      unset shell
      cmd="$s -c \". $_MKCONFIG_DIR/shellfuncs.sh;getshelltype echo\""
      set `eval $cmd`
      ss=$2
      if [ "$ss" = "sh" ]; then
        ss=`echo $s | sed 's,.*/,,'`
      fi
      _MKCONFIG_SHELL=$s
      export _MKCONFIG_SHELL
      shell=$ss

      runshelltest
      rc=$?
      if [ $rc -ne 0 ]; then src=$rc; fi
      domath scount "$scount + 1"

      unset _shell
      unset shell
      unset _MKCONFIG_SHELL
    done
  else
    runshelltest
    src=$?
  fi

  if [ $src -ne 0 ]; then
    src=1
    grc=1
    if [ $tbase = "c-compiler" -a $grc -ne 0 ]; then
      CC=""
      grc=0
    fi
    if [ $tbase = "d-compiler" -a $grc -ne 0 ]; then
      DC=""
      grc=0
    fi
    if [ $grc -eq 0 ]; then
      echo " ... skipping $tprefix compiler tests"
      echo " skipping $tprefix compiler tests" >&8
    else
      echo " ... failed"
      echo " failed" >&8
      domath fcount "$fcount + 1"
    fi
  else
    echo " ... success"
    echo " success" >&8
  fi
  domath count "$count + 1"

  if [ "$DOPERL" = "T" -a \
       \( $runshpl -eq $_MKC_PL -o $runshpl -eq $_MKC_SH_PL \) ]; then
    _MKCONFIG_TSTRUNTMPDIR=$_MKCONFIG_RUNTMPDIR/${tbase}_pl
    export _MKCONFIG_TSTRUNTMPDIR
    mkdir ${_MKCONFIG_TSTRUNTMPDIR}
    TSTRUNLOG=$_MKCONFIG_TSTRUNTMPDIR/${tbase}.log
    > $TSTRUNLOG
    exec 9>>$TSTRUNLOG

    dt=`date`
    echo "####" >&9
    echo "# Test: $tf mkconfig.pl" >&9
    echo "# $dt" >&9
    echo "####" >&9
    echo ${EN} "$tbase ...${EC}"
    echo ${EN} "$tbase ...${EC}" >&8
    echo ${EN} " ${tfdisp}${EC}"
    echo ${EN} " ${tfdisp}${EC}" >&8
    echo ${EN} " ... perl${EC}"
    echo ${EN} " ... perl${EC}" >&8
    echo "## Using mkconfig.pl " >&9
    if [ -f $tconfig ]; then
      cp $tconfig $_MKCONFIG_TSTRUNTMPDIR/$tconfh
    fi

    cd $_MKCONFIG_TSTRUNTMPDIR
    # dup stdout to 5; redirect stdout to 9; redirect stderr to new 1.
    $_MKCONFIG_RUNTESTDIR/$tf none $_MKCONFIG_DIR/mkconfig.pl 5>&1 >&9 2>&1
    rc=$?
    cd $_MKCONFIG_RUNTESTDIR

    dt=`date`
    echo "####" >&9
    echo "# $dt" >&9
    echo "# exit $rc" >&9
    echo "####" >&9
    exec 9>&-
    if [ $rc -ne 0 ]; then
      echo " ... failed"
      echo " failed" >&8
      domath fcount "$fcount + 1"
      grc=1
    else
      echo " ... success"
      echo " success" >&8
    fi
    domath count "$count + 1"
  fi

  lastpass=$pass
done
# set std to saved fd 7; close 7
exec <&7 7<&-
test -f $TMPORDER && rm -f $TMPORDER

if [ $count -eq 0 ]; then  # this can't be right...
  $fcount = -1
fi

exec 8>&-

if [ $SUBDIR = "F" ]; then
  echo "$count tests $fcount failures"
  if [ $fcount -eq 0 ]; then
    if [ "$MKC_KEEP_RUN_TMP" = "" ]; then
      test -d "$_MKCONFIG_RUNTMPDIR" && rm -rf "$_MKCONFIG_RUNTMPDIR"
    fi
  fi
else
  echo "$count $fcount $fpass" > $TMPOUT
fi

exit $fcount
