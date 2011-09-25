#!/bin/sh
#
# $Id$
#
# Copyright 2009-2010 Brad Lanam Walnut Creek, CA USA
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - >>$LOG                     (mkconfig.sh)
#    8 - >>$VARSFILE, >>$CONFH      (mkconfig.sh)
#    7 - saved stdin                (mkconfig.sh)
#    6 - temporary                  (c-main.sh, mkconfig.sh)
#    4 - temporary                  (c-main.sh)
#

set -f  # set this globally.

# this is a workaround for ksh93 on solaris
if [ "$1" = "-d" ]; then
  cd $2
  shift
  shift
fi
unset CDPATH
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
_MKCONFIG_DIR=`(cd $mypath;pwd)`
export _MKCONFIG_DIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

doshelltest $0 $@
setechovars

LOG="mkconfig.log"
_MKCONFIG_TMP="_tmp_mkconfig"
CACHEFILE="mkconfig.cache"
OPTIONFILE="options.dat"
_MKCONFIG_PREFIX=mkc    # need a default in case no units loaded
optionsloaded=F

INC="mkcinclude.txt"                   # temporary

_chkconfigfname () {
  if [ "$CONFH" = "" ]; then
    echo "Config file name not set.  Exiting."
    _exitmkconfig 1
  fi
}

_exitmkconfig () {
    rc=$1
    exit $rc
}

_savecache () {
    # And save the data for re-use.
    # Some shells don't quote the values in the set
    # command like bash does.  So we do it.
    # Then we have to undo it for bash.
    # Other shells do: x=$''; remove the $
    # And then there's: x='', which gets munged.
    set | grep "^mkc_" | \
      sed -e "s/=/='/" -e "s/$/'/" -e "s/''/'/g" \
      -e "s/='$/=''/" -e "s/='\$'/='/" \
      > ${CACHEFILE}
}

setdata () {
    prefix=$1
    sdname=$2
    sdval=$3

    if [ "$_MKCONFIG_EXPORT" = "T" ]; then
      _doexport $sdname "$sdval"
    fi

    if [ $varsfileopen = "F" ]; then
      exec 8>>$VARSFILE
      varsfileopen=T
    fi
    cmd="test \"X\$mkc_${prefix}_${sdname}\" != X > /dev/null 2>&1"
    eval $cmd
    rc=$?
    # if already in the list of vars, don't add it again.
    if [ $rc -ne 0 ]; then
      if [ "$_MKCONFIG_HASEMPTY" = "T" ]; then
        # have to check again, as empty vars don't work for the above test.
        # need a better way to do this.
        grep -l "^${sdname}\$" $VARSFILE > /dev/null 2>&1
        rc=$?
      fi
      if [ $rc -ne 0 ]; then
        echo ${sdname} >&8
      fi
    fi
    cmd="mkc_${prefix}_${sdname}=\"${sdval}\""
    eval $cmd
    echo "   set: $cmd" >&9
}

getdata () {
    var=$1
    prefix=$2
    gdname=$3

    cmd="${var}=\${mkc_${prefix}_${gdname}}"
    eval $cmd
}

_setifleveldisp () {
  ifleveldisp=""
  for il in $iflevels; do
    ifleveldisp="${il}${ifleveldisp}"
  done
  if [ "$ifleveldisp" != "" ]; then
    doappend ifleveldisp " "
  fi
}

printlabel () {
  tname=$1
  tlabel=$2

  echo "   $ifleveldisp[${tname}] ${tlabel} ... " >&9
  echo ${EN} "${ifleveldisp}${tlabel} ... ${EC}" >&1
}

_doexport () {
  var=$1
  val=$2

  cmd="${var}=\"${val}\""
  eval $cmd
  cmd="export ${var}"
  eval $cmd
}

printyesno_actual () {
  ynname=$1
  ynval=$2
  yntag=${3:-}

  echo "   [${ynname}] $ynval ${yntag}" >&9
  echo "$ynval ${yntag}" >&1
}

printyesno_val () {
  ynname=$1
  ynval=$2
  yntag=${3:-}

  if [ "$ynval" != "0" ]; then
    printyesno_actual "$ynname" "$ynval" "${yntag}"
  else
    printyesno_actual "$ynname" no "${yntag}"
  fi
}

printyesno () {
    ynname=$1
    ynval=$2
    yntag=${3:-}

    if [ "$ynval" != "0" ]; then
      ynval=yes
    fi
    printyesno_val "$ynname" $ynval "$yntag"
}

