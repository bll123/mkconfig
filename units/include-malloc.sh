#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
# check and see if there is a conflict w/string.h and malloc.h
#

require_unit lang-c

check_include_malloc () {
    name="_$1"

    if [ "${CC}" = "" ]; then
      echo "No compiler specified"
      return
    fi

    trc=0
    _hdr_malloc=`getdata cfg _hdr_malloc`
    _hdr_string=`getdata cfg _hdr_string`
    if [ "${_hdr_string}" = "string.h" -a "${_hdr_malloc}" = "malloc.h" ]; then
      printlabel $name "header: include malloc.h"
      checkcache $name
      if [ $rc -eq 0 ]; then return; fi

      code="
#include <string.h>
#include <malloc.h>
main () { char *x; x = (char *) malloc (20); }"
      do_check_compile "${name}" "${code}" std
    else
      setdata cfg "${name}" "${trc}"
    fi
}
