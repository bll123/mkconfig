#!/bin/sh
#
# $Id$
# $Revision$
#
# Copyright 2010 Brad Lanam Walnut Creek, CA USA
#

xuname=`locatecmd uname`
echo "uname located: ${xuname}" >&2

if [ "${xuname}" != "" ]
then
    SYSTYPE=`${xuname} -s`
    SYSREV=`${xuname} -r`
    SYSARCH=`${xuname} -m`

    case ${SYSTYPE} in
        AIX)
            tmp=`( (oslevel) 2>/dev/null || echo "not found") 2>&1`
            case "$tmp" in
                'not found') SYSREV="$4"."$3" ;;
                '<3240'|'<>3240') SYSREV=3.2.0 ;;
                '=3240'|'>3240'|'<3250'|'<>3250') SYSREV=3.2.4 ;;
                '=3250'|'>3250') SYSREV=3.2.5 ;;
                *) SYSREV=$tmp;;
            esac
            ;;
    esac

    echo "type: ${SYSTYPE}" >&2
    echo "rev: ${SYSREV}" >&2
    echo "arch: ${SYSARCH}" >&2
else
  # no uname...we'll have to do some guessing.
  if [ -f /vmunix ]; then
    # some sort of BSD variant
    # sys/param.h might have:
    #   #define BSD 43
    #   #define BSD4_3  1
    rev=`grep '^#define.*BSD[^0-9]' /usr/include/sys/param.h | sed 's,/.*,,'`
    if [ "rev" != "" ]; then
      SYSTYPE="BSD"
      rev=`echo $rev | sed 's/^[^0-9]*\([0-9]\)*\([0-9]\).*/\1.\2/'`
      SYSREV="$rev"
      SYSARCH="unknown"
    fi
  else
    SYSTYPE="SYSV"      # some SysV variant, probably.
    SYSREV="unknown"
    SYSARCH="unknown"
  fi
fi

echo "_MKCONFIG_SYSTYPE=\"${SYSTYPE}\""
echo "export _MKCONFIG_SYSTYPE"
echo "_MKCONFIG_SYSREV=\"${SYSREV}\""
echo "export _MKCONFIG_SYSREV"
echo "_MKCONFIG_SYSARCH=\"${SYSARCH}\""
echo "export _MKCONFIG_SYSARCH"
