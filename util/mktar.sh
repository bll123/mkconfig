#!/bin/sh

ver=`cat VERSION`

PKG=mkconfig
dir="${PKG}-${ver}"
for dir in "${PKG}-${ver}-src" "${PKG}-${ver}"; do
  rm -rf ${dir} > /dev/null 2>&1
  mkdir ${dir}
  chmod 755 ${dir}

  sed 's,[/]*[	 ].*$,,' MANIFEST |
  while read f; do
    if [ -d $f ]; then
      mkdir ${dir}/${f}
      chmod 755 ${dir}/${f}
    else
      d=`dirname $f`
      cp -p $f ${dir}/${d}
    fi
  done
  if [ $dir = "${PKG}-${ver}-src" ]; then
    for d in tests.d features util; do
      cp -pr ${d} ${dir}
      chmod 755 ${dir}/${d}
    done
    for f in Makefile MANIFEST NOTES; do
      cp -p ${f} ${dir}
    done
  fi
  chmod -R a+r ${dir}

  tar cf - ${dir} |
    gzip -9 > ${dir}.tar.gz

  rm -rf ${dir} > /dev/null 2>&1
done

exit 0
