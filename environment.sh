#!/bin/sh
#
# $Id$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA USA
#


mypath=`echo $0 | sed -e 's,/[^/]*$,,'`
. ${mypath}/shellfuncs.sh

LOG="mkconfig_env.log"
ENVFILE="mkconfig.env"

create_env () {
    configfile=$1

    case ${ENVFILE} in
      /*)
        ;;
      *)
        ENVFILE="./${ENVFILE}"
        ;;
    esac

    > ${ENVFILE}
    chmod a+rx $ENVFILE

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
        rununit*)
          set $tdatline
          type=$1
          file=$2
          if [ -f ${mypath}/env.units/${file}.sh ]; then
            echo "run-unit: ${file}"
            echo "   found ${file}" >> $LOG
            ${mypath}/env.units/${file}.sh >> $ENVFILE 2>>$LOG
            . $ENVFILE >>$LOG 2>&1
          fi
          ;;
      esac
    done
    # reset the file descriptors back to the norm.
    exec <&5 5<&-
}

usage () {
  echo "Usage: $0 [-l <log-file>] [-e <env-file>] [-C] <config-file>"
  echo "  -C : clear cache-file"
  echo "defaults:"
  echo "  <log-file>   : mkconfig_env.log"
  echo "  <env-file>   : mkconfig.env"
}

# main

doshelltest $@
setechovars
pthlist=`dosubst "$PATH" ';' ' ' ':' ' '`

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
    -e)
      shift
      ENVFILE="$1"
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

echo "$0 ($shell) using $configfile"
rm -f $LOG > /dev/null 2>&1
echo "sh has append: ${shhasappend}" >> $LOG
echo "sh has paramsub: ${shhasparamsub}" >> $LOG
echo "sh has math: ${shhasmath}" >> $LOG

create_env $configfile

cd ..
test -d $TMP && rm -rf $TMP > /dev/null 2>&1
exit 0


