#!/bin/sh

script=$@
echo ${EN} "compile mkconfig.pl${EC}" >&5

grc=0

perl -cw $_MKCONFIG_DIR/mkconfig.pl
rc=$?
if [ $rc -ne 0 ];then grc=$rc; fi

exit $grc
