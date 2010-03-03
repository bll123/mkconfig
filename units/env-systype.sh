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
  SYSTYPE="unknown"
  SYSREV="unknown"
  SYSARCH="unknown"
fi

echo "_MKCONFIG_SYSTYPE=${SYSTYPE}"
echo "export _MKCONFIG_SYSTYPE"
echo "_MKCONFIG_SYSREV=${SYSREV}"
echo "export _MKCONFIG_SYSREV"
echo "_MKCONFIG_SYSARCH=${SYSARCH}"
echo "export _MKCONFIG_SYSARCH"
