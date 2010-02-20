#!/bin/sh
#
# check and see if there is a conflict between string.h and strings.h
#

check_include_string () {
    name=$1

    trc=0
    _hdr_string=`getdata cfg _hdr_string`
    _hdr_strings=`getdata cfg _hdr_strings`
    if [ "${_hdr_string}" = "string.h" -a "${_hdr_strings}" = "strings.h" ]; then
      printlabel $name "header: include both string.h & strings.h"
      checkcache $name
      if [ $rc -eq 0 ]; then return; fi

      code="#include <string.h>
#include <strings.h>
main () { char *x; x = \"xyz\"; strcat (x, \"abc\"); }
"
      do_check_compile "${name}" "${code}" std
    else
      setdata cfg "${name}" "${trc}"
    fi
}
