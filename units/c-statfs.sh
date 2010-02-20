#!/bin/sh
#
#  Check to see how many arguments the statfs() system
#  call takes.  Generally only works w/prototypes.
#

check_statfs_args () {
    name=$1

    printlabel $name "statfs(): 2 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi
    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf);
}
"
    do_check_link "${name}" "${code}" all
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 2
      return
    fi

    printlabel $name "statfs(): 3 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi
    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf));
}
"
    do_check_link "${name}" "${code}" all
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 3
      return
    fi

    printlabel $name "statfs(): 4 arguments"
    checkcache $name
    if [ $rc -eq 0 ]; then return; fi
    code="
main () {
    struct statfs statBuf; char *name; name = \"/\";
    statfs (name, &statBuf, sizeof (statBuf), 0);
}
"
    do_check_link "${name}" "${code}" all
    if [ $rc -eq 0 ]; then
      setdata cfg "${name}" 4
      return
    fi
    setdata cfg "${name}" 0
}
