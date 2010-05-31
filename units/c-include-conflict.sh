#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
# check and see if there is a conflict between time.h and sys/time.h
#

#
# speed at the cost of maintainability...
# File Descriptors:
#    9 - >>$LOG                     (mkconfig.sh)
#    8 - >>$VARSFILE, >>$CONFH      (mkconfig.sh)
#    7 - temporary for mkconfig.sh  (mkconfig.sh)
#    6 - temporary for c-main.sh    (c-main.sh)
#    5 - temporary for c-main.sh    (c-main.sh)
#

require_unit c-main

check_include_time () {
    name="_$1"

    if [ "${CC}" = "" ]; then
      echo "No compiler specified" >&2
      return
    fi

    trc=0
    printlabel $name "header: include both time.h & sys/time.h"

    getdata _hdr_time ${_MKCONFIG_PREFIX} _hdr_time
    getdata _sys_time ${_MKCONFIG_PREFIX} _sys_time
    if [ "${_hdr_time}" = "time.h" -a "${_sys_time}" = "sys/time.h" ]; then
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <time.h>
#include <sys/time.h>
main () { struct tm x; }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata ${_MKCONFIG_PREFIX} "${name}" "${trc}"
      printyesno_val "${name}" $trc ""
    fi
}

check_include_quota () {
    name="_$1"

    if [ "${CC}" = "" ]; then
      echo "No compiler specified" >&2
      return
    fi

    trc=0
    printlabel $name "header: include both sys/quota.h & linux/quota.h"

    getdata _hdr_linux_quota ${_MKCONFIG_PREFIX} _hdr_linux_quota
    getdata _sys_quota ${_MKCONFIG_PREFIX} _sys_quota
    if [ "${_hdr_linux_quota}" = "linux/quota.h" -a \
        "${_sys_quota}" = "sys/quota.h" ]; then
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <sys/quota.h>
#include <linux/quota.h>
main () { int x; return; }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata ${_MKCONFIG_PREFIX} "${name}" "${trc}"
      printyesno_val "${name}" $trc ""
    fi
}
