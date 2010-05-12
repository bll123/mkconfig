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
#    7 - temporary for mkconfig.sh  (mkconfig.sh)
#    6 - temporary for c-main.sh    (c-main.sh)
#    5 - temporary for c-main.sh    (c-main.sh)
#    4 - runtests.sh: >>$MAINLOG    (runtests.sh)
#

RUNTOPDIR=`pwd`
mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
cd $mypath
_MKCONFIG_DIR=`pwd`
export _MKCONFIG_DIR
cd $RUNTOPDIR
. ${_MKCONFIG_DIR}/shellfuncs.sh

LOG="mkconfig.log"
_MKCONFIG_TMP="_tmp_mkconfig"
CACHEFILE="mkconfig.cache"

INC="include.txt"                   # temporary

initifs () {
  hasifs=0
  if [ "$IFS" != "" ]; then
    OIFS="$IFS"
    hasifs=1
  fi
}

setifs () {
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

chkconfigfname () {
  if [ "$CONFH" = "" ]; then
    echo "Config file name not set.  Exiting."
    exitmkconfig 1
  fi
}

exitmkconfig () {
    rc=$1
    exit 1
}

savecache () {
    # And save the data for re-use.
    # Some shells don't quote the values in the set
    # command like bash does.  So we do it.
    # Then we have to undo it for bash.
    # Other shells do: x=$''; remove the $
    # And then there's: x='', which gets munged.
    set | grep "^di_" | \
      sed -e "s/=/='/" -e "s/$/'/" -e "s/''/'/g" \
      -e "s/='$/=''/" -e "s/='\$'/='/" \
      > ${CACHEFILE}
}

setdata () {
    prefix=$1
    sdname=$2
    sdval=$3

    cmd="test \"X\$di_${prefix}_${sdname}\" != X > /dev/null 2>&1"
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
    cmd="di_${prefix}_${sdname}=\"${sdval}\""
    eval $cmd
    echo "   set: $cmd" >&9
}

getdata () {
    var=$1
    prefix=$2
    gdname=$3

    cmd="${var}=\${di_${prefix}_${gdname}}"
    eval $cmd
}

printlabel () {
  tname=$1
  tlabel=$2

  echo "   [${tname}] ${tlabel} ... " >&9
  echo ${EN} "${tlabel} ... ${EC}" >&1
}



doexport () {
  var=$1
  val=$2

  cmd="${var}=\"${val}\""
  eval $cmd
  cmd="export ${var}"
  eval $cmd
}

printyesno_val () {
  ynname=$1
  ynval=$2
  yntag=${3:-}

  if [ "$ynval" != "0" ]; then
    echo "   [${ynname}] $ynval ${yntag}" >&9
    echo "$ynval ${yntag}" >&1
  else
    echo "   [${ynname}] no ${yntag}" >&9
    echo "no ${yntag}" >&1
  fi

  if [ "$_MKCONFIG_EXPORT" = "T" ]; then
    doexport $ynname "$ynval"
  fi
}

printyesno () {
    ynname=$1
    ynval=$2
    yntag=${3:-}

    if [ "$ynval" != "0" ]; then
      ynval=yes
    fi
    printyesno_val $ynname $ynval "$yntag"
}

checkcache_val () {
  prefix=$1
  tname=$2

  getdata tval ${prefix} ${tname}
  rc=1
  if [ "$tval" != "" ]; then
    printyesno_val $tname $tval " (cached)"
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
    doloadunit $rqu Y
  done
}

doloadunit () {
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

create_config () {
  configfile=$1

  reqlibs=""

  if [ -f "$CACHEFILE" ]; then
    . $CACHEFILE
  fi

  reqhdr=""

  ininclude=0
  linenumber=0
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
        endinclude)
          ;;
        output*)
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
          ;;
        loadunit*)
          set $tdatline
          type=$1
          file=$2
          doloadunit ${file} N
          if [ "$VARSFILE" = "" -a "${_MKCONFIG_PREFIX}" != "" ]; then
            VARSFILE="../mkconfig_${_MKCONFIG_PREFIX}.vars"
          fi
          exec 8>>$VARSFILE
          ;;
        standard)
          chkconfigfname
          standard_checks
          ;;
        command*)
            chkconfigfname
            set $tdatline
            cmd=$2
            nm="_command_${cmd}"
            check_command ${nm} ${cmd}
            ;;
        include)
            chkconfigfname
            ininclude=1
            ;;
        *)
            chkconfigfname
            set $tdatline
            type=$1
            chk="check_${type}"
            cmd="$chk $@"
            eval $cmd
            ;;
      esac
    fi
    if [ $ininclude -eq 1 ]; then
      setifs
    fi
  done
  # reset the file descriptors back to the norm.
  exec <&7 7<&-
  exec 8>&-

  savecache  # save the cache file.

  if [ ${CONFH} != "none" ]; then
    > ${CONFH}
    exec 8>>${CONFH}
    preconfigfile ${CONFH} >&8

    exec 7<&0 < $VARSFILE
    while read cfgvar; do
      getdata val ${_MKCONFIG_PREFIX} $cfgvar
      output_item ${CONFH} ${cfgvar} "${val}" >&8
    done
    exec <&7 7<&-

    stdconfigfile ${CONFH} >&8
    cat $INC >&8
    postconfigfile ${CONFH} >&8
    exec 8>&-

    output_other ${CONFH}
  fi
}

usage () {
  cat << _HERE_
Usage: $0 [-C] [-c <cache-file>] [-l <log-file>] <config-file>
  -C : clear cache-file
defaults:"
  <cache-file> : mkconfig.cache
  <log-file>   : mkconfig.log
_HERE_
}

# main

doshelltest $0 $@
setechovars
mkconfigversion

unset GREP_OPTIONS
unset DI_ARGS
unset DI_FMT
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
    -l)
      shift
      LOG=$1
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

echo "$0 ($shell) using $configfile"

create_config $configfile

dt=`date`
echo "#### " >&9
echo "# End: $dt " >&9
echo "#### " >&9
exec 9>&-

cd ..
test -d $_MKCONFIG_TMP && rm -rf $_MKCONFIG_TMP > /dev/null 2>&1
exit 0
