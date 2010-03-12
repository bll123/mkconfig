#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
# check and see if there is a conflict between time.h and sys/time.h
#

require_unit c-main

check_include_time () {
    name="_$1"

    if [ "${CC}" = "" ]; then
      echo "No compiler specified" >&2
      return
    fi

    trc=0
    _hdr_time=`getdata ${_MKCONFIG_PREFIX} _hdr_time`
    _sys_time=`getdata ${_MKCONFIG_PREFIX} _sys_time`
    if [ "${_hdr_time}" = "time.h" -a "${_sys_time}" = "sys/time.h" ]; then
      printlabel $name "header: include both time.h & sys/time.h"
      checkcache ${_MKCONFIG_PREFIX} $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <time.h>
#include <sys/time.h>
main () { struct tm x; }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata ${_MKCONFIG_PREFIX} "${name}" "${trc}"
    fi
}
