#!/bin/sh
#
# $Id$
#
# Copyright 2009-2010 Brad Lanam Walnut Creek, CA USA
#


mypath=`dirname $0`
. ${mypath}/features/shellfuncs.sh

LOG="mkconfig.log"
REQLIB="reqlibs.txt"
TMP="_tmp_mkconfig"
CACHEFILE="mkconfig.cache"
VARSFILE="mkconfig.vars"
datafile=""

INC="include.txt"                   # temporary
datachg=0

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

savedata () {
    # And save the data for re-use.
    # Some shells don't quote the values in the set
    # command like bash does.  So we do it.
    # Then we have to undo it for bash.
    # And then there's: x='', which gets munged.
    if [ $datachg -eq 1 ]; then
      set | grep "^di_cfg" | \
        sed -e "s/=/='/" -e "s/$/'/" -e "s/''/'/g" -e "s/='$/=''/" \
        > "${CACHEFILE}"
      datachg=0
    fi
}

cleardata () {
    prefix=$1
    if [ -f $VARSFILE ]; then
      for tval in `cat $VARSFILE`; do
          eval unset di_${prefix}_${tval}
      done
      rm -f $VARSFILE
    fi
}

setdata () {
    prefix=$1
    sdname=$2
    sdval=$3

    datachg=1

    cmd="test \"X\$di_${prefix}_${sdname}\" != X > /dev/null 2>&1"
    eval "$cmd"
    rc=$?
    # if already in the list of vars, don't add it again.
    if [ $rc -ne 0 ]; then
      echo $sdname >> $VARSFILE
    fi
    cmd="di_${prefix}_${sdname}=\"${sdval}\""
    eval "$cmd"
}

getdata () {
    prefix=$1
    gdname=$2

    gdval=`eval echo "\\${di_${prefix}_${gdname}}"`
    echo $gdval
}

printlabel () {
  tname="$1"
  tlabel="$2"

  echo "## [${tname}] ${tlabel} ... " >> $LOG
  echo ${EN} "${tlabel} ... ${EC}"
}

printyesno_val () {
  ynname=$1
  ynval=$2
  yntag="${3:-}"

  if [ "$ynval" != "0" ]; then
    echo "## [${ynname}] $ynval ${yntag}" >> $LOG
    echo "$ynval ${yntag}"
  else
    echo "## [${ynname}] no ${yntag}" >> $LOG
    echo "no ${yntag}"
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
  tname=$1

  tval=`getdata cfg $tname`
  rc=1
  if [ "$tval" != "" ]; then
    printyesno_val $tname $tval " (cached)"
    rc=0
  fi
  return $rc
}

checkcache () {
  tname=$1

  tval=`getdata cfg $tname`
  rc=1
  if [ "$tval" != "" ]; then
    printyesno $tname $tval " (cached)"
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

    trc=0
    for p in $pthlist; do
      if [ -x "$p/$cmd" ]; then
        trc="$p/$cmd"
        echo " found $cmd in $p" >> $LOG
        break
      fi
    done
    printyesno $name $trc
    setdata cfg "${name}" "${trc}"
}


create_config () {
    configfile=$1
    cleardata cfg

    reqlibs=""

    if [ -f "$CACHEFILE" -a -f "$VARSFILE" ]; then
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
    # save stdin in fd 5.
    # and reset stdin to get from the configfile.
    # this allows us to run the while loop in the
    # current shell rather than a subshell.
    exec 5<&0 < ../${configfile}
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
              hdr*|sys*)
                  echo "#### ${linenumber}: ${tdatline}" >> $LOG
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
              /*)
                CONFH="${file}"
                ;;
              *)
                CONFH="../${file}"
                ;;
            esac
            echo "output-file: ${CONFH}"
            echo "   config file name: ${CONFH}" >> $LOG
            ;;
          loadunit*)
            set $tdatline
            type=$1
            file=$2
            if [ -f ../${mypath}/mkconfig.units/${file}.sh ]; then
              echo "load-unit: ${file}"
              echo "   found ${file}" >> $LOG
              . ../${mypath}/mkconfig.units/${file}.sh
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
              eval $chk $@
              ;;
        esac
      fi
    done
    # reset the file descriptors back to the norm.
    exec <&5 5<&-

    savedata  # save the cache file.

    > ${CONFH}
    preconfigfile ${CONFH}

    for cfgvar in `cat $VARSFILE`; do
      val=`getdata cfg $cfgvar`
      tval=0
      if [ "$val" != "0" ]; then
        tval=1
      fi
      case ${cfgvar} in
        _hdr*|_sys*|_command*)
          echo "#define ${cfgvar} ${tval}" >> ${CONFH}
          ;;
        *)
          echo "#define ${cfgvar} ${val}" >> ${CONFH}
          ;;
      esac
    done

    > $REQLIB
    echo $reqlibs >> $REQLIB

    # standard header for all...
    stdconfigfile ${CONFH}
    cat $INC >> ${CONFH}
    postconfigfile ${CONFH}
}

usage () {
  echo "Usage: $0 [-c <cache-file>] [-v <vars-file>]"
  echo "       [-l <log-file>] [-t <tmp-dir>] [-r <reqlib-file>]"
  echo "       [-C] <config-file>"
  echo "  -C : clear cache-file"
  echo "<tmp-dir> must not exist."
  echo "defaults:"
  echo "  <cache-file> : mkconfig.cache"
  echo "  <vars-file>  : mkconfig.vars"
  echo "  <log-file>   : mkconfig.log"
  echo "  <tmp-dir>    : _tmp_mkconfig"
  echo "  <reqlib-file>: reqlibs.txt"
}

# main

shell=`getshelltype`
testshell $shell
if [ $? != 0 ]; then
  exec $SHELL $0 $@
fi
testshcapability
setechovars
pthlist=`dosubst "$PATH" '[;:]' ' '`

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
    -t)
      shift
      TMP="$1"
      shift
      ;;
    -r)
      shift
      REQLIB="$1"
      shift
      ;;
    -v)
      shift
      VARSFILE="$1"
      shift
      ;;
  esac
done

configfile=$1
if [ $# -ne 1 -o ! -f $configfile ]; then
  usage
  exit 1
fi
if [ -d $TMP -a $TMP != "_tmp_mkconfig" ]; then
  usage
  exit 1
fi

test -d $TMP && rm -rf $TMP > /dev/null 2>&1
mkdir $TMP
cd $TMP

LOG="../$LOG"
REQLIB="../$REQLIB"
CACHEFILE="../$CACHEFILE"
VARSFILE="../$VARSFILE"

if [ $clearcache -eq 1 ]; then
  rm -f $CACHEFILE > /dev/null 2>&1
  rm -f $VARSFILE > /dev/null 2>&1
fi

echo "$0 ($shell) using $configfile"
rm -f $LOG > /dev/null 2>&1
CFLAGS="${CFLAGS} ${CINCLUDES}"
echo "CC: ${CC}" >> $LOG
echo "CFLAGS: ${CFLAGS}" >> $LOG
echo "LDFLAGS: ${LDFLAGS}" >> $LOG
echo "LIBS: ${LIBS}" >> $LOG
echo "sh has append: ${shhasappend}" >> $LOG
echo "sh has paramsub: ${shhasparamsub}" >> $LOG
echo "sh has math: ${shhasmath}" >> $LOG

create_config $configfile

cd ..
test -d $TMP && rm -rf $TMP > /dev/null 2>&1
exit 0
