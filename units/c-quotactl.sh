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

check_quotactl_pos () {
    name="_$1"

    printlabel $name "quotactl position"
    checkcache_val ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata val ${_MKCONFIG_PREFIX} _lib_quotactl
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    for hnm in _sys_quota _hdr_ufs_ufs_quota _hdr_ufs_quota \
        _hdr_linux_quota; do
      getdata hdr ${_MKCONFIG_PREFIX} $hnm
      if [ "$hdr" != 0 ]; then
        break
      fi
    done
    getdata uhdr ${_MKCONFIG_PREFIX} _hdr_unistd

    echo "header: $hdr" >&9
    code=""
    if [ "$hdr" != 0 ]; then
      code="#include <$hdr>"
      if [ "$uhdr" != 0 ]; then
        code="$code
#include <$uhdr>"
      fi
      _c_chk_cpp $name "$code"
      rc=$?

      if [ $rc -eq 0 ]; then
        egrep -l 'quotactl *\( *int[^,]*, *(const *)?char' $name.out >&9 2>&1
        rc=$?
        if [ $rc -eq 0 ]; then
          setdata ${_MKCONFIG_PREFIX} "${name}" 2
          printyesno_val "${name}" 2 ""
          return
        fi

        egrep -l 'quotactl *\( *(const *)?char[^,]*, *int' $name.out >&9 2>&1
        rc=$?
        if [ $rc -eq 0 ]; then
          setdata ${_MKCONFIG_PREFIX} "${name}" 1
          printyesno_val "${name}" 1 ""
          return
        fi
      fi
    fi

    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
