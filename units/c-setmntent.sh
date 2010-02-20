#!/bin/sh
#
# check and see how many arguments setmntent() takes.
#

check_setmntent_args () {
    name=$1

    printlabel $name "setmntent(): 1 argument"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi
    code="main () { setmntent (\"/etc/mnttab\"); }"
    do_check_link "${name}" "${code}" all
    rc=$?
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 1
      return
    fi

    printlabel $name "setmntent(): 2 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi
    code="main () { setmntent (\"/etc/mnttab\", \"r\"); }"
    do_check_link "${name}" "${code}" all
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 1
      return
    fi
    setdata cfg "${name}" 0
}
