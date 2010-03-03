#!/bin/sh
#
# $Id$
# $Source$
#
# Copyright 2010 Brad Lanam, Walnut Creek, California USA
#

# optional unit: cflags

xmsgfmt=`locatecmd msgfmt`
xgmsgfmt=`locatecmd gmsgfmt`

mfmt="${xmsgfmt}"
if [ "$_MKCONFIG_USING_GCC" = "Y" ]
then
    mfmt="${xgmsgfmt:-${xmsgfmt}}"
    if [ -x "${xccpath}/msgfmt" ]
    then
        mfmt="${xccpath}/msgfmt"
    fi
    if [ -x "${xccpath}/gmsgfmt" ]
    then
        mfmt="${xccpath}/gmsgfmt"
    fi
fi

echo "XMSGFMT=\"$mfmt\""
echo "export XMSGFMT"

