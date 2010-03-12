#!/bin/sh
#
# Copyright 2010 Brad Lanam Walnut Creek CA USA
#
#
#  Check to see how many arguments the statfs() system
#  call takes.  Generally only works w/prototypes.
#

require_unit c-main

check_statfs_args () {
    name="_$1"

    printlabel $name "statfs # arguments"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    if [ "${CC}" = "" ]; then
      echo "No compiler specified" >&2
      return
    fi

    val=`getdata ${_MKCONFIG_PREFIX} _lib_statfs`
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf);
}
"
    _chk_link_libs "${name}" "${code}" > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 2
      printyesno_val "${name}" 2 ""
      return
    fi

    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf));
}
"
    _chk_link_libs "${name}" "${code}" > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 3
      printyesno_val "${name}" 3 ""
      return
    fi

    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf), 0);
}
"
    _chk_link_libs "${name}" "${code}" > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 4
      printyesno_val "${name}" 4 ""
      return
    fi
    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