checkcache_actual () {
  prefix=$1
  tname=$2

  getdata tval ${prefix} ${tname}
  rc=1
  if [ "$tval" != "" ]; then
    printyesno_actual $tname "$tval" " (cached)"
    rc=0
  fi
  return $rc
}

checkcache_val () {
  prefix=$1
  tname=$2

  getdata tval ${prefix} ${tname}
  rc=1
  if [ "$tval" != "" ]; then
    printyesno_val $tname "$tval" " (cached)"
    rc=0
  fi
  return $rc
}

checkcache () {
  prefix=$1
  tname=$2

  getdata tval ${prefix} ${tname}
  rc=1
  if [ "$tval" != "" ]; then
    printyesno $tname $tval " (cached)"
    rc=0
  fi
  return $rc
}

_loadoptions () {
  if [ $optionsloaded = "F" -a -f "${OPTIONFILE}" ]; then
    exec 6<&0 < ${OPTIONFILE}
    while read o; do
      case $o in
        "")
          continue
          ;;
        \#*)
          continue
          ;;
      esac

      topt=`echo $o | sed 's/=.*//'`
      tval=`echo $o | sed 's/.*=//'`
      eval "_mkc_opt_${topt}=\"${tval}\""
    done
    exec <&6 6<&-
    optionsloaded=T
  fi
}

check_command () {
    name=$1
    ccmd=$2

    printlabel $name "command: ${ccmd}"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    locatecmd trc $ccmd
    if [ "$trc" = "" ]; then trc=0; fi
    printyesno $name $trc
    setdata ${_MKCONFIG_PREFIX} ${name} ${trc}
}

check_ifoption () {
    ifdispcount=$1
    type=$2
    name=$3
    oopt=$4

    printlabel $name "$type ($ifdispcount): ${oopt}"

    _loadoptions
    trc=F  # if option is not set, it's false

    found=F
    if [ "$optionsloaded" = "T" ]; then
      eval tval=\$_mkc_opt_${oopt}
      if [ "$tval" != "" ]; then
        found=T
        trc=$tval
        tolower trc
        echo "  found: $oopt $trc" >&9
        if [ "$trc" = "t" ]; then trc=T; fi
        if [ "$trc" = "enable" ]; then trc=T; fi
        if [ "$trc" = "f" ]; then trc=F; fi
        if [ "$trc" = "disable" ]; then trc=F; fi
        if [ "$trc" = "true" ]; then trc=T; fi
        if [ "$trc" = "false" ]; then trc=F; fi
      fi
    fi

    if [ "$trc" = "T" ]; then trc=1; fi
    if [ "$trc" = "F" ]; then trc=0; fi

    if [ $type = "ifnotoption" ]; then
      if [ $trc -eq 0 ]; then trc=1; else trc=0; fi
    fi
    if [ "$optionsloaded" = "F" ]; then
      trc=0
      printyesno_actual $name "no options file"
    elif [ "$found" = "F" ]; then
      trc=0
      printyesno_actual $name "option not found"
    else
      printyesno $name $trc
    fi
    return $trc
}

check_if () {
    iflabel=$1
    ifdispcount=$2
    ifline=$3

    name=$iflabel
    printlabel $name, "if ($ifdispcount): $iflabel";

    boolclean ifline
    echo "## ifline: $ifline" >&9

    trc=0  # if option is not set, it's false

    nline="test "
    ineq=0
    qtoken=""
    quoted=0
    for token in $ifline; do
      echo "## token: $token" >&9

      case $token in
        \'*\')
          token=`echo $token | sed -e s,\',,g`
          echo "## begin/end quoted token" >&9
          ;;
        \'*)
          qtoken=$token
          echo "## begin qtoken: $qtoken" >&9
          quoted=1
          continue
          ;;
      esac

      if [ $quoted -eq 1 ]; then
        case $token in
          *\')
            token="${qtoken} $token"
            token=`echo $token | sed -e s,\',,g`
            echo "## end qtoken: $token" >&9
            quoted=0
            ;;
          *)
            qtoken="$qtoken $token"
            echo "## in qtoken: $qtoken" >&9
            continue
            ;;
        esac
      fi

      if [ $ineq -eq 1 ]; then
        ineq=2
        getdata tvar ${_MKCONFIG_PREFIX} $token
      elif [ $ineq -eq 2 ]; then
        doappend nline " ( '$tvar' = '$token' )"
        ineq=0
      else
        case $token in
          ==)
            ineq=1
            ;;
          \(|\)|-a|-o|!)
            doappend nline " $token"
            ;;
          *)
            getdata tvar ${_MKCONFIG_PREFIX} $token
            if [ "$tvar" != "0" ]; then tvar=1; fi
            tvar="( $tvar = 1 )"
            doappend nline " $tvar"
          ;;
        esac
      fi
    done

    if [ "$ifline" != "" ]; then
      dosubst nline '(' '\\\\\\(' ')' '\\\\\\)'
      echo "## nline: $nline" >&9
      eval $nline
      trc=$?
      echo "## eval nline: $trc" >&9
      # replace w/ shell return
      if [ $trc -eq 0 ]; then trc=1; else trc=0; fi
      echo "## eval nline final: $trc" >&9
    fi

    texp=$_MKCONFIG_EXPORT
    _MKCONFIG_EXPORT=F
    printyesno "$name" $trc
    _MKCONFIG_EXPORT=$texp
    return $trc
}

