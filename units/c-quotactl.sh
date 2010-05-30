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

check_quotactl_special_pos () {
    name="_$1"

    printlabel $name "quotactl special pos"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata val ${_MKCONFIG_PREFIX} _lib_quotactl
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    getdata hdrlinux ${_MKCONFIG_PREFIX} _sys_quota
    getdata hdrbsd ${_MKCONFIG_PREFIX} _ufs_ufs_quota

    # this is not the best way to do this, but it works.

    if [ "$hdrbsd" != 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 1
      printyesno_val "${name}" 1 ""
      return
    fi

    if [ "$hdrlinux" != 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 2
      printyesno_val "${name}" 2 ""
      return
    fi

    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
