#!/bin/sh

script=$@
echo ${EN} "compile mkconfig.pl${EC}" >&3

grc=0

perl -cw ../mkconfig.pl
if [ $rc -ne 0 ];then grc=$rc; fi

exit $grc
