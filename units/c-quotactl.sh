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
    TMP=qctlpos

    printlabel $name "quotactl position"
    checkcache ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata val ${_MKCONFIG_PREFIX} _lib_quotactl
    if [ "$val" = 0 ]; then
      setdata ${_MKCONFIG_PREFIX} "${name}" 0
      printyesno_val "${name}" 0 ""
      return
    fi

    getdata hdr ${_MKCONFIG_PREFIX} _sys_quota
    if [ "$hdr" = 0 ]; then
      getdata hdr ${_MKCONFIG_PREFIX} _hdr_ufs_ufs_quota
    fi
    if [ "$hdr" = 0 ]; then
      getdata hdr ${_MKCONFIG_PREFIX} _hdr_ufs_quota
    fi
    if [ "$hdr" = 0 ]; then
      getdata hdr ${_MKCONFIG_PREFIX} _hdr_linux_quota
    fi
    getdata uhdr ${_MKCONFIG_PREFIX} _hdr_unistd

    echo "header: $hdr" >&9
    if [ "$hdr" != 0 ]; then
      echo "#include <$hdr>" > $TMP.c
      if [ "$uhdr" != 0 ]; then
        echo "#include <$uhdr>" >> $TMP.c
      fi
      ${CC} -E $TMP.c > $TMP.x

      egrep 'quotactl *\( *int.*, *(const *)?char' $TMP.x >&9
      rc=$?
      if [ $rc -eq 0 ]; then
        setdata ${_MKCONFIG_PREFIX} "${name}" 2
        printyesno_val "${name}" 2 ""
        return
      fi

      egrep 'quotactl *\( *(const *)?char.*, *int' $TMP.x >&9
      rc=$?
      if [ $rc -eq 0 ]; then
        setdata ${_MKCONFIG_PREFIX} "${name}" 1
        printyesno_val "${name}" 1 ""
        return
      fi
    fi

    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
