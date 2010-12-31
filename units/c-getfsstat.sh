#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
# check and see how many arguments setmntent() takes.
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

check_getfsstat_type () {
    name="_$1"

    printlabel $name "getfsstat type"
    checkcache_val ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata val ${_MKCONFIG_PREFIX} _lib_getfsstat
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    getdata hdr ${_MKCONFIG_PREFIX} _sys_mount
    if [ "$hdr" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    echo "header: $hdr" >&9
    code=""
    if [ "$hdr" != 0 ]; then
      code="#include <$hdr>"
      _c_chk_cpp $name "$code"
      rc=$?

      if [ $rc -eq 0 ]; then
        egrep -l 'getfsstat[	 ]*\(' $name.out >&9 2>&1
        rc=$?
        if [ $rc -eq 0 -a "$val" != "" ]; then
          # strip up to first comma, then after comma
          # and any variable name.
          rval=`egrep 'getfsstat[	 ]*\(' $name.out |
            sed -e 's/^[^,]*,[	 ]*//' -e 's/,.*$//' \
              -e 's/  *[_a-z0-9]*$//'`
          setdata ${_MKCONFIG_PREFIX} "${name}" ${rval}
          printyesno_val "${name}" ${rval} ""
          return
        fi
      fi
    fi

    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
