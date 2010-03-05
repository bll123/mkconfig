#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA USA
#


mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
. ${mypath}/shellfuncs.sh

LOG="mkconfig_env.log"

exitmkconfig () {
    rc=$1
    exit $rc
}

chkconfigfname () {
  if [ "$ENVFILE" = "" ]; then
    echo "Config file name not set.  Exiting."
    exitmkconfig 1
  fi
}

dorununit () {
  tag=""
  dep=$2
  if [ "$dep" = "Y" ]; then
   su="${u}"
   tag=" (dependency)"
  fi
  u=$1
  if [ ! -f ${ENVFILE} ]; then
    > ${ENVFILE}
    chmod a+rx $ENVFILE
  fi
  if [ -f ${mypath}/env.units/${u}.sh ]; then
    # run as part of our script so that it
    # has access to the various functions
    echo "run-unit: ${u} ${tag}" >&3
    echo "   found ${u}" >> $LOG
    . ${mypath}/env.units/${u}.sh >> $ENVFILE 2>>$LOG
    tu=`dosubst $u '-' '_'`
    eval "_MKCONFIG_UNIT_${tu}=Y"
    . $ENVFILE >>$LOG 2>&1
  fi
  if [ "$dep" = "Y" ]; then
    u="$su"
    tag=""
  fi
}

require_unit () {
  units=$@
  for u in $units; do
    tu=`dosubst $u '-' '_'`
    cmd="echo \$_MKCONFIG_UNIT_${tu}"
    val=`eval $cmd`
    if [ "$val" = "Y" ]; then
      echo "   required unit ${u} already run" >> $LOG
      continue
    fi
    echo "   required unit ${u} needed" >> $LOG
    dorununit $u Y
  done
}

create_env () {
    configfile=$1

    case ${ENVFILE} in
      /*)
        ;;
      *)
        ENVFILE="./${ENVFILE}"
        ;;
    esac

    test -f ${ENVFILE} && rm -f ${ENVFILE}

    linenumber=0
    # save stdin in fd 5.
    # and reset stdin to get from the configfile.
    # this allows us to run the while loop in the
    # current shell rather than a subshell.
    exec 5<&0 < ${configfile}
    while read tdatline; do
      linenumber=`domath "$linenumber + 1"`

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

      case ${tdatline} in
        output*)
          set $tdatline
          type=$1
          file=$2
          ENVFILE="${file}"
          case ${ENVFILE} in
            /*)
              ;;
            *)
              ENVFILE="./${ENVFILE}"
              ;;
          esac
          test -f ${ENVFILE} && rm -f ${ENVFILE}
          echo "output-file: ${file}" >&3
          echo "   output file name: ${ENVFILE}" >> $LOG
          ;;
        rununit*)
          chkconfigfname
          set $tdatline
          type=$1
          file=$2
          dorununit ${file} N
          ;;
      esac
    done
    # reset the file descriptors back to the norm.
    exec <&5 5<&-
}

usage () {
  echo "Usage: $0 [-l <log-file>] [-C] <config-file>"
  echo "  -C : clear cache-file"
  echo "defaults:"
  echo "  <log-file>   : mkconfig_env.log"
}

# main

exec 3>&1

doshelltest $@
setechovars
mkconfigversion

clearenv=0
while test $# -gt 1; do
  case "$1" in
    -C)
      shift
      clearenv=1
      ;;
    -l)
      shift
      LOG="$1"
      shift
      ;;
  esac
done

configfile=$1
if [ $# -ne 1 -o ! -f $configfile ]; then
  usage
  exit 1
fi

if [ $clearenv -eq 1 ]; then
  rm -f $ENVFILE > /dev/null 2>&1
fi

echo "$0 ($shell) using $configfile" >&3
rm -f $LOG > /dev/null 2>&1
echo "sh has append: ${shhasappend}" >> $LOG
echo "sh has paramsub: ${shhasparamsub}" >> $LOG
echo "sh has math: ${shhasmath}" >> $LOG

create_env $configfile

cd ..
exit 0
