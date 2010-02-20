#!/bin/sh
#
# check and see if there is a conflict between time.h and sys/time.h
#

check_include_time () {
    name="_$1"

    trc=0
    _hdr_time=`getdata cfg _hdr_time`
    _sys_time=`getdata cfg _sys_time`
    if [ "${_hdr_time}" = "time.h" -a "${_sys_time}" = "sys/time.h" ]; then
      printlabel $name "header: include both time.h & sys/time.h"
      checkcache $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <time.h>
#include <sys/time.h>
main () { struct tm x; }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata cfg "${name}" "${trc}"
    fi
}
