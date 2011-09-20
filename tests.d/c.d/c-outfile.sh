#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'multiple output files'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@



#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " multiple output files${EC}"
  exit 0
fi

shift
script=$@

for f in out.h out2.h \
    mkconfig_env.vars mkconfig.log mkconfig.cache; do
  test -f $f && rm -f $f
done

dorunmkc

chkdiff out.h out2.h

testcleanup out2.h

exit $grc