check_set () {
  nm=$1
  type=$2
  sval=$3

  name=$type
  tnm=$1
  dosubst tnm '_setint_' '' '_setstr' ''

  printlabel $name "${type}: ${tnm}"
  if [ "$type" = "set" ]; then
    getdata tval ${prefix} ${nm}
    if [ "$tval" != "" ]; then
      printyesno $nm "${sval}"
      setdata ${_MKCONFIG_PREFIX} ${nm} "${sval}"
    else
      printyesno_actual $nm "no such variable"
    fi
  elif [ "$type" = "setint" ]; then
    printyesno_actual $nm "${sval}"
    setdata ${_MKCONFIG_PREFIX} ${nm} "${sval}"
  else
    printyesno_actual $nm "${sval}"
    setdata ${_MKCONFIG_PREFIX} ${nm} "${sval}"
  fi
}

check_option () {
  nm=$1
  onm=$2
  def=$3

  name=$nm

  _loadoptions

  oval=$def
  printlabel $name "option: ${onm}"

  if [ "$optionsloaded" = "T" ]; then
    eval tval=\$_mkc_opt_${onm}
    if [ "$tval" != "" ]; then
      found=T
      echo "  found: $onm $tval" >&9
      oval="$tval"
    fi
  fi
  printyesno_actual $nm "$oval"
  setdata ${_MKCONFIG_PREFIX} ${nm} "${oval}"
}

check_echo () {
  val=$1

  echo "## echo: $val" >&9
  echo "$val" >&1
}

check_exit () {
  echo "## exit" >&9
  _exitmkconfig 5
}

_doloadunit () {
  lu=$1
  dep=$2
  if [ "$dep" = "Y" ]; then
   slu=${lu}
   tag=" (dependency)"
  fi
  if [ -f ${_MKCONFIG_DIR}/mkconfig.units/${lu}.sh ]; then
    echo "load-unit: ${lu} ${tag}" >&1
    echo "   found ${lu} ${tag}" >&9
    . ${_MKCONFIG_DIR}/mkconfig.units/${lu}.sh
    tlu=$lu
    dosubst tlu '-' '_'
    eval "_MKCONFIG_UNIT_${tlu}=Y"
  fi
  if [ "$dep" = "Y" ]; then
    lu=$slu
    tag=""
  fi
}

require_unit () {
  units=$@
  for rqu in $units; do
    trqu=$rqu
    dosubst trqu '-' '_'
    cmd="val=\$_MKCONFIG_UNIT_${trqu}"
    eval $cmd
    if [ "$val" = "Y" ]; then
      echo "   required unit ${rqu} already loaded" >&9
      continue
    fi
    echo "   required unit ${rqu} needed" >&9
    _doloadunit $rqu Y
  done
}

_create_output () {

  if [ ${CONFH} != "none" ]; then
    > ${CONFH}
    exec 8>>${CONFH}
    preconfigfile ${CONFH} >&8

    exec 6<&0 < $VARSFILE
    while read cfgvar; do
      getdata val ${_MKCONFIG_PREFIX} $cfgvar
      output_item ${CONFH} ${cfgvar} "${val}" >&8
    done
    exec <&6 6<&-

    stdconfigfile ${CONFH} >&8
    cat $INC >&8
    postconfigfile ${CONFH} >&8
    exec 8>&-

    output_other ${CONFH}
  fi
}

