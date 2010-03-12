#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
# check and see how many arguments setmntent() takes.
#

require_unit c-main

check_setmntent_args () {
    name="_$1"

    printlabel $name "setmntent # arguments"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    val=`getdata ${_MKCONFIG_PREFIX} _lib_setmntent`
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    code="main () { setmntent (\"/etc/mnttab\"); }"
    _chk_link_libs "${name}" "${code}" all > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 2
      printyesno_val "${name}" 2 ""
      return
    fi

    if [ $rc -eq 0 ]; then return; fi
    code="main () { setmntent (\"/etc/mnttab\", \"r\"); }"
    _chk_link_libs "${name}" "${code}" all > /dev/null
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 3
      printyesno_val "${name}" 3 ""
      return
    fi
    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
