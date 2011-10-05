#!/bin/sh

. $_MKCONFIG_DIR/testfuncs.sh

maindodisplay $1 'build from cache'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

. $_MKCONFIG_DIR/shellfuncs.sh
testshcapability

ccclear="-nc"
ccache_count=1  # this has to be a unique variable
if [ -f ${_MKCONFIG_RUNTMPDIR}/c-cache.out.h ]; then
  domath ccache_count "${ccache_count} + 1"
fi
while test -f out.h.${ccache_count}; do
  domath ccache_count "${ccache_count} + 1"
done
echo "ccc:${ccache_count}"

dorunmkc ${ccclear}

# cache creation
if [ ${ccache_count} -eq 1 ]; then
  ccclear=""
  mv -f out.h ${_MKCONFIG_RUNTMPDIR}/c-cache.out.h
  cp -f mkconfig.cache ${_MKCONFIG_RUNTMPDIR}/c-cache.mkconfig_c.cache
  mv -f mkc_out_c.vars ${_MKCONFIG_RUNTMPDIR}/c-cache.mkc_out_c.vars
  # keep mkconfig.cache
  ${_MKCONFIG_SHELL} $0 $stag $script   # re-run this script for this shell
  exit $?
fi

mv -f out.h out.h.${ccache_count}
mv -f mkc_out_c.vars mkc_out_c.vars.${ccache_count}

c=2
while test $c -lt $ccache_count; do
  echo "## diff c-cache.out.h out.h.${c}"
  diff -b ${_MKCONFIG_RUNTMPDIR}/c-cache.out.h out.h.${c}
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi

  echo "## diff c-cache.mkc_out_c.vars mkc_out_c.vars.${c}"
  diff -b ${_MKCONFIG_RUNTMPDIR}/c-cache.mkc_out_c.vars mkc_out_c.vars.${c}
  rc=$?
  if [ $rc -ne 0 ]; then grc=$rc; fi

  domath c "$c + 1"
done

# reset cache
cp -f ${_MKCONFIG_RUNTMPDIR}/c-cache.mkconfig_c.cache mkconfig_c.cache
# keep mkc_out_c.cache

mv -f mkconfig.log mkconfig.log.${ccache_count}

exit $grc