main_process () {
  configfile=$1

  reqlibs=""

  if [ -f "$CACHEFILE" ]; then
    . $CACHEFILE
  fi

  reqhdr=""

  inproc=0
  ininclude=0
  doproclist=""
  doproc=1
  linenumber=0
  ifstmtcount=0
  ifleveldisp=""
  iflevels=""
  initifs
  > $INC
  case ${configfile} in
    /*)
      ;;
    *)
      configfile="../${configfile}"
      ;;
  esac
  # save stdin in fd 7.
  # and reset stdin to get from the configfile.
  # this allows us to run the while loop in the
  # current shell rather than a subshell.

  # default varsfile.
  # a main loadunit will override this.
  # but don't open it unless it is needed.
  varsfiledflt=T
  varsfileopen=F
  if [ "$VARSFILE" = "" -a "${_MKCONFIG_PREFIX}" != "" ]; then
    VARSFILE="../mkconfig_${_MKCONFIG_PREFIX}.vars"
  fi

  # save stdin in fd 7; open stdin
  exec 7<&0 < ${configfile}
  while read tdatline; do
    resetifs
    domath linenumber "$linenumber + 1"

    if [ $ininclude -eq 1 ]; then
        if [ "${tdatline}" = "endinclude" ]; then
          echo "#### ${linenumber}: ${tdatline}" >&9
          ininclude=0
          resetifs
        else
          echo "${tdatline}" >> $INC
        fi
    else
        case ${tdatline} in
            "")
                continue
                ;;
            \#*)
                continue
                ;;
            *)
                echo "#### ${linenumber}: ${tdatline}" >&9
                ;;
        esac
    fi

    if [ $ininclude -eq 0 ]; then
      case ${tdatline} in
        "else")
          if [ $doproc -eq 0 ]; then doproc=1; else doproc=0; fi
          set -- $iflevels
          shift
          iflevels=$@
          iflevels="-$ifstmtcount $iflevels"
          _setifleveldisp
          echo "## else iflevels: $iflevels" >&9
          ;;
        "endif")
          set $doproclist
          c=$#
          if [ $c -gt 0 ]; then
            echo "## doproclist: $doproclist" >&9
            doproc=$1
            shift
            doproclist=$@
            echo "## doproc: $doproc doproclist: $doproclist" >&9
            set -- $iflevels
            shift
            iflevels=$@
            _setifleveldisp
            echo "## endif iflevels: $iflevels" >&9
          else
            doproc=1
            ifleveldisp=""
            iflevels=""
          fi
          ;;
      esac

      if [ $doproc -eq 1 ]; then
        case ${tdatline} in
          command*)
            _chkconfigfname
            set $tdatline
            cmd=$2
            nm="_command_${cmd}"
            check_command ${nm} ${cmd}
            ;;
          "echo"*)
            _chkconfigfname
            set $tdatline
            shift
            val=$@
            check_echo "${val}"
            ;;
          "exit")
            check_exit
            ;;
          endinclude)
            ;;
          ifoption*|ifnotoption*)
            _chkconfigfname
            set $tdatline
            type=$1
            opt=$2
            nm="_${type}_${opt}"
            domath ifstmtcount "$ifstmtcount + 1"
            check_ifoption $ifstmtcount $type ${nm} ${opt}
            rc=$?
            iflevels="+$ifstmtcount $iflevels"
            _setifleveldisp
            echo "## ifopt iflevels: $iflevels" >&9
            doproclist="$doproc $doproclist"
            doproc=$rc
            echo "## doproc: $doproc doproclist: $doproclist" >&9
            ;;
          "if "*)
            _chkconfigfname
            set $tdatline
            shift
            label=$1
            shift
            ifline=$@
            domath ifstmtcount "$ifstmtcount + 1"
            check_if $label $ifstmtcount "$ifline"
            rc=$?
            iflevels="+$ifstmtcount $iflevels"
            _setifleveldisp
            echo "## if iflevels: $iflevels" >&9
            doproclist="$doproc $doproclist"
            doproc=$rc
            echo "## doproc: $doproc doproclist: $doproclist" >&9
            ;;
          "else")
            ;;
          "endif")
            ;;
          include)
            _chkconfigfname
            ininclude=1
            ;;
          loadunit*)
            set $tdatline
            type=$1
            file=$2
            _doloadunit ${file} N
            if [ "$varsfiledflt" = "T" -a "${_MKCONFIG_PREFIX}" != "" ]; then
              VARSFILE="../mkconfig_${_MKCONFIG_PREFIX}.vars"
              varsfiledflt=F
            fi
            exec 8>>$VARSFILE
            varsfileopen=T
            ;;
          option-file*)
            set $tdatline
            type=$1
            file=$2
            case ${file} in
              /*)
                OPTIONFILE=${file}
                ;;
              *)
                OPTIONFILE="../${file}"
                ;;
            esac
            echo "option-file: ${file}" >&1
            echo "   option file name: ${OPTIONFILE}" >&9
            ;;
          option*)
            _chkconfigfname
            set $tdatline
            optnm=$2
            shift; shift
            tval=$@
            nm="_opt_${optnm}"
            check_option ${nm} $optnm "${tval}"
            ;;
          output*)
            if [ $inproc -eq 1 ]; then
              _create_output
              CONFH=none
            fi
            set $tdatline
            type=$1
            file=$2
            case ${file} in
              none)
                CONFH=${file}
                ;;
              /*)
                CONFH=${file}
                ;;
              *)
                CONFH="../${file}"
                ;;
            esac
            echo "output-file: ${file}" >&1
            echo "   config file name: ${CONFH}" >&9
            inproc=1
            ;;
          standard)
            _chkconfigfname
            standard_checks
            ;;
          "set "*|setint*|setstr*)
            _chkconfigfname
            set $tdatline
            type=$1
            nm=$2
            if [ "$type" = "setint" -o "$type" = "setstr" ]; then
              nm="_${type}_$2"
            fi
            shift; shift
            tval=$@
            check_set ${nm} $type "${tval}"
            ;;
          *)
            _chkconfigfname
            set $tdatline
            type=$1
            chk="check_${type}"
            cmd="$chk $@"
            eval $cmd
            ;;
        esac
      fi  # doproc
    fi # ininclude
    if [ $ininclude -eq 1 ]; then
      setifs
    fi
  done
  # reset the file descriptors back to the norm.
  # set stdin to saved fd 7; close fd 7
  exec <&7 7<&-
  exec 8>&-

  _savecache     # save the cache file.
  _create_output
}

usage () {
  echo "Usage: $0 [-C] [-c <cache-file>] [-o <options-file>]
           [-L <log-file>] <config-file>
  -C : clear cache-file
defaults:
  <cache-file> : mkconfig.cache
  <log-file>   : mkconfig.log"
}

# main

mkconfigversion

unset GREP_OPTIONS
unset ENV
unalias sed > /dev/null 2>&1
unalias grep > /dev/null 2>&1
unalias ls > /dev/null 2>&1
unalias rm > /dev/null 2>&1
LC_ALL=C
export LC_ALL
clearcache=0
while test $# -gt 1; do
  case $1 in
    -C)
      shift
      clearcache=1
      ;;
    -c)
      shift
      CACHEFILE=$1
      shift
      ;;
    -L)
      shift
      LOG=$1
      shift
      ;;
    -o)
      shift
      OPTIONFILE=$1
      shift
      ;;
  esac
done

configfile=$1
if [ $# -ne 1 ] || [ ! -f $configfile  ]; then
  echo "No configuration file specified or not found."
  usage
  exit 1
fi
if [ -d $_MKCONFIG_TMP -a $_MKCONFIG_TMP != "_tmp_mkconfig" ]; then
  echo "$_MKCONFIG_TMP must not exist."
  usage
  exit 1
fi

test -d $_MKCONFIG_TMP && rm -rf $_MKCONFIG_TMP > /dev/null 2>&1
mkdir $_MKCONFIG_TMP
cd $_MKCONFIG_TMP

LOG="../$LOG"
REQLIB="../$REQLIB"
CACHEFILE="../$CACHEFILE"
OPTIONFILE="../$OPTIONFILE"

if [ $clearcache -eq 1 ]; then
  rm -f $CACHEFILE > /dev/null 2>&1
  rm -f ../mkconfig_*.vars > /dev/null 2>&1
fi

dt=`date`
exec 9>>$LOG

echo "#### " >&9
echo "# Start: $dt " >&9
echo "# $0 ($shell) using $configfile " >&9
echo "#### " >&9
echo "shell: $shell" >&9
echo "has append: ${shhasappend}" >&9
echo "has math: ${shhasmath}" >&9
echo "has upper: ${shhasupper}" >&9

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
echo "awk: $awkcmd" >&9

echo "$0 ($shell) using $configfile"

main_process $configfile

dt=`date`
echo "#### " >&9
echo "# End: $dt " >&9
echo "#### " >&9
exec 9>&-

cd ..

if [ "$MKC_KEEP_TMP" = "" ]; then
  test -d $_MKCONFIG_TMP && rm -rf $_MKCONFIG_TMP > /dev/null 2>&1
fi
exit 0
