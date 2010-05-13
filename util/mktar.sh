#!/bin/bash

ver=$(cat VERSION)

PKG=mkconfig
dir="${PKG}-${ver}"
rm -rf ${dir} > /dev/null 2>&1
mkdir ${dir}
chmod 755 ${dir}

sed 's,[/]*[	 ].*$,,' MANIFEST |
while read f; do
  if [ -d $f ]; then
    mkdir ${dir}/${f}
    chmod 755 ${dir}/${f}
  else
    d=$(dirname $f)
    cp $f ${dir}/${d}
  fi
done
chmod -R a+r ${dir}

tar cf - ./${dir} |
gzip -9 > ${dir}.tar.gz

rm -rf ${dir} > /dev/null 2>&1

exit 0
