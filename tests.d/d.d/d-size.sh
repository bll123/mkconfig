#!/bin/sh

if [ "$1" = "-d" ]; then
  echo ${EN} " size${EC}"
  exit 0
fi

if [ "${DC}" = "" ]; then
  echo ${EN} " no D compiler; skipped${EC}" >&5
  exit 0
fi

stag=$1
shift
script=$@

${_MKCONFIG_SHELL} ${_MKCONFIG_DIR}/mkconfig.sh -d `pwd` \
    -C $_MKCONFIG_RUNTESTDIR/d.env.dat
. ./d.env

grc=0

${_MKCONFIG_SHELL} ${script} -d `pwd` -C ${_MKCONFIG_RUNTESTDIR}/d-size.dat
v=`egrep "^enum (: )?int ({ )?_siz_long = 8( })?;$" dsize.d | sed -e 's/.*= //' -e 's/[ }]*;$//'`
grc=1
if [ "$v" = "8" ]; then
  grc=0
fi

if [ $grc -eq 0 ]; then
  ${DC} -c ${DFLAGS} dsize.d
  if [ $? -ne 0 ]; then
    echo "## compile dsize.d failed"
    grc=1
  fi
fi

if [ "$stag" != "" ]; then
  mv dsize.d dsize.d${stag}
  mv mkconfig.log mkconfig.log${stag}
  mv mkconfig.cache mkconfig.cache${stag}
  mv mkconfig_d.vars mkconfig_d.vars${stag}
fi

exit $grc
