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

check_rquota_xdr () {
    name="_$1"

    printlabel $name "rquota xdr"
    checkcache_val ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata hdr ${_MKCONFIG_PREFIX} _hdr_rpcsvc_rquota
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
        sed '1,/struct *rquota *{/d' $name.out |
          egrep '[	 ][	 ]*rq_bhardlimit[	 ]*;' >&9 2>&1
        rc=$?
        if [ $rc -eq 0 -a "$val" != "" ]; then
          rval=`sed '1,/struct *rquota *{/d' $name.out |
            egrep '[	 ][	 ]*rq_bhardlimit[	 ]*;' |
            sed -e 's/[	 ][	 ]*rq_bhardlimit.*//' \
              -e 's/^[	 ]*//'`
          setdata ${_MKCONFIG_PREFIX} "${name}" "xdr_${rval}"
          printyesno_val "${name}" "xdr_${rval}" ""
          return
        fi
      fi
    fi

    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}

check_gqa_uid_xdr () {
    name="_$1"

    printlabel $name "gqa_uid xdr"
    checkcache_val ${_MKCONFIG_PREFIX} $name
    if [ $rc -eq 0 ]; then return; fi

    getdata hdr ${_MKCONFIG_PREFIX} _hdr_rpcsvc_rquota
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
        sed '1,/struct *getquota_args *{/d' $name.out |
          egrep '[	 ][	 ]*gqa_uid[	 ]*;' >&9 2>&1
        rc=$?
        if [ $rc -eq 0 -a "$val" != "" ]; then
          rval=`sed '1,/struct *getquota_args *{/d' $name.out |
            egrep '[	 ][	 ]*gqa_uid[	 ]*;' |
            sed -e 's/[	 ][	 ]*gqa_uid.*//' \
              -e 's/^[	 ]*//'`
          setdata ${_MKCONFIG_PREFIX} "${name}" "xdr_${rval}"
          printyesno_val "${name}" "xdr_${rval}" ""
          return
        fi
      fi
    fi

    setdata ${_MKCONFIG_PREFIX} "${name}" 0
    printyesno_val "${name}" 0 ""
}
