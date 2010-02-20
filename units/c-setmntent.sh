#!/bin/sh
#
# check and see how many arguments setmntent() takes.
#

check_setmntent_args () {
    name="_$1"

    printlabel $name "setmntent # arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi

    val=`getdata cfg _lib_setmntent`
    if [ "$val" = 0 ]; then
      setdata cfg "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    code="main () { setmntent (\"/etc/mnttab\"); }"
    _chk_link_libs "${name}" "${code}" > /dev/null
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 2
      printyesno_val "${name}" 2 ""
      return
    fi

    if [ $rc -eq 0 ]; then return; fi
    code="main () { setmntent (\"/etc/mnttab\", \"r\"); }"
    _chk_link_libs "${name}" "${code}" > /dev/null
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 3
      printyesno_val "${name}" 3 ""
      return
    fi
    setdata cfg "${name}" 0
    printyesno_val "${name}" 0 ""
}
