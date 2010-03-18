#!/bin/sh
#
# $Id$
#
# Copyright 2009-2010 Brad Lanam Walnut Creek, CA USA
#

mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
. ${mypath}/shellfuncs.sh

LOG="mkconfig.log"
_MKCONFIG_TMP="_tmp_mkconfig"
CACHEFILE="mkconfig.cache"

INC="include.txt"                   # temporary

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
    # And then there's: x='', which gets munged.
    set | grep "^di_" | \
      sed -e "s/=/='/" -e "s/$/'/" -e "s/''/'/g" -e "s/='$/=''/" \
      > "${CACHEFILE}"
}

setdata () {
    prefix=$1
    sdname=$2
    sdval=$3

    cmd="test \"X\$di_${prefix}_${sdname}\" != X > /dev/null 2>&1"
    eval "$cmd"
    rc=$?
    # if already in the list of vars, don't add it again.
    if [ $rc -ne 0 ]; then
      if [ "$_MKCONFIG_HASEMPTY" = "T" ]; then
        # have to check again, as empty vars don't work for the above test.
        # need a better way to do this.
        grep -l "^${sdname}$" $VARSFILE > /dev/null 2>&1
        rc=$?
      fi
      if [ $rc -ne 0 ]; then
        echo "${sdname}" >> $VARSFILE
      fi
    fi
    cmd="di_${prefix}_${sdname}=\"${sdval}\""
    eval "$cmd"
    echo "   set: $cmd" >> $LOG
}

getdata () {
    prefix=$1
    gdname=$2

    cmd="echo \${di_${prefix}_${gdname}}"
    gdval=`eval $cmd`
    echo $gdval
}

printlabel () {
  tname="$1"
  tlabel="$2"

  echo "   [${tname}] ${tlabel} ... " >> $LOG
  echo ${EN} "${tlabel} ... ${EC}"
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
  yntag="${3:-}"

  if [ "$ynval" != "0" ]; then
    echo "   [${ynname}] $ynval ${yntag}" >> $LOG
    echo "$ynval ${yntag}"
  else
    echo "   [${ynname}] no ${yntag}" >> $LOG
    echo "no ${yntag}"
  fi

  if [ "$_MKCONFIG_EXPORT" = "T" ]; then
    doexport "$ynname" "$ynval"
  fi
}

printyesno () {
    ynname=$1
    ynval=$2
    yntag="${3:-}"

    if [ "$ynval" != "0" ]; then
      ynval="yes"
    fi
    printyesno_val $ynname $ynval "$yntag"
}


checkcache_val () {
  prefix=$1
  tname=$2

  tval=`getdata ${prefix} ${tname}`
  rc=1
  if [ "$tval" != "" ]; then
    printyesno_val "$tname" "$tval" " (cached)"
    rc=0
  fi
  return $rc
}

checkcache () {
  prefix=$1
  tname=$2

  tval=`getdata ${prefix} ${tname}`
  rc=1
  if [ "$tval" != "" ]; then
    printyesno "$tname" "$tval" " (cached)"
    rc=0
  fi
  return $rc
}

check_command () {
    name=$1
    cmd=$2

    printlabel $name "command: ${cmd}"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    trc=`locatecmd "$cmd"`
    if [ "$trc" = "" ]; then trc=0; fi
    printyesno $name $trc
    setdata ${_MKCONFIG_PREFIX} "${name}" "${trc}"
}

require_unit () {
  units=$@
  for rqu in $units; do
    trqu=`dosubst $rqu '-' '_'`
    cmd="echo \$_MKCONFIG_UNIT_${trqu}"
    val=`eval $cmd`
    if [ "$val" = "Y" ]; then
      echo "   required unit ${rqu} already loaded" >> $LOG
      continue
    fi
    echo "   required unit ${rqu} needed" >> $LOG
    doloadunit $rqu Y
  done
}

doloadunit () {
  lu=$1
  dep=$2
  if [ "$dep" = "Y" ]; then
   slu="${lu}"
   tag=" (dependency)"
  fi
  if [ -f ../${mypath}/mkconfig.units/${lu}.sh ]; then
    echo "load-unit: ${lu} ${tag}"
    echo "   found ${lu} ${tag}" >> $LOG
    . ../${mypath}/mkconfig.units/${lu}.sh
    tlu=`dosubst $lu '-' '_'`
    eval "_MKCONFIG_UNIT_${tlu}=Y"
  fi
  if [ "$dep" = "Y" ]; then
    lu="$slu"
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
  hasifs=0
  if [ "$IFS" != "" ]; then
    OIFS="$IFS"
    hasifs=1
  fi
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
    linenumber=`domath "$linenumber + 1"`

    if [ $ininclude -eq 1 ]; then
        if [ "${tdatline}" = "endinclude" ]; then
          echo "#### ${linenumber}: ${tdatline}" >> $LOG
          ininclude=0
          if [ $hasifs -eq 1 ]; then
            IFS="$OIFS"
          else
            unset IFS
          fi
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
                echo "#### ${linenumber}: ${tdatline}" >> $LOG
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
              CONFH="${file}"
              ;;
            /*)
              CONFH="${file}"
              ;;
            *)
              CONFH="../${file}"
              ;;
          esac
          echo "output-file: ${file}"
          echo "   config file name: ${CONFH}" >> $LOG
          ;;
        loadunit*)
          set $tdatline
          type=$1
          file=$2
          doloadunit ${file} N
          if [ "$VARSFILE" = "" -a "${_MKCONFIG_PREFIX}" != "" ]; then
            VARSFILE="../mkconfig_${_MKCONFIG_PREFIX}.vars"
          fi
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
            check_command "${nm}" "${cmd}"
            ;;
        include)
            chkconfigfname
            ininclude=1
            IFS="
"
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
  done
  # reset the file descriptors back to the norm.
  exec <&7 7<&-

  savecache  # save the cache file.

  if [ ${CONFH} != "none" ]; then
    > ${CONFH}
    preconfigfile ${CONFH}

    for cfgvar in `cat $VARSFILE`; do
      val=`getdata ${_MKCONFIG_PREFIX} $cfgvar`
      output_item ${CONFH} "${cfgvar}" "${val}"
    done

    output_other ${CONFH}
    stdconfigfile ${CONFH}
    cat $INC >> ${CONFH}
    postconfigfile ${CONFH}
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

doshelltest $@
setechovars
mkconfigversion

clearcache=0
while test $# -gt 1; do
  case "$1" in
    -C)
      shift
      clearcache=1
      ;;
    -c)
      shift
      CACHEFILE="$1"
      shift
      ;;
    -l)
      shift
      LOG="$1"
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
echo "#### " >> $LOG
echo "# Start: $dt " >> $LOG
echo "# $0 ($shell) using $configfile " >> $LOG
echo "#### " >> $LOG

echo "$0 ($shell) using $configfile"
echo "$shell has append: ${shhasappend}" >> $LOG
echo "$shell has paramsub: ${shhasparamsub}" >> $LOG
echo "$shell has math: ${shhasmath}" >> $LOG
echo "$shell has upper: ${shhasupper}" >> $LOG

create_config $configfile

dt=`date`
echo "#### " >> $LOG
echo "# End: $dt " >> $LOG
echo "#### " >> $LOG

cd ..
test -d $_MKCONFIG_TMP && rm -rf $_MKCONFIG_TMP > /dev/null 2>&1
exit 0
