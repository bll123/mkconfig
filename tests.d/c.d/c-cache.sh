#!/bin/sh

. $_MKCONFIG_DIR/bin/testfuncs.sh

maindodisplay $1 'build from cache'
maindoquery $1 $_MKC_SH_PL

chkccompiler
getsname $0
dosetup $@

. $_MKCONFIG_DIR/bin/shellfuncs.sh
testshcapability

ccclear="-nc"
ccache_count=1  # this has to be a unique variable
if [ -f ${_MKCONFIG_RUNTMPDIR}/c-cache.out.h ]; then
  domath ccache_count "${ccache_count} + 1"
fi
while test -f out.h.${ccache_count}; do
  domath ccache_count "${ccache_count} + 1"
done

dorunmkc ${ccclear}

# cache creation
if [ ${ccache_count} -eq 1 ]; then
  ccclear=""
  sed -e '/Created on:/d' out.h > ${_MKCONFIG_RUNTMPDIR}/c-cache.out.h
  # keep mkconfig.cache
  cp -f ${MKC_FILES}/mkconfig.cache ${_MKCONFIG_RUNTMPDIR}/c-cache.mkconfig.cache
  mv -f ${MKC_FILES}/mkc_out.vars ${_MKCONFIG_RUNTMPDIR}/c-cache.mkc_out.vars

  # re-run this script for this shell
  ${_MKCONFIG_SHELL} $0 $stag $script
  rc=$?
  exit $rc
fi

sed -e '/Created on:/d' out.h > out.h.${ccache_count}
mv -f ${MKC_FILES}/mkc_out.vars ${MKC_FILES}/mkc_out.vars.${ccache_count}

c=2
while test $c -lt $ccache_count; do
  chkdiff ${_MKCONFIG_RUNTMPDIR}/c-cache.out.h out.h.${c}
  chkdiff ${_MKCONFIG_RUNTMPDIR}/c-cache.mkc_out.vars ${MKC_FILES}/mkc_out.vars.${c}
  domath c "$c + 1"
done

# reset cache
cp -f ${_MKCONFIG_RUNTMPDIR}/c-cache.mkconfig_c.cache ${MKC_FILES}/mkconfig_c.cache
# keep mkc_out_c.cache

mv -f ${MKC_FILES}/mkconfig.log ${MKC_FILES}/mkconfig.log.${ccache_count}

exit $grc
