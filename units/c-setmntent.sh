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

check_setmntent_args () {
    name="_$1"

    printlabel $name "setmntent # arguments"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata val ${_MKCONFIG_PREFIX} _lib_setmntent
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    code="main () { setmntent (\"/etc/mnttab\"); }"
    _chk_link_libs "${name}2" "${code}" all
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 2
      printyesno_val "${name}" 2 ""
      return
    fi

    if [ $rc -eq 0 ]; then return; fi
    code="main () { setmntent (\"/etc/mnttab\", \"r\"); }"
    _chk_link_libs "${name}3" "${code}" all
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 3
      printyesno_val "${name}" 3 ""
      return
    fi
    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
